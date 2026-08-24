$repoRoot = Split-Path -Parent $PSScriptRoot

# Visual Studio ignores a colour name it does not recognise. There is no error,
# no warning and no log entry - the token simply renders unthemed. A theme can
# therefore name a classification that no longer exists, build, ship and install
# without anything going wrong until someone looks at the editor and notices a
# token is the wrong colour.
#
# These tests close that gap by checking the themes against a fixture recorded
# from a real installation by scripts/Export-ClassificationNames.ps1. The fixture
# is committed rather than generated here on purpose: the CI runner does not
# have the Visual Studio version these themes target, so a test that scanned an
# installation would find nothing and pass without verifying anything.

$fixturePath = Join-Path $PSScriptRoot 'fixtures\vs-classifications.json'

# Names and GUIDs that are absent from Visual Studio 2026 and are expected to be.
# Each needs a reason: an unexplained entry here is indistinguishable from a bug
# somebody silenced.
$knownAbsent = @{
    # Legacy language service colour names from the era before Roslyn. They are
    # gone from Visual Studio 2026 entirely - not renamed, not built at runtime -
    # so the theme's entries for them do nothing. Harmless for C#, where Roslyn
    # always supplies semantics and Text Editor MEF Items wins, but they are dead
    # configuration and the fallback separation they imply does not happen.
    'String(C# @ Verbatim)'       = 'Legacy language service name, removed from VS 2026'
    'User Types(Value types)'     = 'Legacy language service name, removed from VS 2026'
    'User Types(Interfaces)'      = 'Legacy language service name, removed from VS 2026'
    'User Types(Delegates)'       = 'Legacy language service name, removed from VS 2026'
    'User Types(Enums)'           = 'Legacy language service name, removed from VS 2026'
    'User Types(Type parameters)' = 'Legacy language service name, removed from VS 2026'
}

$knownAbsentGuids = @{
    # ShellInternal is a theme colour category consumed by the shell's theming
    # system, not a Fonts and Colors category, so it is not registered the way
    # the editor categories are. Its absence from the scan is expected.
    '5af241b7-5627-4d12-bfb1-2b67d11127d7' = 'ShellInternal is a theme category, not a Fonts and Colors category'
}

Describe 'Theme colour names are recognised by Visual Studio' {
    It 'has a fixture recorded from a real installation' {
        Test-Path -LiteralPath $fixturePath -PathType Leaf | Should Be $true
        $fixture = Get-Content -Raw -LiteralPath $fixturePath | ConvertFrom-Json
        $fixture.visualStudio.version | Should Not BeNullOrEmpty
        $fixture.filesScanned -gt 0 | Should Be $true
    }

    It 'names only classifications that exist in that installation' {
        $fixture = Get-Content -Raw -LiteralPath $fixturePath | ConvertFrom-Json
        $recognized = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]$fixture.recognizedNames, [System.StringComparer]::Ordinal)

        $unexpected = @()
        foreach ($theme in Get-ChildItem -Path $repoRoot -Filter *.vstheme -Recurse) {
            [xml]$xml = Get-Content -Raw -LiteralPath $theme.FullName
            foreach ($colour in $xml.SelectNodes("//*[local-name()='Color']")) {
                $name = [string]$colour.Name
                if ($recognized.Contains($name)) { continue }
                if ($knownAbsent.ContainsKey($name)) { continue }
                $unexpected += "$($theme.Name): $name"
            }
        }

        # Reported by name so a failure says which colour, in which theme.
        ($unexpected -join '; ') | Should Be ''
    }

    It 'uses category GUIDs that exist in that installation' {
        $fixture = Get-Content -Raw -LiteralPath $fixturePath | ConvertFrom-Json
        $recognized = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]$fixture.recognizedCategoryGuids, [System.StringComparer]::OrdinalIgnoreCase)

        $unexpected = @()
        foreach ($theme in Get-ChildItem -Path $repoRoot -Filter *.vstheme -Recurse) {
            [xml]$xml = Get-Content -Raw -LiteralPath $theme.FullName
            foreach ($category in $xml.SelectNodes("//*[local-name()='Category']")) {
                $guid = ([string]$category.GUID).Trim('{', '}')
                if ($recognized.Contains($guid)) { continue }
                if ($knownAbsentGuids.ContainsKey($guid)) { continue }
                $unexpected += "$($theme.Name): $($category.Name) {$guid}"
            }
        }

        ($unexpected -join '; ') | Should Be ''
    }

    It 'keeps every documented exception genuinely absent' {
        # If Microsoft brings one of these back, the exception should be removed
        # rather than left to hide a name that now works.
        $fixture = Get-Content -Raw -LiteralPath $fixturePath | ConvertFrom-Json
        $recognized = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]$fixture.recognizedNames, [System.StringComparer]::Ordinal)

        $stale = @($knownAbsent.Keys | Where-Object { $recognized.Contains($_) })
        ($stale -join '; ') | Should Be ''
    }
}

Describe 'Focus themes separate the five C# type kinds' {
    It 'gives class, interface, record, struct and enum distinct colours' {
        # The headline behaviour of the family. Asserted on the theme files so a
        # palette edit that collapses two kinds onto one hue fails here rather
        # than being noticed in a screenshot.
        $kinds = 'class name', 'interface name', 'record class name', 'struct name', 'enum name'

        foreach ($theme in Get-ChildItem -Path (Join-Path $repoRoot 'FocusThemes\Themes') -Filter *.vstheme) {
            [xml]$xml = Get-Content -Raw -LiteralPath $theme.FullName
            $colours = @{}
            foreach ($kind in $kinds) {
                $node = $xml.SelectSingleNode(
                    "//*[local-name()='Category'][@Name='Text Editor MEF Items']/*[local-name()='Color'][@Name='$kind']/*[local-name()='Foreground']")
                $node | Should Not BeNullOrEmpty
                $colours[$kind] = [string]$node.Source
            }

            $distinct = @($colours.Values | Sort-Object -Unique)
            "$($theme.BaseName): $($distinct.Count) distinct" | Should Be "$($theme.BaseName): 5 distinct"
        }
    }

    It 'renders interfaces in italic, which colour alone cannot express' {
        # A .vstheme carries colour only, so the interface/class distinction
        # depends on the MEF component as well as on the tint.
        $emphasis = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'FocusThemes\FocusEmphasis.cs')
        $emphasis -match 'ClassificationTypeNames\s*=\s*"interface name"' | Should Be $true
    }
}
