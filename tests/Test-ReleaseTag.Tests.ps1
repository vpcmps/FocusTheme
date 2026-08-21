$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $repoRoot 'scripts\Test-ReleaseTag.ps1')

function Test-ThrowsReleaseTag {
    param([Parameter(Mandatory)][scriptblock]$Action)

    try {
        & $Action
        return $false
    }
    catch {
        return $true
    }
}

Describe 'Release tag validation' {
    It 'returns the version from a stable release tag' {
        Get-ReleaseVersionFromTag -Tag 'v12.3.45' | Should Be '12.3.45'
    }

    It 'rejects malformed and prerelease tags' {
        Test-ThrowsReleaseTag { Get-ReleaseVersionFromTag -Tag '1.2.3' } | Should Be $true
        Test-ThrowsReleaseTag { Get-ReleaseVersionFromTag -Tag 'v1.2' } | Should Be $true
        Test-ThrowsReleaseTag { Get-ReleaseVersionFromTag -Tag 'v1.2.3-beta.1' } | Should Be $true
    }
}

Describe 'Release commit ancestry validation' {
    BeforeEach {
        $repository = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $repository
        git -C $repository init -b main | Out-Null
        git -C $repository config user.name 'Release Tests'
        git -C $repository config user.email 'release-tests@example.invalid'
        'main' | Set-Content -LiteralPath (Join-Path $repository 'main.txt')
        git -C $repository add main.txt
        git -C $repository commit -m 'main commit' | Out-Null
        $mainCommit = git -C $repository rev-parse HEAD

        git -C $repository checkout -b feature | Out-Null
        'feature' | Set-Content -LiteralPath (Join-Path $repository 'feature.txt')
        git -C $repository add feature.txt
        git -C $repository commit -m 'feature commit' | Out-Null
        $featureCommit = git -C $repository rev-parse HEAD
    }

    It 'accepts a commit contained in main' {
        Assert-CommitOnMain -RepositoryRoot $repository -Commit $mainCommit -MainRef 'main'
    }

    It 'rejects a commit not contained in main' {
        Test-ThrowsReleaseTag {
            Assert-CommitOnMain -RepositoryRoot $repository -Commit $featureCommit -MainRef 'main'
        } | Should Be $true
    }
}
