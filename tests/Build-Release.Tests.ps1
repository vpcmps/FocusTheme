$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $repoRoot 'scripts\Build-Release.ps1')

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

Describe 'Build-Release version contract' {
    It 'accepts a stable three-part version' {
        Assert-StableVersion -Version '12.3.45' | Should Be '12.3.45'
    }

    It 'rejects tags, prereleases, and incomplete versions' {
        Test-Throws { Assert-StableVersion -Version 'v1.2.3' } | Should Be $true
        Test-Throws { Assert-StableVersion -Version '1.2.3-beta.1' } | Should Be $true
        Test-Throws { Assert-StableVersion -Version '1.2' } | Should Be $true
    }
}

Describe 'Marketplace metadata limits' {
    It 'holds the shipped manifest inside the publisher limits' {
        foreach ($name in 'FocusThemes') {
            $metadata = Get-VsixManifestMetadata -Path (Join-Path $repoRoot "$name\source.extension.vsixmanifest")
            Assert-MarketplaceMetadataLimits -Metadata $metadata -Name $name
            $metadata.Description.Trim().Length -lt 280 | Should Be $true
            $metadata.Tags.Trim().Length -le 50 | Should Be $true
        }
    }

    It 'rejects a description at or over 280 characters' {
        # VsixPub0024. 279 is the last accepted length.
        $ok = [pscustomobject]@{ Description = 'x' * 279; Tags = 'theme' }
        $over = [pscustomobject]@{ Description = 'x' * 280; Tags = 'theme' }
        Test-Throws { Assert-MarketplaceMetadataLimits -Metadata $ok -Name 'sample' } | Should Be $false
        Test-Throws { Assert-MarketplaceMetadataLimits -Metadata $over -Name 'sample' } | Should Be $true
    }

    It 'measures the whole Tags element against the 50-character limit' {
        # VsixPub0023: VsixPublisher does not split Tags on commas, so a list of
        # individually short tags still fails once the string passes 50.
        $long = 'theme, color theme, dark, high contrast, focus, adhd, accessibility'
        $metadata = [pscustomobject]@{ Description = 'A theme.'; Tags = $long }
        Test-Throws { Assert-MarketplaceMetadataLimits -Metadata $metadata -Name 'sample' } | Should Be $true
    }

    It 'rejects a missing description or tags' {
        $noDescription = [pscustomobject]@{ Description = '  '; Tags = 'theme' }
        $noTags = [pscustomobject]@{ Description = 'A theme.'; Tags = '' }
        Test-Throws { Assert-MarketplaceMetadataLimits -Metadata $noDescription -Name 'sample' } | Should Be $true
        Test-Throws { Assert-MarketplaceMetadataLimits -Metadata $noTags -Name 'sample' } | Should Be $true
    }
}

Describe 'Repository publisher contract' {
    It 'uses the public publisher name in the VSIX manifest' {
        foreach ($manifestPath in @(
            (Join-Path $repoRoot 'FocusThemes\source.extension.vsixmanifest')
        )) {
            (Get-VsixManifestMetadata -Path $manifestPath).Publisher | Should Be 'Vinícius Campos'
        }
    }

    It 'retains the immutable Marketplace publisher ID' {
        foreach ($publishManifestPath in @(
            (Join-Path $repoRoot 'marketplace\FocusThemes\vs-publish.json')
        )) {
            $publishManifest = Get-Content -Raw -LiteralPath $publishManifestPath | ConvertFrom-Json
            $publishManifest.publisher | Should Be 'vpcampos'
        }
    }
}

Describe 'Build-Release manifest contract' {
    BeforeEach {
        $manifestPath = Join-Path $TestDrive 'source.extension.vsixmanifest'
        @'
<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Id="FocusThemes.test-id" Version="1.2.3" Language="en-US" Publisher="Vinícius Campos" />
    <Icon>Assets\icon.png</Icon>
    <PreviewImage>Assets\icon.png</PreviewImage>
    <License>Assets\LICENSE.txt</License>
  </Metadata>
</PackageManifest>
'@ | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    }

    It 'reads identity and required marketplace metadata' {
        $metadata = Get-VsixManifestMetadata -Path $manifestPath

        $metadata.Id | Should Be 'FocusThemes.test-id'
        $metadata.Version | Should Be '1.2.3'
        $metadata.Publisher | Should Be 'Vinícius Campos'
        $metadata.Icon | Should Be 'Assets\icon.png'
        $metadata.PreviewImage | Should Be 'Assets\icon.png'
        $metadata.License | Should Be 'Assets\LICENSE.txt'
    }

    It 'rejects a manifest without required marketplace metadata' {
        (Get-Content -Raw -LiteralPath $manifestPath).Replace('<Icon>Assets\icon.png</Icon>', '') |
            Set-Content -LiteralPath $manifestPath -Encoding UTF8

        Test-Throws {
            Assert-ManifestContract -Metadata (Get-VsixManifestMetadata -Path $manifestPath) -ExpectedVersion '1.2.3' -ExpectedPublisherDisplayName 'Vinícius Campos'
        } | Should Be $true
    }

    It 'rejects a version or publisher mismatch' {
        $metadata = Get-VsixManifestMetadata -Path $manifestPath

        Test-Throws { Assert-ManifestContract -Metadata $metadata -ExpectedVersion '9.9.9' -ExpectedPublisherDisplayName 'Vinícius Campos' } | Should Be $true
        Test-Throws { Assert-ManifestContract -Metadata $metadata -ExpectedVersion '1.2.3' -ExpectedPublisherDisplayName 'Another Publisher' } | Should Be $true
    }
}

Describe 'Build-Release VSIX inspection' {
    It 'reads the packaged extension manifest from the VSIX archive' {
        $archiveRoot = Join-Path $TestDrive 'archive'
        $null = New-Item -ItemType Directory -Path $archiveRoot
        @'
<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Id="FocusThemes.test-id" Version="4.5.6" Language="en-US" Publisher="Vinícius Campos" />
    <Icon>Assets\icon.png</Icon>
    <PreviewImage>Assets\icon.png</PreviewImage>
    <License>Assets\LICENSE.txt</License>
  </Metadata>
</PackageManifest>
'@ | Set-Content -LiteralPath (Join-Path $archiveRoot 'extension.vsixmanifest') -Encoding UTF8

        $vsixPath = Join-Path $TestDrive 'FocusThemes.vsix'
        Compress-Archive -Path (Join-Path $archiveRoot '*') -DestinationPath $vsixPath

        $metadata = Get-PackagedVsixMetadata -Path $vsixPath
        $metadata.Id | Should Be 'FocusThemes.test-id'
        $metadata.Version | Should Be '4.5.6'
        $metadata.Publisher | Should Be 'Vinícius Campos'
    }

    It 'requires the icon, preview image, and license files inside the package' {
        $archiveRoot = Join-Path $TestDrive 'complete-archive'
        $assetsRoot = Join-Path $archiveRoot 'Assets'
        $null = New-Item -ItemType Directory -Path $assetsRoot
        @'
<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Id="FocusThemes.test-id" Version="1.2.3" Language="en-US" Publisher="Vinícius Campos" />
    <Icon>Assets\icon.png</Icon>
    <PreviewImage>Assets\icon.png</PreviewImage>
    <License>Assets\LICENSE.txt</License>
  </Metadata>
</PackageManifest>
'@ | Set-Content -LiteralPath (Join-Path $archiveRoot 'extension.vsixmanifest') -Encoding UTF8
        'png' | Set-Content -LiteralPath (Join-Path $assetsRoot 'icon.png')
        'license' | Set-Content -LiteralPath (Join-Path $assetsRoot 'LICENSE.txt')

        $completeVsix = Join-Path $TestDrive 'complete.vsix'
        Compress-Archive -Path (Join-Path $archiveRoot '*') -DestinationPath $completeVsix
        Assert-PackagedVsixAssets -Path $completeVsix -Metadata (Get-PackagedVsixMetadata -Path $completeVsix)

        $missingVsix = Join-Path $TestDrive 'missing-assets.vsix'
        Compress-Archive -Path (Join-Path $archiveRoot 'extension.vsixmanifest') -DestinationPath $missingVsix
        Test-Throws {
            Assert-PackagedVsixAssets -Path $missingVsix -Metadata (Get-PackagedVsixMetadata -Path $missingVsix)
        } | Should Be $true
    }
}

Describe 'Build-Release Marketplace manifest validation' {
    It 'accepts a complete public and free listing whose assets exist' {
        $listingRoot = Join-Path $TestDrive 'listing'
        $screenshotsRoot = Join-Path $listingRoot 'screenshots'
        $null = New-Item -ItemType Directory -Path $screenshotsRoot
        '# Overview' | Set-Content -LiteralPath (Join-Path $listingRoot 'overview.md')
        'png' | Set-Content -LiteralPath (Join-Path $screenshotsRoot 'preview.png')
        @'
{
  "categories": ["coding"],
  "identity": { "internalName": "FocusThemes" },
  "overview": "overview.md",
  "priceCategory": "free",
  "publisher": "vpcampos",
  "private": false,
  "qna": true,
  "repo": "https://github.com/vpcmps/FocusThemes",
  "assetFiles": [
    { "pathOnDisk": "screenshots/preview.png", "targetPath": "images/preview.png" }
  ]
}
'@ | Set-Content -LiteralPath (Join-Path $listingRoot 'vs-publish.json') -Encoding UTF8

        Assert-MarketplaceManifestContract `
            -Path (Join-Path $listingRoot 'vs-publish.json') `
            -ExpectedPublisherId 'vpcampos' `
            -ExpectedInternalName 'FocusThemes'
    }

    It 'rejects a missing listing asset or a private listing' {
        $listingRoot = Join-Path $TestDrive 'invalid-listing'
        $null = New-Item -ItemType Directory -Path $listingRoot
        '# Overview' | Set-Content -LiteralPath (Join-Path $listingRoot 'overview.md')
        @'
{
  "categories": ["coding"],
  "identity": { "internalName": "FocusThemes" },
  "overview": "overview.md",
  "priceCategory": "free",
  "publisher": "vpcampos",
  "private": true,
  "qna": true,
  "repo": "https://github.com/vpcmps/FocusThemes",
  "assetFiles": [
    { "pathOnDisk": "screenshots/missing.png", "targetPath": "images/missing.png" }
  ]
}
'@ | Set-Content -LiteralPath (Join-Path $listingRoot 'vs-publish.json') -Encoding UTF8

        Test-Throws {
            Assert-MarketplaceManifestContract `
                -Path (Join-Path $listingRoot 'vs-publish.json') `
                -ExpectedPublisherId 'vpcampos' `
                -ExpectedInternalName 'FocusThemes'
        } | Should Be $true
    }
}

Describe 'Build-Release artifact set validation' {
    It 'accepts only when the VSIX package and the checksum file exist' {
        $releaseRoot = Join-Path $TestDrive 'release-complete'
        $null = New-Item -ItemType Directory -Path $releaseRoot
        'focus' | Set-Content -LiteralPath (Join-Path $releaseRoot 'FocusThemes-1.2.3.vsix')
        'hashes' | Set-Content -LiteralPath (Join-Path $releaseRoot 'SHA256SUMS.txt')

        Assert-ReleaseArtifactSet -Directory $releaseRoot -Version '1.2.3'
    }

    It 'rejects a missing release artifact' {
        $releaseRoot = Join-Path $TestDrive 'release-incomplete'
        $null = New-Item -ItemType Directory -Path $releaseRoot
        'hashes' | Set-Content -LiteralPath (Join-Path $releaseRoot 'SHA256SUMS.txt')

        Test-Throws { Assert-ReleaseArtifactSet -Directory $releaseRoot -Version '1.2.3' } | Should Be $true
    }
}
