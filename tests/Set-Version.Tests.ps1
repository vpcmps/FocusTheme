$repoRoot = Split-Path -Parent $PSScriptRoot
$setVersion = Join-Path $repoRoot 'scripts\Set-Version.ps1'

# One tag now releases three separately packaged extensions, and Set-Version.ps1
# is what keeps their three manifests saying the same number. It works by regex
# against three unrelated file formats, which is the kind of thing that keeps
# working right up until a file gains another attribute that happens to match.
#
# The release workflow runs this script in -Check mode before it builds anything,
# so a false pass here is a release published at two different versions.

function Test-ThrowsSetVersion {
    <#
        .SYNOPSIS
        $true when the action throws.

        .DESCRIPTION
        Same helper Test-ReleaseTag.Tests.ps1 uses, and for the same reason:
        `Should Throw` does not fire under the Pester 3.4 that scripts/Test.ps1
        selects, so an assertion written that way passes whether or not the code
        actually failed.
    #>
    param([Parameter(Mandatory)][scriptblock]$Action)

    try {
        & $Action
        return $false
    }
    catch {
        return $true
    }
}

function Get-DeclaredVersion {
    $path = Join-Path $repoRoot 'FocusThemes\source.extension.vsixmanifest'
    ([xml](Get-Content -LiteralPath $path -Raw)).PackageManifest.Metadata.Identity.Version
}

Describe 'Set-Version rejects versions that are not stable releases' {
    It 'refuses anything that is not MAJOR.MINOR.PATCH' {
        foreach ($bad in '1.0', '1.0.0.0', '1.0.0-beta', 'v1.0.0', '01.0.0') {
            Test-ThrowsSetVersion { & $setVersion $bad -Check } |
                Should Be $true
        }
    }
}

Describe 'Set-Version finds the version each manifest actually declares' {
    It 'agrees with every manifest at the version they currently hold' {
        # Read the version from one manifest and assert the script sees the same
        # one in all three. Hard-coding a number here would make this test a
        # second place to update on every release - the exact duplication the
        # script exists to remove.
        Test-ThrowsSetVersion { & $setVersion (Get-DeclaredVersion) -Check } |
            Should Be $false
    }

    It 'reads the extension identity, not the manifest schema version' {
        # source.extension.vsixmanifest carries three Version attributes: the
        # schema's on <PackageManifest>, the extension's on <Identity>, and a
        # version range on <InstallationTarget>. Only the middle one is the
        # release version, and the first is a plausible-looking 2.0.0 that a
        # looser pattern would happily rewrite.
        $path = Join-Path $repoRoot 'FocusThemes\source.extension.vsixmanifest'
        $schemaVersion = ([xml](Get-Content -LiteralPath $path -Raw)).PackageManifest.Version

        # If the two ever coincide this test proves nothing, so fail loudly
        # rather than pass quietly.
        $schemaVersion | Should Not Be (Get-DeclaredVersion)

        Test-ThrowsSetVersion { & $setVersion $schemaVersion -Check } |
            Should Be $true
    }

    It 'reports a mismatch rather than passing silently' {
        Test-ThrowsSetVersion { & $setVersion '99.99.99' -Check } |
            Should Be $true
    }
}

Describe 'Set-Version writes every manifest' {
    It 'round-trips a version through all three and back byte for byte' {
        $touched = @(
            'FocusThemes\source.extension.vsixmanifest'
            'vscode\package.json'
            'jetbrains\plugin\gradle.properties'
        )
        $before = @{}
        foreach ($relative in $touched) {
            $before[$relative] = [System.IO.File]::ReadAllText((Join-Path $repoRoot $relative))
        }
        $original = Get-DeclaredVersion

        try {
            & $setVersion '9.8.7' | Out-Null
            Test-ThrowsSetVersion { & $setVersion '9.8.7' -Check } | Should Be $false

            & $setVersion $original | Out-Null
            Test-ThrowsSetVersion { & $setVersion $original -Check } | Should Be $false

            # Byte-identical after the round trip. A regex that rewrote more than
            # the version - a stray attribute, the line endings, the BOM - shows
            # up here and nowhere else until release day.
            $changed = @()
            foreach ($relative in $touched) {
                $after = [System.IO.File]::ReadAllText((Join-Path $repoRoot $relative))
                if ($after -ne $before[$relative]) { $changed += $relative }
            }
            ($changed -join '; ') | Should Be ''
        }
        finally {
            # Restore regardless, so a failure part-way through cannot leave the
            # working tree pinned at 9.8.7.
            foreach ($relative in $touched) {
                [System.IO.File]::WriteAllText((Join-Path $repoRoot $relative), $before[$relative])
            }
        }
    }
}
