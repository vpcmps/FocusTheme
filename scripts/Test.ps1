[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
# GitHub's Windows image ships Pester 3 and 5; prefer the oldest available
# version so the same test engine runs locally and in CI.
$pester = Get-Module -ListAvailable Pester | Sort-Object Version | Select-Object -First 1
if ($null -eq $pester) {
    throw 'Pester is required to run the repository tests.'
}

Import-Module Pester -RequiredVersion $pester.Version -Force
if ($pester.Version.Major -ge 5) {
    $configuration = New-PesterConfiguration
    $configuration.Run.Path = Join-Path $repoRoot 'tests'
    $configuration.Run.PassThru = $true
    $configuration.Output.Verbosity = 'Detailed'
    $result = Invoke-Pester -Configuration $configuration
}
else {
    $result = Invoke-Pester -Script (Join-Path $repoRoot 'tests') -PassThru
}

if ($result.FailedCount -gt 0) {
    throw "$($result.FailedCount) test(s) failed."
}

Write-Host "$($result.PassedCount) tests passed."
