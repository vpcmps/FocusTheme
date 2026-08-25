[CmdletBinding()]
param(
    [string]$OutputRoot,
    [string]$SamplePath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Add-Type -AssemblyName System.Drawing

# GenericTypographic does not measure trailing spaces, so a preview segment that
# ends in one would have its neighbour drawn hard against it. Draw and measure
# both go through this copy of it, which does.
$script:TextFormat = [System.Drawing.StringFormat]::new([System.Drawing.StringFormat]::GenericTypographic)
$script:TextFormat.FormatFlags = $script:TextFormat.FormatFlags -bor [System.Drawing.StringFormatFlags]::MeasureTrailingSpaces

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
        $Graphics.DrawString($Text, $Font, $brush, $X, $Y, $script:TextFormat)
    }
    finally {
        $brush.Dispose()
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
        @(@{ Text = '    public'; Kind = 'Keyword' }, @{ Text = ' interface'; Kind = 'Keyword' }, @{ Text = ' ITokenSample'; Kind = 'Interface' }, @{ Text = ' {'; Kind = 'Text' }, @{ Text = ' int'; Kind = 'Keyword' }, @{ Text = ' Count {'; Kind = 'Text' }, @{ Text = ' get'; Kind = 'Keyword' }, @{ Text = '; } }'; Kind = 'Text' }),
        @(@{ Text = '    public'; Kind = 'Keyword' }, @{ Text = ' record'; Kind = 'Keyword' }, @{ Text = ' Palette'; Kind = 'Record' }, @{ Text = '('; Kind = 'Text' }, @{ Text = 'string'; Kind = 'Keyword' }, @{ Text = ' Name,'; Kind = 'Text' }, @{ Text = ' int'; Kind = 'Keyword' }, @{ Text = ' Size);'; Kind = 'Text' }),
        @(@{ Text = '    public'; Kind = 'Keyword' }, @{ Text = ' struct'; Kind = 'Keyword' }, @{ Text = ' Accent'; Kind = 'Struct' }, @{ Text = ' {'; Kind = 'Text' }, @{ Text = ' public'; Kind = 'Keyword' }, @{ Text = ' byte'; Kind = 'Keyword' }, @{ Text = ' R, G, B; }'; Kind = 'Text' }),
        @(@{ Text = '    public'; Kind = 'Keyword' }, @{ Text = ' enum'; Kind = 'Keyword' }, @{ Text = ' Emphasis'; Kind = 'Enum' }, @{ Text = ' { None, Italic, Bold }'; Kind = 'Text' }),
        @(@{ Text = ''; Kind = 'Text' }),
        @(@{ Text = '    public'; Kind = 'Keyword' }, @{ Text = ' sealed'; Kind = 'Keyword' }, @{ Text = ' class'; Kind = 'Keyword' }, @{ Text = ' AllTokens'; Kind = 'Class' }, @{ Text = '<T> : '; Kind = 'Text' }, @{ Text = 'ITokenSample'; Kind = 'Interface' }, @{ Text = ', '; Kind = 'Text' }, @{ Text = 'IDisposable'; Kind = 'Interface' }),
        @(@{ Text = '        where'; Kind = 'Keyword' }, @{ Text = ' T : '; Kind = 'Text' }, @{ Text = 'class'; Kind = 'Keyword' }, @{ Text = ', '; Kind = 'Text' }, @{ Text = 'new'; Kind = 'Keyword' }, @{ Text = '()'; Kind = 'Text' }),
        @(@{ Text = '    {'; Kind = 'Text' }),
        @(@{ Text = '        private'; Kind = 'Keyword' }, @{ Text = ' readonly'; Kind = 'Keyword' }, @{ Text = ' List'; Kind = 'Class' }, @{ Text = '<'; Kind = 'Text' }, @{ Text = 'string'; Kind = 'Keyword' }, @{ Text = '>'; Kind = 'Text' }, @{ Text = ' _backing'; Kind = 'Variable' }, @{ Text = ' ='; Kind = 'Operator' }, @{ Text = ' new'; Kind = 'Keyword' }, @{ Text = ' List'; Kind = 'Class' }, @{ Text = '<'; Kind = 'Text' }, @{ Text = 'string'; Kind = 'Keyword' }, @{ Text = '>();'; Kind = 'Text' }),
        @(@{ Text = '        public'; Kind = 'Keyword' }, @{ Text = ' const'; Kind = 'Keyword' }, @{ Text = ' int'; Kind = 'Keyword' }, @{ Text = ' MaxAccents'; Kind = 'Variable' }, @{ Text = ' ='; Kind = 'Operator' }, @{ Text = ' 31'; Kind = 'Number' }, @{ Text = ';'; Kind = 'Text' }),
        @(@{ Text = '        private'; Kind = 'Keyword' }, @{ Text = ' const'; Kind = 'Keyword' }, @{ Text = ' string'; Kind = 'Keyword' }, @{ Text = ' DefaultLabel'; Kind = 'Variable' }, @{ Text = ' ='; Kind = 'Operator' }, @{ Text = ' "focus"'; Kind = 'String' }, @{ Text = ';'; Kind = 'Text' }),
        @(@{ Text = '        public'; Kind = 'Keyword' }, @{ Text = ' string'; Kind = 'Keyword' }, @{ Text = ' Label'; Kind = 'Variable' }, @{ Text = ' {'; Kind = 'Text' }, @{ Text = ' get'; Kind = 'Keyword' }, @{ Text = ';'; Kind = 'Text' }, @{ Text = ' init'; Kind = 'Keyword' }, @{ Text = '; } ='; Kind = 'Text' }, @{ Text = ' DefaultLabel'; Kind = 'Variable' }, @{ Text = ';'; Kind = 'Text' }),
        @(@{ Text = '        public'; Kind = 'Keyword' }, @{ Text = ' Emphasis'; Kind = 'Enum' }, @{ Text = ' Emphasis'; Kind = 'Variable' }, @{ Text = ' {'; Kind = 'Text' }, @{ Text = ' get'; Kind = 'Keyword' }, @{ Text = ';'; Kind = 'Text' }, @{ Text = ' init'; Kind = 'Keyword' }, @{ Text = '; } ='; Kind = 'Text' }, @{ Text = ' Emphasis'; Kind = 'Enum' }, @{ Text = '.Italic;'; Kind = 'Text' }),
        @(@{ Text = ''; Kind = 'Text' }),
        @(@{ Text = '        public'; Kind = 'Keyword' }, @{ Text = ' int'; Kind = 'Keyword' }, @{ Text = ' ControlFlow'; Kind = 'Method' }, @{ Text = '('; Kind = 'Text' }, @{ Text = 'IEnumerable'; Kind = 'Interface' }, @{ Text = '<'; Kind = 'Text' }, @{ Text = 'string'; Kind = 'Keyword' }, @{ Text = '>'; Kind = 'Text' }, @{ Text = ' items'; Kind = 'Variable' }, @{ Text = ')'; Kind = 'Text' }),
        @(@{ Text = '        {'; Kind = 'Text' }),
        @(@{ Text = '            var'; Kind = 'Keyword' }, @{ Text = ' total'; Kind = 'Variable' }, @{ Text = ' ='; Kind = 'Operator' }, @{ Text = ' 0'; Kind = 'Number' }, @{ Text = ';'; Kind = 'Text' }),
        @(@{ Text = '            foreach'; Kind = 'Keyword' }, @{ Text = ' ('; Kind = 'Text' }, @{ Text = 'var'; Kind = 'Keyword' }, @{ Text = ' item'; Kind = 'Variable' }, @{ Text = ' in'; Kind = 'Keyword' }, @{ Text = ' items'; Kind = 'Variable' }, @{ Text = ')'; Kind = 'Text' }),
        @(@{ Text = '            {'; Kind = 'Text' }),
        @(@{ Text = '                if'; Kind = 'Keyword' }, @{ Text = ' ('; Kind = 'Text' }, @{ Text = 'item'; Kind = 'Variable' }, @{ Text = ' is null'; Kind = 'Keyword' }, @{ Text = ')'; Kind = 'Text' }, @{ Text = ' continue'; Kind = 'Keyword' }, @{ Text = ';'; Kind = 'Text' }),
        @(@{ Text = '                total'; Kind = 'Variable' }, @{ Text = ' +='; Kind = 'Operator' }, @{ Text = ' item'; Kind = 'Variable' }, @{ Text = '.Length'; Kind = 'Text' }, @{ Text = ' <<'; Kind = 'Operator' }, @{ Text = ' 1'; Kind = 'Number' }, @{ Text = ';'; Kind = 'Text' }),
        @(@{ Text = '            }'; Kind = 'Text' }),
        @(@{ Text = ''; Kind = 'Text' }),
        @(@{ Text = '            return'; Kind = 'Keyword' }, @{ Text = ' total'; Kind = 'Variable' }, @{ Text = ' >='; Kind = 'Operator' }, @{ Text = ' MaxAccents'; Kind = 'Variable' }, @{ Text = ' ?'; Kind = 'Operator' }, @{ Text = ' total'; Kind = 'Variable' }, @{ Text = ' :'; Kind = 'Operator' }, @{ Text = ' -'; Kind = 'Operator' }, @{ Text = 'total'; Kind = 'Variable' }, @{ Text = ';'; Kind = 'Text' }),
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

        Write-GraphicText $graphics 'FocusThemes' $titleFont (ConvertTo-DrawingColor $Palette.Text) 22 18
        Write-GraphicText $graphics "Visual Studio  •  $ThemeName" $uiFont (ConvertTo-DrawingColor $Palette.Muted) 1260 21
        Write-GraphicText $graphics 'AllTokens.cs' $titleFont (ConvertTo-DrawingColor $Palette.Text) 345 58

        Write-GraphicText $graphics 'SOLUTION EXPLORER' $titleFont (ConvertTo-DrawingColor $Palette.Text) 20 116
        $tree = @(
            @{ Text = '▾  FocusThemes'; X = 20; Kind = 'Text' },
            @{ Text = '  ▾  Sample'; X = 38; Kind = 'Text' },
            @{ Text = '      AllTokens.cs'; X = 58; Kind = 'Accent' },
            @{ Text = '      ThemeSample.csproj'; X = 58; Kind = 'Muted' },
            @{ Text = '  ▸  FocusThemes'; X = 38; Kind = 'Muted' },
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
            Class = $Palette.Class; Interface = $Palette.Interface; Record = $Palette.Record
            Struct = $Palette.Struct; Enum = $Palette.Enum; Method = $Palette.Method
            Variable = $Palette.Variable; Operator = $Palette.Operator
            String = $Palette.String; Number = $Palette.Number
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
                $x += $graphics.MeasureString($segment.Text, $font, 2000, $script:TextFormat).Width
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

    # Duplicates the palettes in FocusThemes\Themes\gen-themes.py; update it
    # whenever a palette changes there.
    $palettes = @(
        @{ Family = 'FocusThemes'; File = 'FocusVoltage'; Name = 'Focus Voltage'; Editor = '090B10'; Chrome = '0D1017'; Panel = '0B0E14'; Border = '102A31'; Text = 'D6E1F2'; Muted = '5A6A85'; Gutter = '556070'; Comment = '5A6A85'; Keyword = 'FF2E88'; Class = '3BE8FF'; Interface = '6FFFD1'; Record = 'B6FF3D'; Struct = 'FFD24D'; Enum = 'FF7A1A'; Method = '9B8CFF'; Variable = 'AEBED6'; Operator = 'FF9EC4'; String = '4ADE80'; Number = 'FFF275'; Accent = 'FF2E88'; IsLight = $false },
        @{ Family = 'FocusThemes'; File = 'FocusUltraviolet'; Name = 'Focus Ultraviolet'; Editor = '0B0714'; Chrome = '120C1F'; Panel = '0E0918'; Border = '2D1C3E'; Text = 'E4DAFF'; Muted = '6E5A8C'; Gutter = '64577D'; Comment = '6E5A8C'; Keyword = 'C77DFF'; Class = 'FF6EC7'; Interface = 'FFB3E3'; Record = '6BE1FF'; Struct = '5CFFB1'; Enum = 'FF9060'; Method = 'FFD166'; Variable = 'B7ABD4'; Operator = 'E0BFFF'; String = 'A3FF6B'; Number = 'FFF3A3'; Accent = 'C77DFF'; IsLight = $false },
        @{ Family = 'FocusThemes'; File = 'FocusReactor'; Name = 'Focus Reactor'; Editor = '06100E'; Chrome = '0A1715'; Panel = '081310'; Border = '0C342B'; Text = 'D8F3EC'; Muted = '4E6E68'; Gutter = '49665F'; Comment = '4E6E68'; Keyword = 'FF7A1A'; Class = '2EF2C2'; Interface = '9FFFE3'; Record = 'A78BFA'; Struct = 'FF6EA9'; Enum = '63D8FF'; Method = 'FFE066'; Variable = 'A9C7C0'; Operator = 'FFB27A'; String = 'C6FF4D'; Number = 'E8FF9E'; Accent = 'FF7A1A'; IsLight = $false },
        @{ Family = 'FocusThemes'; File = 'FocusArcade'; Name = 'Focus Arcade'; Editor = '0D0912'; Chrome = '150F1C'; Panel = '100B16'; Border = '391226'; Text = 'F2E9FF'; Muted = '6B5E7A'; Gutter = '625A6E'; Comment = '6B5E7A'; Keyword = 'FF3D7F'; Class = 'FFE94E'; Interface = 'FFF9C4'; Record = 'FF9F1C'; Struct = '3DFFC9'; Enum = 'C084FC'; Method = '4DA8FF'; Variable = 'C0B4D1'; Operator = 'FF9CC0'; String = '9FFF6B'; Number = 'D9FFB3'; Accent = 'FF3D7F'; IsLight = $false },
        @{ Family = 'FocusThemes'; File = 'FocusSignal'; Name = 'Focus Signal'; Editor = '101116'; Chrome = '16181F'; Panel = '13151B'; Border = '2A2B30'; Text = 'E6E8EF'; Muted = '6B7280'; Gutter = '5E616A'; Comment = '6B7280'; Keyword = 'FF5C39'; Class = '35C2FF'; Interface = '6E9BFF'; Record = 'C084FC'; Struct = '2DD4BF'; Enum = 'F472B6'; Method = 'FBBF24'; Variable = 'B4BAC7'; Operator = 'FF9E85'; String = '4ADE80'; Number = 'A3E635'; Accent = 'FF5C39'; IsLight = $false },
        @{ Family = 'FocusThemes'; File = 'FocusNightdive'; Name = 'Focus Nightdive'; Editor = '040F14'; Chrome = '08171D'; Panel = '061319'; Border = '103130'; Text = 'D2ECF2'; Muted = '4A6B75'; Gutter = '47636A'; Comment = '4A6B75'; Keyword = 'FF6B6B'; Class = '4DE1C1'; Interface = '4DF2A0'; Record = 'C6FF4D'; Struct = 'B39BFF'; Enum = 'FF9BD2'; Method = '59B8FF'; Variable = 'A3BFC7'; Operator = 'FFA8A8'; String = 'FFC24D'; Number = 'FFE3A8'; Accent = '4DE1C1'; IsLight = $false }
    )

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
