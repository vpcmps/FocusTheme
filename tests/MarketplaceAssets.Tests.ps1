$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $repoRoot 'scripts\Generate-MarketplaceAssets.ps1')

Describe 'Marketplace asset generation' {
    It 'creates two 256 square icons and eight 1600 by 900 previews' {
        $outputRoot = Join-Path $TestDrive 'marketplace'
        Invoke-GenerateMarketplaceAssets -OutputRoot $outputRoot -SamplePath (Join-Path $repoRoot 'Sample\AllTokens.cs')

        $expected = @(
            @{ Path = 'GraphiteTheme\icon.png'; Width = 256; Height = 256 },
            @{ Path = 'GraphiteTheme\screenshots\GraphiteDark.png'; Width = 1600; Height = 900 },
            @{ Path = 'GraphiteTheme\screenshots\GraphiteLight.png'; Width = 1600; Height = 900 },
            @{ Path = 'FocusThemes\icon.png'; Width = 256; Height = 256 },
            @{ Path = 'FocusThemes\screenshots\FocusVoltage.png'; Width = 1600; Height = 900 },
            @{ Path = 'FocusThemes\screenshots\FocusUltraviolet.png'; Width = 1600; Height = 900 },
            @{ Path = 'FocusThemes\screenshots\FocusReactor.png'; Width = 1600; Height = 900 },
            @{ Path = 'FocusThemes\screenshots\FocusArcade.png'; Width = 1600; Height = 900 },
            @{ Path = 'FocusThemes\screenshots\FocusSignal.png'; Width = 1600; Height = 900 },
            @{ Path = 'FocusThemes\screenshots\FocusNightdive.png'; Width = 1600; Height = 900 }
        )

        foreach ($asset in $expected) {
            $path = Join-Path $outputRoot $asset.Path
            Test-Path -LiteralPath $path -PathType Leaf | Should Be $true

            $image = [System.Drawing.Image]::FromFile($path)
            try {
                $image.Width | Should Be $asset.Width
                $image.Height | Should Be $asset.Height
            }
            finally {
                $image.Dispose()
            }
        }
    }
}
