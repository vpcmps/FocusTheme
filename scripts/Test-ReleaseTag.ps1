[CmdletBinding()]
param(
    [string]$Tag,
    [string]$Commit,
    [string]$MainRef = 'origin/main',
    [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-ReleaseVersionFromTag {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Tag)

    if ($Tag -notmatch '^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$') {
        throw "Tag '$Tag' must use stable vMAJOR.MINOR.PATCH format."
    }

    return $Tag.Substring(1)
}

function Assert-CommitOnMain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$Commit,
        [Parameter(Mandatory)][string]$MainRef
    )

    if (-not (Test-Path -LiteralPath $RepositoryRoot -PathType Container)) {
        throw "Repository root not found: $RepositoryRoot"
    }

    $null = & git -C $RepositoryRoot merge-base --is-ancestor $Commit $MainRef 2>&1
    $nativeExitCode = $LASTEXITCODE
    $global:LASTEXITCODE = 0

    if ($nativeExitCode -ne 0) {
        throw "Commit '$Commit' is not contained in '$MainRef'."
    }
}

function Invoke-TestReleaseTag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Tag,
        [Parameter(Mandatory)][string]$Commit,
        [Parameter(Mandatory)][string]$MainRef,
        [Parameter(Mandatory)][string]$RepositoryRoot
    )

    $version = Get-ReleaseVersionFromTag -Tag $Tag
    Assert-CommitOnMain -RepositoryRoot $RepositoryRoot -Commit $Commit -MainRef $MainRef

    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_OUTPUT)) {
        "version=$version" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
    }
    else {
        Write-Output $version
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
        $RepositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
    }
    Invoke-TestReleaseTag -Tag $Tag -Commit $Commit -MainRef $MainRef -RepositoryRoot $RepositoryRoot
}
