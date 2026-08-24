$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $repoRoot 'scripts\Export-ClassificationNames.ps1')

function Test-Throws {
    param([Parameter(Mandatory)][scriptblock]$Action)

    try {
        & $Action
        return $false
    }
    catch {
        return $true
    }
}

Describe 'Get-VisualStudioInstallation fallback' {
    It 'returns DisplayName when InstallationPath is supplied' {
        $path = Join-Path $TestDrive 'vs'
        $null = New-Item -ItemType Directory -Path $path
        $installation = Get-VisualStudioInstallation -InstallationPath $path
        $installation.Path | Should Be $path
        $installation.Version | Should Be 'unknown'
        $installation.DisplayName | Should Be 'unknown'
    }

    It 'throws when InstallationPath does not exist' {
        Test-Throws { Get-VisualStudioInstallation -InstallationPath (Join-Path $TestDrive 'missing') } | Should Be $true
    }
}
