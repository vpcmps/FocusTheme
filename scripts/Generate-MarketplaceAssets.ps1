[CmdletBinding()]
param(
    [string]$OutputRoot,
    [string]$SamplePath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Add-Type -AssemblyName System.Drawing

function ConvertTo-DrawingColor {
    param([Parameter(Mandatory)][string]$Hex)

    return [System.Drawing.ColorTranslator]::FromHtml("#$($Hex.TrimStart('#'))")
}

function Write-GraphicText {
    param(
        [Parameter(Mandatory)][System.Drawing.Graphics]$Graphics,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory)][System.Drawing.Font]$Font,
        [Parameter(Mandatory)][System.Drawing.Color]$Color,
        [Parameter(Mandatory)][single]$X,
        [Parameter(Mandatory)][single]$Y
    )

    $brush = [System.Drawing.SolidBrush]::new($Color)
    try {
        $Graphics.DrawString($Text, $Font, $brush, $X, $Y, [System.Drawing.StringFormat]::GenericTypographic)
    }
    finally {
        $brush.Dispose()
    }
}

function Save-GraphiteIcon {
    param([Parameter(Mandatory)][string]$Path)

    $bitmap = [System.Drawing.Bitmap]::new(256, 256)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.Clear((ConvertTo-DrawingColor '171A20'))

        $layers = @(
            @{ Y = 58; Fill = '596273' },
            @{ Y = 92; Fill = '3D4553' },
            @{ Y = 126; Fill = '2B303B' }
        )
        foreach ($layer in $layers) {
            $points = [System.Drawing.Point[]]@(
                [System.Drawing.Point]::new(128, $layer.Y),
                [System.Drawing.Point]::new(216, $layer.Y + 43),
                [System.Drawing.Point]::new(128, $layer.Y + 86),
                [System.Drawing.Point]::new(40, $layer.Y + 43)
            )
            $brush = [System.Drawing.SolidBrush]::new((ConvertTo-DrawingColor $layer.Fill))
            try { $graphics.FillPolygon($brush, $points) } finally { $brush.Dispose() }
        }

        $pen = [System.Drawing.Pen]::new((ConvertTo-DrawingColor '00E8C6'), 8)
        try {
            $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
            $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
            $graphics.DrawLine($pen, 74, 66, 128, 40)
            $graphics.DrawLine($pen, 128, 40, 182, 66)
        }
        finally { $pen.Dispose() }

        $directory = Split-Path -Parent $Path
        $null = New-Item -ItemType Directory -Force -Path $directory
        $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

function Save-FocusIcon {
    param([Parameter(Mandatory)][string]$Path)

    $bitmap = [System.Drawing.Bitmap]::new(256, 256)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.Clear((ConvertTo-DrawingColor '090B10'))

        $colors = 'FF2E88', 'C77DFF', 'FF7A1A', 'FF3D7F', 'FF5C39', '4DE1C1'
        for ($index = 0; $index -lt $colors.Count; $index++) {
            $startAngle = -90 + ($index * 60)
            $pen = [System.Drawing.Pen]::new((ConvertTo-DrawingColor $colors[$index]), 18)
            try { $graphics.DrawArc($pen, 43, 43, 170, 170, $startAngle + 4, 52) } finally { $pen.Dispose() }
        }

        foreach ($ring in @(
            @{ Box = 72; Size = 112; Color = 'D6E1F2'; Width = 5 },
            @{ Box = 101; Size = 54; Color = '3BE8FF'; Width = 7 }
        )) {
            $pen = [System.Drawing.Pen]::new((ConvertTo-DrawingColor $ring.Color), $ring.Width)
            try { $graphics.DrawEllipse($pen, $ring.Box, $ring.Box, $ring.Size, $ring.Size) } finally { $pen.Dispose() }
        }

        $brush = [System.Drawing.SolidBrush]::new((ConvertTo-DrawingColor 'FF2E88'))
        try { $graphics.FillEllipse($brush, 118, 118, 20, 20) } finally { $brush.Dispose() }

        $directory = Split-Path -Parent $Path
        $null = New-Item -ItemType Directory -Force -Path $directory
        $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

function Get-CodePreviewLines {
    return @(
        @(@{ Text = 'namespace'; Kind = 'Keyword' }, @{ Text = ' Sample.Tokens'; Kind = 'Text' }),
        @(@{ Text = '{'; Kind = 'Text' }),
        @(@{ Text = '    /// Every token class the themes paint, in one file.'; Kind = 'Comment' }),
        @(@{ Text = '    public'; Kind = 'Keyword' }, @{ Text = ' sealed'; Kind = 'Keyword' }, @{ Text = ' class'; Kind = 'Keyword' }, @{ Text = ' AllTokens'; Kind = 'Type' }, @{ Text = '<T> : '; Kind = 'Text' }, @{ Text = 'ITokenSample'; Kind = 'Type' }, @{ Text = ', IDisposable'; Kind = 'Type' }),
        @(@{ Text = '        where'; Kind = 'Keyword' }, @{ Text = ' T : '; Kind = 'Text' }, @{ Text = 'class'; Kind = 'Keyword' }, @{ Text = ', '; Kind = 'Text' }, @{ Text = 'new'; Kind = 'Keyword' }, @{ Text = '()'; Kind = 'Text' }),
        @(@{ Text = '    {'; Kind = 'Text' }),
        @(@{ Text = '        private'; Kind = 'Keyword' }, @{ Text = ' readonly'; Kind = 'Keyword' }, @{ Text = ' List'; Kind = 'Type' }, @{ Text = '<string> _backing = '; Kind = 'Text' }, @{ Text = 'new'; Kind = 'Keyword' }, @{ Text = ' List'; Kind = 'Type' }, @{ Text = '<string>();'; Kind = 'Text' }),
        @(@{ Text = '        public'; Kind = 'Keyword' }, @{ Text = ' const'; Kind = 'Keyword' }, @{ Text = ' int'; Kind = 'Type' }, @{ Text = ' MaxAccents = '; Kind = 'Text' }, @{ Text = '31'; Kind = 'Number' }, @{ Text = ';'; Kind = 'Text' }),
        @(@{ Text = '        private'; Kind = 'Keyword' }, @{ Text = ' const'; Kind = 'Keyword' }, @{ Text = ' string'; Kind = 'Type' }, @{ Text = ' DefaultLabel = '; Kind = 'Text' }, @{ Text = '"graphite"'; Kind = 'String' }, @{ Text = ';'; Kind = 'Text' }),
        @(@{ Text = ''; Kind = 'Text' }),
        @(@{ Text = '        public'; Kind = 'Keyword' }, @{ Text = ' string'; Kind = 'Type' }, @{ Text = ' Label { '; Kind = 'Text' }, @{ Text = 'get'; Kind = 'Keyword' }, @{ Text = '; '; Kind = 'Text' }, @{ Text = 'init'; Kind = 'Keyword' }, @{ Text = '; } = DefaultLabel;'; Kind = 'Text' }),
        @(@{ Text = ''; Kind = 'Text' }),
        @(@{ Text = '        public'; Kind = 'Keyword' }, @{ Text = ' int'; Kind = 'Type' }, @{ Text = ' ControlFlow('; Kind = 'Method' }, @{ Text = 'IEnumerable'; Kind = 'Type' }, @{ Text = '<string> items)'; Kind = 'Text' }),
        @(@{ Text = '        {'; Kind = 'Text' }),
        @(@{ Text = '            var'; Kind = 'Keyword' }, @{ Text = ' total = '; Kind = 'Text' }, @{ Text = '0'; Kind = 'Number' }, @{ Text = ';'; Kind = 'Text' }),
        @(@{ Text = '            foreach'; Kind = 'Keyword' }, @{ Text = ' (var item '; Kind = 'Text' }, @{ Text = 'in'; Kind = 'Keyword' }, @{ Text = ' items)'; Kind = 'Text' }),
        @(@{ Text = '            {'; Kind = 'Text' }),
        @(@{ Text = '                if'; Kind = 'Keyword' }, @{ Text = ' (item '; Kind = 'Text' }, @{ Text = 'is null'; Kind = 'Keyword' }, @{ Text = ') '; Kind = 'Text' }, @{ Text = 'continue'; Kind = 'Keyword' }, @{ Text = ';'; Kind = 'Text' }),
        @(@{ Text = '                switch'; Kind = 'Keyword' }, @{ Text = ' (item.Length)'; Kind = 'Text' }),
        @(@{ Text = '                {'; Kind = 'Text' }),
        @(@{ Text = '                    case'; Kind = 'Keyword' }, @{ Text = ' 0: '; Kind = 'Text' }, @{ Text = 'goto'; Kind = 'Keyword' }, @{ Text = ' Finished;'; Kind = 'Text' }),
        @(@{ Text = '                    default'; Kind = 'Keyword' }, @{ Text = ': total += item.Length; '; Kind = 'Text' }, @{ Text = 'break'; Kind = 'Keyword' }, @{ Text = ';'; Kind = 'Text' }),
        @(@{ Text = '                }'; Kind = 'Text' }),
        @(@{ Text = '            }'; Kind = 'Text' }),
        @(@{ Text = ''; Kind = 'Text' }),
        @(@{ Text = '            return'; Kind = 'Keyword' }, @{ Text = ' total >= MaxAccents ? total : -total;'; Kind = 'Text' }),
        @(@{ Text = '        }'; Kind = 'Text' }),
        @(@{ Text = '    }'; Kind = 'Text' }),
        @(@{ Text = '}'; Kind = 'Text' })
    )
}

function Save-ThemePreview {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ThemeName,
        [Parameter(Mandatory)][hashtable]$Palette
    )

    $bitmap = [System.Drawing.Bitmap]::new(1600, 900)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $normalFont = [System.Drawing.Font]::new('Cascadia Mono', 17, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $boldFont = [System.Drawing.Font]::new('Cascadia Mono', 17, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $uiFont = [System.Drawing.Font]::new('Segoe UI', 16, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $titleFont = [System.Drawing.Font]::new('Segoe UI Semibold', 18, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    try {
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
        $graphics.Clear((ConvertTo-DrawingColor $Palette.Editor))

        $chromeBrush = [System.Drawing.SolidBrush]::new((ConvertTo-DrawingColor $Palette.Chrome))
        $panelBrush = [System.Drawing.SolidBrush]::new((ConvertTo-DrawingColor $Palette.Panel))
        $borderPen = [System.Drawing.Pen]::new((ConvertTo-DrawingColor $Palette.Border), 1)
        $accentBrush = [System.Drawing.SolidBrush]::new((ConvertTo-DrawingColor $Palette.Accent))
        try {
            $graphics.FillRectangle($chromeBrush, 0, 0, 1600, 92)
            $graphics.FillRectangle($panelBrush, 0, 92, 320, 808)
            $graphics.DrawLine($borderPen, 319, 92, 319, 900)
            $graphics.DrawLine($borderPen, 0, 91, 1600, 91)
            $graphics.FillRectangle($accentBrush, 320, 89, 1280, 3)
        }
        finally {
            $chromeBrush.Dispose()
            $panelBrush.Dispose()
            $borderPen.Dispose()
            $accentBrush.Dispose()
        }

        Write-GraphicText $graphics 'GraphiteTheme' $titleFont (ConvertTo-DrawingColor $Palette.Text) 22 18
        Write-GraphicText $graphics "Visual Studio  •  $ThemeName" $uiFont (ConvertTo-DrawingColor $Palette.Muted) 1260 21
        Write-GraphicText $graphics 'AllTokens.cs' $titleFont (ConvertTo-DrawingColor $Palette.Text) 345 58

        Write-GraphicText $graphics 'SOLUTION EXPLORER' $titleFont (ConvertTo-DrawingColor $Palette.Text) 20 116
        $tree = @(
            @{ Text = '▾  GraphiteTheme'; X = 20; Kind = 'Text' },
            @{ Text = '  ▾  Sample'; X = 38; Kind = 'Text' },
            @{ Text = '      AllTokens.cs'; X = 58; Kind = 'Accent' },
            @{ Text = '      ThemeSample.csproj'; X = 58; Kind = 'Muted' },
            @{ Text = '  ▸  GraphiteTheme'; X = 38; Kind = 'Muted' },
            @{ Text = '  ▸  FocusThemes'; X = 38; Kind = 'Muted' }
        )
        $treeY = 154
        foreach ($item in $tree) {
            $color = if ($item.Kind -eq 'Accent') { $Palette.Accent } elseif ($item.Kind -eq 'Muted') { $Palette.Muted } else { $Palette.Text }
            Write-GraphicText $graphics $item.Text $uiFont (ConvertTo-DrawingColor $color) $item.X $treeY
            $treeY += 31
        }

        $kindColors = @{
            Text = $Palette.Text; Comment = $Palette.Comment; Keyword = $Palette.Keyword
            Type = $Palette.Type; String = $Palette.String; Number = $Palette.Number; Method = $Palette.Method
        }
        $codeLines = Get-CodePreviewLines
        $lineNumber = 10
        $y = 108
        foreach ($line in $codeLines) {
            Write-GraphicText $graphics ([string]$lineNumber).PadLeft(3) $normalFont (ConvertTo-DrawingColor $Palette.Gutter) 338 $y
            $x = [single]395
            foreach ($segment in $line) {
                $font = if ($segment.Kind -eq 'Keyword') { $boldFont } else { $normalFont }
                $color = ConvertTo-DrawingColor $kindColors[$segment.Kind]
                Write-GraphicText $graphics $segment.Text $font $color $x $y
                $x += $graphics.MeasureString($segment.Text, $font, 2000, [System.Drawing.StringFormat]::GenericTypographic).Width
            }
            $lineNumber++
            $y += 25
        }

        $statusBrush = [System.Drawing.SolidBrush]::new((ConvertTo-DrawingColor $Palette.Accent))
        try { $graphics.FillRectangle($statusBrush, 0, 872, 1600, 28) } finally { $statusBrush.Dispose() }
        $statusText = if ($Palette.IsLight) { 'FFFFFF' } else { '090B10' }
        Write-GraphicText $graphics 'Ready     Ln 22, Col 18     UTF-8     C#' $uiFont (ConvertTo-DrawingColor $statusText) 18 876

        $directory = Split-Path -Parent $Path
        $null = New-Item -ItemType Directory -Force -Path $directory
        $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $normalFont.Dispose()
        $boldFont.Dispose()
        $uiFont.Dispose()
        $titleFont.Dispose()
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

function Invoke-GenerateMarketplaceAssets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$OutputRoot,
        [Parameter(Mandatory)][string]$SamplePath
    )

    if (-not (Test-Path -LiteralPath $SamplePath -PathType Leaf)) {
        throw "Sample source not found: $SamplePath"
    }
    $sample = Get-Content -Raw -LiteralPath $SamplePath
    if ($sample -notmatch 'public sealed class AllTokens<T>' -or $sample -notmatch 'public int ControlFlow') {
        throw 'Sample source no longer contains the code used by the marketplace previews.'
    }

    $palettes = @(
        @{ Family = 'GraphiteTheme'; File = 'GraphiteDark'; Name = 'Graphite Dark'; Editor = '23262E'; Chrome = '20232A'; Panel = '2B303B'; Border = '333844'; Text = 'D5CED9'; Muted = 'A0A1A7'; Gutter = '746F77'; Comment = 'A0A1A7'; Keyword = 'C74DED'; Type = 'FFE66D'; Method = '7CB7FF'; String = '96E072'; Number = 'F39C12'; Accent = '00E8C6'; IsLight = $false },
        @{ Family = 'GraphiteTheme'; File = 'GraphiteLight'; Name = 'Graphite Light'; Editor = 'FFFFFF'; Chrome = 'F5F4F8'; Panel = 'E9E7F0'; Border = 'D3D0DC'; Text = '29252E'; Muted = '615B68'; Gutter = '746F77'; Comment = '6B6570'; Keyword = '7927A0'; Type = '7A6200'; Method = '215A9B'; String = '3E6F24'; Number = '9A5700'; Accent = '007D6A'; IsLight = $true },
        @{ Family = 'FocusThemes'; File = 'FocusVoltage'; Name = 'Focus Voltage'; Editor = '090B10'; Chrome = '0D1017'; Panel = '0B0E14'; Border = '102A31'; Text = 'D6E1F2'; Muted = '5A6A85'; Gutter = '556070'; Comment = '5A6A85'; Keyword = 'FF2E88'; Type = '3BE8FF'; Method = '9B8CFF'; String = 'B6FF3D'; Number = 'FFC53D'; Accent = 'FF2E88'; IsLight = $false },
        @{ Family = 'FocusThemes'; File = 'FocusUltraviolet'; Name = 'Focus Ultraviolet'; Editor = '0B0714'; Chrome = '120C1F'; Panel = '0E0918'; Border = '2D1C3E'; Text = 'E4DAFF'; Muted = '6E5A8C'; Gutter = '64577D'; Comment = '6E5A8C'; Keyword = 'C77DFF'; Type = 'FF6EC7'; Method = '6BE1FF'; String = '5CFFB1'; Number = 'FFD166'; Accent = 'C77DFF'; IsLight = $false },
        @{ Family = 'FocusThemes'; File = 'FocusReactor'; Name = 'Focus Reactor'; Editor = '06100E'; Chrome = '0A1715'; Panel = '081310'; Border = '0C342B'; Text = 'D8F3EC'; Muted = '4E6E68'; Gutter = '49665F'; Comment = '4E6E68'; Keyword = 'FF7A1A'; Type = '2EF2C2'; Method = '63D8FF'; String = 'FFE066'; Number = 'FF4D6D'; Accent = 'FF7A1A'; IsLight = $false },
        @{ Family = 'FocusThemes'; File = 'FocusArcade'; Name = 'Focus Arcade'; Editor = '0D0912'; Chrome = '150F1C'; Panel = '100B16'; Border = '391226'; Text = 'F2E9FF'; Muted = '6B5E7A'; Gutter = '625A6E'; Comment = '6B5E7A'; Keyword = 'FF3D7F'; Type = 'FFE94E'; Method = '4DA8FF'; String = '3DFFC9'; Number = 'FF9F1C'; Accent = 'FF3D7F'; IsLight = $false },
        @{ Family = 'FocusThemes'; File = 'FocusSignal'; Name = 'Focus Signal'; Editor = '101116'; Chrome = '16181F'; Panel = '13151B'; Border = '2A2B30'; Text = 'E6E8EF'; Muted = '6B7280'; Gutter = '5E616A'; Comment = '6B7280'; Keyword = 'FF5C39'; Type = '35C2FF'; Method = 'C084FC'; String = '4ADE80'; Number = 'FBBF24'; Accent = 'FF5C39'; IsLight = $false },
        @{ Family = 'FocusThemes'; File = 'FocusNightdive'; Name = 'Focus Nightdive'; Editor = '040F14'; Chrome = '08171D'; Panel = '061319'; Border = '103130'; Text = 'D2ECF2'; Muted = '4A6B75'; Gutter = '47636A'; Comment = '4A6B75'; Keyword = '4DE1C1'; Type = 'FF6B6B'; Method = '59B8FF'; String = 'C6FF4D'; Number = 'FFC24D'; Accent = '4DE1C1'; IsLight = $false }
    )

    Save-GraphiteIcon -Path (Join-Path $OutputRoot 'GraphiteTheme\icon.png')
    Save-FocusIcon -Path (Join-Path $OutputRoot 'FocusThemes\icon.png')
    foreach ($palette in $palettes) {
        $path = Join-Path $OutputRoot "$($palette.Family)\screenshots\$($palette.File).png"
        Save-ThemePreview -Path $path -ThemeName $palette.Name -Palette $palette
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
    if ([string]::IsNullOrWhiteSpace($OutputRoot)) { $OutputRoot = Join-Path $repoRoot 'marketplace' }
    if ([string]::IsNullOrWhiteSpace($SamplePath)) { $SamplePath = Join-Path $repoRoot 'Sample\AllTokens.cs' }
    Invoke-GenerateMarketplaceAssets -OutputRoot $OutputRoot -SamplePath $SamplePath
}
