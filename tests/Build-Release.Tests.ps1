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

Describe 'Build-Release manifest contract' {
    BeforeEach {
        $manifestPath = Join-Path $TestDrive 'source.extension.vsixmanifest'
        @'
<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Id="GraphiteTheme.test-id" Version="1.2.3" Language="en-US" Publisher="vpcampos" />
    <Icon>Assets\icon.png</Icon>
    <PreviewImage>Assets\icon.png</PreviewImage>
    <License>Assets\LICENSE.txt</License>
  </Metadata>
</PackageManifest>
'@ | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    }

    It 'reads identity and required marketplace metadata' {
        $metadata = Get-VsixManifestMetadata -Path $manifestPath

        $metadata.Id | Should Be 'GraphiteTheme.test-id'
        $metadata.Version | Should Be '1.2.3'
        $metadata.Publisher | Should Be 'vpcampos'
        $metadata.Icon | Should Be 'Assets\icon.png'
        $metadata.PreviewImage | Should Be 'Assets\icon.png'
        $metadata.License | Should Be 'Assets\LICENSE.txt'
    }

    It 'rejects a manifest without required marketplace metadata' {
        (Get-Content -Raw -LiteralPath $manifestPath).Replace('<Icon>Assets\icon.png</Icon>', '') |
            Set-Content -LiteralPath $manifestPath -Encoding UTF8

        Test-Throws {
            Assert-ManifestContract -Metadata (Get-VsixManifestMetadata -Path $manifestPath) -ExpectedVersion '1.2.3' -ExpectedPublisher 'vpcampos'
        } | Should Be $true
    }

    It 'rejects a version or publisher mismatch' {
        $metadata = Get-VsixManifestMetadata -Path $manifestPath

        Test-Throws { Assert-ManifestContract -Metadata $metadata -ExpectedVersion '9.9.9' -ExpectedPublisher 'vpcampos' } | Should Be $true
        Test-Throws { Assert-ManifestContract -Metadata $metadata -ExpectedVersion '1.2.3' -ExpectedPublisher 'another-publisher' } | Should Be $true
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
    <Identity Id="FocusThemes.test-id" Version="4.5.6" Language="en-US" Publisher="vpcampos" />
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
        $metadata.Publisher | Should Be 'vpcampos'
    }

    It 'requires the icon, preview image, and license files inside the package' {
        $archiveRoot = Join-Path $TestDrive 'complete-archive'
        $assetsRoot = Join-Path $archiveRoot 'Assets'
        $null = New-Item -ItemType Directory -Path $assetsRoot
        @'
<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Id="GraphiteTheme.test-id" Version="1.2.3" Language="en-US" Publisher="vpcampos" />
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
  "identity": { "internalName": "GraphiteTheme" },
  "overview": "overview.md",
  "priceCategory": "free",
  "publisher": "vpcampos",
  "private": false,
  "qna": true,
  "repo": "https://github.com/vpcmps/GraphiteTheme",
  "assetFiles": [
    { "pathOnDisk": "screenshots/preview.png", "targetPath": "images/preview.png" }
  ]
}
'@ | Set-Content -LiteralPath (Join-Path $listingRoot 'vs-publish.json') -Encoding UTF8

        Assert-MarketplaceManifestContract `
            -Path (Join-Path $listingRoot 'vs-publish.json') `
            -ExpectedPublisher 'vpcampos' `
            -ExpectedInternalName 'GraphiteTheme'
    }

    It 'rejects a missing listing asset or a private listing' {
        $listingRoot = Join-Path $TestDrive 'invalid-listing'
        $null = New-Item -ItemType Directory -Path $listingRoot
        '# Overview' | Set-Content -LiteralPath (Join-Path $listingRoot 'overview.md')
        @'
{
  "categories": ["coding"],
  "identity": { "internalName": "GraphiteTheme" },
  "overview": "overview.md",
  "priceCategory": "free",
  "publisher": "vpcampos",
  "private": true,
  "qna": true,
  "repo": "https://github.com/vpcmps/GraphiteTheme",
  "assetFiles": [
    { "pathOnDisk": "screenshots/missing.png", "targetPath": "images/missing.png" }
  ]
}
'@ | Set-Content -LiteralPath (Join-Path $listingRoot 'vs-publish.json') -Encoding UTF8

        Test-Throws {
            Assert-MarketplaceManifestContract `
                -Path (Join-Path $listingRoot 'vs-publish.json') `
                -ExpectedPublisher 'vpcampos' `
                -ExpectedInternalName 'GraphiteTheme'
        } | Should Be $true
    }
}

Describe 'Build-Release artifact set validation' {
    It 'accepts only when both VSIX packages and the checksum file exist' {
        $releaseRoot = Join-Path $TestDrive 'release-complete'
        $null = New-Item -ItemType Directory -Path $releaseRoot
        'graphite' | Set-Content -LiteralPath (Join-Path $releaseRoot 'GraphiteTheme-1.2.3.vsix')
        'focus' | Set-Content -LiteralPath (Join-Path $releaseRoot 'FocusThemes-1.2.3.vsix')
        'hashes' | Set-Content -LiteralPath (Join-Path $releaseRoot 'SHA256SUMS.txt')

        Assert-ReleaseArtifactSet -Directory $releaseRoot -Version '1.2.3'
    }

    It 'rejects a missing release artifact' {
        $releaseRoot = Join-Path $TestDrive 'release-incomplete'
        $null = New-Item -ItemType Directory -Path $releaseRoot
        'graphite' | Set-Content -LiteralPath (Join-Path $releaseRoot 'GraphiteTheme-1.2.3.vsix')
        'hashes' | Set-Content -LiteralPath (Join-Path $releaseRoot 'SHA256SUMS.txt')

        Test-Throws { Assert-ReleaseArtifactSet -Directory $releaseRoot -Version '1.2.3' } | Should Be $true
    }
}
