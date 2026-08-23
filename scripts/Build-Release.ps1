[CmdletBinding()]
param(
    [string]$ExpectedVersion,
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert-StableVersion {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Version)

    if ($Version -notmatch '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$') {
        throw "Version '$Version' must use stable MAJOR.MINOR.PATCH format."
    }

    return $Version
}

function Get-VsixManifestMetadataFromXml {
    [CmdletBinding()]
    param([Parameter(Mandatory)][xml]$Xml)

    $identity = $Xml.SelectSingleNode("//*[local-name()='Metadata']/*[local-name()='Identity']")
    if ($null -eq $identity) {
        throw 'The VSIX manifest does not contain a Metadata/Identity element.'
    }

    function Get-MetadataElementValue([string]$Name) {
        $element = $Xml.SelectSingleNode("//*[local-name()='Metadata']/*[local-name()='$Name']")
        if ($null -eq $element) { return $null }
        return $element.InnerText
    }

    [pscustomobject]@{
        Id           = [string]$identity.Id
        Version      = [string]$identity.Version
        Publisher    = [string]$identity.Publisher
        Icon         = Get-MetadataElementValue 'Icon'
        PreviewImage = Get-MetadataElementValue 'PreviewImage'
        License      = Get-MetadataElementValue 'License'
        DisplayName  = Get-MetadataElementValue 'DisplayName'
        Description  = Get-MetadataElementValue 'Description'
        Tags         = Get-MetadataElementValue 'Tags'
    }
}

function Get-VsixManifestMetadata {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "VSIX manifest not found: $Path"
    }

    [xml]$xml = Get-Content -Raw -LiteralPath $Path
    return Get-VsixManifestMetadataFromXml -Xml $xml
}

function Assert-MarketplaceMetadataLimits {
    <#
    .SYNOPSIS
        Enforces the metadata limits VsixPublisher.exe applies when publishing.
    .DESCRIPTION
        These are checked here rather than left to publish time because the
        release workflow publishes one extension before the other: a violation
        in the second one is only discovered after the first is already live and
        the tag is already cut, which costs a version number to fix.

        Both limits below were found that way. Each is keyed to the error code
        VsixPublisher reports, so a future failure can be traced back here.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Metadata,
        [Parameter(Mandatory)][string]$Name
    )

    # VsixPub0024: the description must be set and under 280 characters.
    $description = [string]$Metadata.Description
    if ([string]::IsNullOrWhiteSpace($description)) {
        throw "$Name has no Description; the Marketplace requires one (VsixPub0024)."
    }
    if ($description.Trim().Length -ge 280) {
        throw ("$Name has a Description of {0} characters; the Marketplace limit is under 280 (VsixPub0024)." -f $description.Trim().Length)
    }

    # VsixPub0023: the whole Tags element is measured as a single tag, because
    # VsixPublisher does not split it on commas. A comma-separated list is
    # therefore limited to 50 characters in total, not 50 characters per tag.
    $tags = [string]$Metadata.Tags
    if ([string]::IsNullOrWhiteSpace($tags)) {
        throw "$Name has no Tags element."
    }
    if ($tags.Trim().Length -gt 50) {
        throw ("$Name has a Tags string of {0} characters; VsixPublisher measures the whole element as one tag against a 50-character limit (VsixPub0023). Put the full list in vs-publish.json under identity.tags instead." -f $tags.Trim().Length)
    }
}

function Assert-ManifestContract {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Metadata,
        [Parameter(Mandatory)][string]$ExpectedVersion,
        [Parameter(Mandatory)][string]$ExpectedPublisherDisplayName,
        [string]$ExpectedId
    )

    $null = Assert-StableVersion -Version $ExpectedVersion

    if ($Metadata.Version -ne $ExpectedVersion) {
        throw "VSIX version '$($Metadata.Version)' does not match expected version '$ExpectedVersion'."
    }
    if ($Metadata.Publisher -cne $ExpectedPublisherDisplayName) {
        throw "VSIX publisher '$($Metadata.Publisher)' does not match expected display name '$ExpectedPublisherDisplayName'."
    }
    if ($ExpectedId -and $Metadata.Id -cne $ExpectedId) {
        throw "VSIX identity '$($Metadata.Id)' does not match expected identity '$ExpectedId'."
    }

    foreach ($property in 'Icon', 'PreviewImage', 'License') {
        if ([string]::IsNullOrWhiteSpace([string]$Metadata.$property)) {
            throw "VSIX manifest is missing required metadata '$property'."
        }
    }
}

function Get-PackagedVsixMetadata {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "VSIX package not found: $Path"
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $Path))
    try {
        $entry = $archive.Entries | Where-Object FullName -eq 'extension.vsixmanifest' | Select-Object -First 1
        if ($null -eq $entry) {
            throw "VSIX package '$Path' does not contain extension.vsixmanifest."
        }

        $reader = [System.IO.StreamReader]::new($entry.Open())
        try {
            [xml]$xml = $reader.ReadToEnd()
        }
        finally {
            $reader.Dispose()
        }
    }
    finally {
        $archive.Dispose()
    }

    return Get-VsixManifestMetadataFromXml -Xml $xml
}

function Assert-PackagedVsixAssets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)]$Metadata
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $Path))
    try {
        $entries = @($archive.Entries | ForEach-Object { $_.FullName.Replace('\', '/').TrimStart('/') })
        foreach ($property in 'Icon', 'PreviewImage', 'License') {
            $requiredPath = ([string]$Metadata.$property).Replace('\', '/').TrimStart('/')
            if ($requiredPath -cnotin $entries) {
                throw "VSIX package '$Path' is missing '$requiredPath' referenced by $property."
            }
        }
    }
    finally {
        $archive.Dispose()
    }
}

function Assert-MarketplaceManifestContract {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ExpectedPublisherId,
        [Parameter(Mandatory)][string]$ExpectedInternalName
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Marketplace publish manifest not found: $Path"
    }

    $manifest = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
    $manifestRoot = Split-Path -Parent (Resolve-Path -LiteralPath $Path)

    if ([string]$manifest.publisher -cne $ExpectedPublisherId) {
        throw "Marketplace publisher ID '$($manifest.publisher)' does not match '$ExpectedPublisherId'."
    }
    if ([string]$manifest.identity.internalName -cne $ExpectedInternalName) {
        throw "Marketplace internal name '$($manifest.identity.internalName)' does not match '$ExpectedInternalName'."
    }
    if ([string]$manifest.priceCategory -cne 'free' -or [bool]$manifest.private -ne $false -or [bool]$manifest.qna -ne $true) {
        throw 'Marketplace listing must be public, free, and have Q&A enabled.'
    }
    if (@($manifest.categories).Count -lt 1 -or @($manifest.categories).Count -gt 3 -or 'coding' -cnotin @($manifest.categories)) {
        throw "Marketplace listing '$Path' must contain the coding category and between one and three categories."
    }
    if ([string]::IsNullOrWhiteSpace([string]$manifest.repo)) {
        throw "Marketplace listing '$Path' must declare its repository URL."
    }

    $overviewPath = Join-Path $manifestRoot ([string]$manifest.overview)
    if (-not (Test-Path -LiteralPath $overviewPath -PathType Leaf)) {
        throw "Marketplace overview not found: $overviewPath"
    }

    if (@($manifest.assetFiles).Count -lt 1) {
        throw "Marketplace listing '$Path' must declare at least one asset file."
    }
    foreach ($asset in $manifest.assetFiles) {
        if ([string]::IsNullOrWhiteSpace([string]$asset.pathOnDisk) -or [string]::IsNullOrWhiteSpace([string]$asset.targetPath)) {
            throw "Marketplace listing '$Path' contains an incomplete asset mapping."
        }
        $assetPath = Join-Path $manifestRoot ([string]$asset.pathOnDisk)
        if (-not (Test-Path -LiteralPath $assetPath -PathType Leaf)) {
            throw "Marketplace asset not found: $assetPath"
        }
    }
}

function Assert-ReleaseArtifactSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Directory,
        [Parameter(Mandatory)][string]$Version
    )

    $null = Assert-StableVersion -Version $Version
    foreach ($fileName in "GraphiteTheme-$Version.vsix", "FocusThemes-$Version.vsix", 'SHA256SUMS.txt') {
        $path = Join-Path $Directory $fileName
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Required release artifact not found: $path"
        }
    }
}

function Invoke-BuildRelease {
    [CmdletBinding()]
    param(
        [string]$ExpectedVersion,
        [string]$OutputDirectory
    )

    $repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
    if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
        $OutputDirectory = Join-Path $repoRoot 'artifacts\release'
    }
    elseif (-not [System.IO.Path]::IsPathRooted($OutputDirectory)) {
        $OutputDirectory = Join-Path $repoRoot $OutputDirectory
    }
    $OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)

    $extensions = @(
        [pscustomobject]@{
            Name         = 'GraphiteTheme'
            Project      = 'GraphiteTheme'
            Identity     = 'GraphiteTheme.4dae551d-1ec1-4c81-949a-350fd81f3ba1'
            ManifestPath = Join-Path $repoRoot 'GraphiteTheme\source.extension.vsixmanifest'
            PublishPath  = Join-Path $repoRoot 'marketplace\GraphiteTheme\vs-publish.json'
        },
        [pscustomobject]@{
            Name         = 'FocusThemes'
            Project      = 'FocusThemes'
            Identity     = 'FocusThemes.b9d6cd53-0821-40c2-bf4e-ef01584a6755'
            ManifestPath = Join-Path $repoRoot 'FocusThemes\source.extension.vsixmanifest'
            PublishPath  = Join-Path $repoRoot 'marketplace\FocusThemes\vs-publish.json'
        }
    )

    $sourceMetadata = @{}
    foreach ($extension in $extensions) {
        $sourceMetadata[$extension.Name] = Get-VsixManifestMetadata -Path $extension.ManifestPath
    }

    if ([string]::IsNullOrWhiteSpace($ExpectedVersion)) {
        $ExpectedVersion = $sourceMetadata[$extensions[0].Name].Version
    }
    $ExpectedVersion = Assert-StableVersion -Version $ExpectedVersion

    foreach ($extension in $extensions) {
        Assert-ManifestContract `
            -Metadata $sourceMetadata[$extension.Name] `
            -ExpectedVersion $ExpectedVersion `
            -ExpectedPublisherDisplayName 'Vinícius Campos' `
            -ExpectedId $extension.Identity
        Assert-MarketplaceMetadataLimits `
            -Metadata $sourceMetadata[$extension.Name] `
            -Name $extension.Name
        Assert-MarketplaceManifestContract `
            -Path $extension.PublishPath `
            -ExpectedPublisherId 'vpcampos' `
            -ExpectedInternalName $extension.Name
    }

    Push-Location $repoRoot
    try {
        & dotnet restore GraphiteTheme.slnx
        if ($LASTEXITCODE -ne 0) { throw "dotnet restore failed with exit code $LASTEXITCODE." }

        & dotnet build GraphiteTheme.slnx -c Release --no-restore
        if ($LASTEXITCODE -ne 0) { throw "dotnet build failed with exit code $LASTEXITCODE." }
    }
    finally {
        Pop-Location
    }

    $null = New-Item -ItemType Directory -Force -Path $OutputDirectory
    $releaseFiles = @()
    foreach ($extension in $extensions) {
        $sourceVsix = Join-Path $repoRoot "$($extension.Project)\bin\Release\net472\$($extension.Name).vsix"
        if (-not (Test-Path -LiteralPath $sourceVsix -PathType Leaf)) {
            throw "Expected build artifact was not produced: $sourceVsix"
        }

        $destinationVsix = Join-Path $OutputDirectory "$($extension.Name)-$ExpectedVersion.vsix"
        Copy-Item -LiteralPath $sourceVsix -Destination $destinationVsix -Force

        $packagedMetadata = Get-PackagedVsixMetadata -Path $destinationVsix
        Assert-ManifestContract `
            -Metadata $packagedMetadata `
            -ExpectedVersion $ExpectedVersion `
            -ExpectedPublisherDisplayName 'Vinícius Campos' `
            -ExpectedId $extension.Identity
        Assert-MarketplaceMetadataLimits -Metadata $packagedMetadata -Name $extension.Name
        Assert-PackagedVsixAssets -Path $destinationVsix -Metadata $packagedMetadata

        $releaseFiles += Get-Item -LiteralPath $destinationVsix
    }

    $checksumPath = Join-Path $OutputDirectory 'SHA256SUMS.txt'
    $checksumLines = foreach ($file in $releaseFiles) {
        $hash = Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256
        '{0} *{1}' -f $hash.Hash.ToLowerInvariant(), $file.Name
    }
    $checksumLines | Set-Content -LiteralPath $checksumPath -Encoding utf8
    Assert-ReleaseArtifactSet -Directory $OutputDirectory -Version $ExpectedVersion

    Write-Host "Release artifacts created in $OutputDirectory"
    Get-ChildItem -LiteralPath $OutputDirectory -File | Sort-Object Name | ForEach-Object {
        Write-Host " - $($_.Name)"
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-BuildRelease -ExpectedVersion $ExpectedVersion -OutputDirectory $OutputDirectory
}
