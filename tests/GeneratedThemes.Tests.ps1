$repoRoot = Split-Path -Parent $PSScriptRoot

# The six palettes now feed three editors from one table in
# scripts/focuspalette.py. That is the point of having a table at all, and it is
# exactly the kind of invariant that quietly stops being true: someone hand-edits
# a generated file, or adds a hex to a generator instead of to the table, and the
# three platforms drift apart without anything failing.
#
# These tests hold the invariant rather than the output. They do not check that a
# particular token is a particular colour - the generators and the contrast report
# already do that - they check that every colour in every generated file came from
# the shared palette, and that regenerating changes nothing.
#
# Pester 3 syntax, matching the rest of tests/: scripts/Test.ps1 deliberately runs
# the oldest Pester available so local and CI use the same engine.

$python = Get-Command python -ErrorAction SilentlyContinue
if ($null -eq $python) {
    $python = Get-Command python3 -ErrorAction SilentlyContinue
}

function Get-PaletteColor {
    <#
        .SYNOPSIS
        Every colour the shared palette can produce, across all six directions.

        .DESCRIPTION
        Asks the module itself rather than parsing the file. derive_extended()
        computes roles that appear nowhere in the source text - the lifted gutter
        grey, the blended border and selection bands, the sixteen ANSI slots - and
        a test that only read the literals would flag every one of them as foreign.
    #>
    $script = @'
import json, sys
sys.path.insert(0, sys.argv[1])
import focuspalette as fp
seen = set()
for palette in fp.PALETTES:
    for value in fp.derive_extended(palette).values():
        if isinstance(value, str) and len(value) == 6:
            try:
                int(value, 16)
            except ValueError:
                continue
            seen.add(value.upper())
print(json.dumps(sorted(seen)))
'@
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.py')
    Set-Content -LiteralPath $tmp -Value $script -Encoding UTF8
    try {
        & $python.Source $tmp (Join-Path $repoRoot 'scripts') | ConvertFrom-Json
    }
    finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

$paletteColors = Get-PaletteColor

Describe 'Shared palette' {
    It 'produces a colour for every role in every direction' {
        # Six directions times roughly forty roles, minus the values that repeat
        # across directions. A number far below this means derive_extended() lost
        # a role; far above means a generator is inventing them.
        $paletteColors.Count | Should BeGreaterThan 100
    }

    It 'is the only file in the repository holding a literal palette colour' {
        # A hex in a generator is the one failure the shared table exists to
        # prevent, so it is worth failing over rather than reviewing for.
        $generators = @(
            'FocusThemes\Themes\gen-themes.py'
            'vscode\gen-vscode.py'
            'jetbrains\gen-jetbrains.py'
            'scripts\gen-all.py'
        )
        $offenders = @()
        foreach ($relative in $generators) {
            $text = Get-Content -LiteralPath (Join-Path $repoRoot $relative) -Raw
            # Six hex digits standing alone as a quoted string. The Visual Studio
            # template legitimately contains "FF%(accent)s" and similar, which this
            # misses on purpose; FFFFFF is white, a blend target rather than a hue.
            foreach ($match in [regex]::Matches($text, '"(?!FFFFFF)([0-9A-F]{6})"')) {
                $offenders += "$relative -> $($match.Groups[1].Value)"
            }
        }
        ($offenders -join '; ') | Should Be ''
    }
}

Describe 'Visual Studio themes' {
    It 'regenerate byte for byte' {
        # Moving the palette out of gen-themes.py was not supposed to change any
        # of the six .vstheme files, so anything that did change is a bug in the
        # extraction rather than a new decision. This is the gate for that.
        $generator = Join-Path $repoRoot 'FocusThemes\Themes\gen-themes.py'
        $scratch = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $scratch | Out-Null
        try {
            & $python.Source $generator $scratch | Out-Null

            $mismatched = @()
            $written = Get-ChildItem -Path $scratch -Filter *.vstheme
            $written.Count | Should Be 6
            foreach ($file in $written) {
                $committed = Join-Path $repoRoot "FocusThemes\Themes\$($file.Name)"
                if (-not (Test-Path -LiteralPath $committed)) {
                    $mismatched += "$($file.Name) is not committed"
                    continue
                }
                # Compare normalised: the generators write LF, and a working tree
                # with core.autocrlf=true holds CRLF. That is a checkout detail,
                # not a difference in the theme.
                $fresh = ([System.IO.File]::ReadAllText($file.FullName)) -replace "`r`n", "`n"
                $old = ([System.IO.File]::ReadAllText($committed)) -replace "`r`n", "`n"
                if ($fresh -ne $old) {
                    $mismatched += "$($file.Name) differs from the committed output"
                }
            }
            ($mismatched -join '; ') | Should Be ''
        }
        finally {
            Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'VS Code themes' {
    $vscodeThemes = Get-ChildItem -Path (Join-Path $repoRoot 'vscode\themes') -Filter *.json

    It 'ship one theme per palette' {
        $vscodeThemes.Count | Should Be 6
    }

    It 'are valid JSON that declares semantic highlighting' {
        $problems = @()
        foreach ($file in $vscodeThemes) {
            $theme = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
            if ($theme.type -ne 'dark') { $problems += "$($file.Name): type is not dark" }
            # Without this flag VS Code ignores semanticTokenColors entirely, and
            # the five C# type kinds collapse back into a single class hue - which
            # is the one thing these themes exist to prevent.
            if (-not $theme.semanticHighlighting) { $problems += "$($file.Name): semanticHighlighting is off" }
            if (-not $theme.colors) { $problems += "$($file.Name): no workbench colours" }
            if (-not $theme.tokenColors) { $problems += "$($file.Name): no TextMate rules" }
        }
        ($problems -join '; ') | Should Be ''
    }

    It 'use no colour the shared palette cannot produce' {
        $foreign = @()
        foreach ($file in $vscodeThemes) {
            $text = Get-Content -LiteralPath $file.FullName -Raw
            # VS Code writes #RRGGBB or #RRGGBBAA. The alpha is appended by
            # alpha() and is not part of the palette value, so it is trimmed here.
            $used = [regex]::Matches($text, '#([0-9A-Fa-f]{6})(?:[0-9A-Fa-f]{2})?\b') |
                ForEach-Object { $_.Groups[1].Value.ToUpperInvariant() } |
                Sort-Object -Unique
            foreach ($colour in $used) {
                if ($paletteColors -notcontains $colour) { $foreign += "$($file.Name) -> #$colour" }
            }
        }
        ($foreign -join '; ') | Should Be ''
    }

    It 'are all listed in the extension manifest' {
        $manifest = Get-Content -LiteralPath (Join-Path $repoRoot 'vscode\package.json') -Raw |
            ConvertFrom-Json
        $manifest.contributes.themes.Count | Should Be 6

        $problems = @()
        foreach ($entry in $manifest.contributes.themes) {
            $relative = ($entry.path -replace '^\./', '') -replace '/', '\'
            if (-not (Test-Path -LiteralPath (Join-Path $repoRoot "vscode\$relative"))) {
                $problems += "$($entry.label) points at a missing file"
            }
            if ($entry.uiTheme -ne 'vs-dark') { $problems += "$($entry.label) is not vs-dark" }
        }
        ($problems -join '; ') | Should Be ''
    }
}

Describe 'JetBrains schemes' {
    $schemes = Get-ChildItem -Path (Join-Path $repoRoot 'jetbrains\schemes') -Filter *.icls
    $bundled = Join-Path $repoRoot 'jetbrains\plugin\src\main\resources\themes'

    It 'ship one scheme per palette' {
        $schemes.Count | Should Be 6
    }

    It 'are well-formed XML that falls back to Darcula' {
        $problems = @()
        foreach ($file in $schemes) {
            $xml = [xml](Get-Content -LiteralPath $file.FullName -Raw)
            # Darcula supplies anything the scheme does not name, the same way
            # every Focus .vstheme falls back to the built-in VS Dark.
            if ($xml.scheme.parent_scheme -ne 'Darcula') {
                $problems += "$($file.Name): parent scheme is $($xml.scheme.parent_scheme)"
            }
            $count = $xml.SelectNodes('/scheme/attributes/option').Count
            if ($count -lt 100) { $problems += "$($file.Name): only $count attributes" }
        }
        ($problems -join '; ') | Should Be ''
    }

    It 'use no colour the shared palette cannot produce' {
        $foreign = @()
        foreach ($file in $schemes) {
            $xml = [xml](Get-Content -LiteralPath $file.FullName -Raw)
            $used = $xml.SelectNodes('//option[@value]') |
                ForEach-Object { $_.value } |
                Where-Object { $_ -match '^[0-9a-f]{6}$' } |
                ForEach-Object { $_.ToUpperInvariant() } |
                Sort-Object -Unique
            foreach ($colour in $used) {
                if ($paletteColors -notcontains $colour) { $foreign += "$($file.Name) -> $colour" }
            }
        }
        ($foreign -join '; ') | Should Be ''
    }

    It 'are bundled with the plugin alongside a matching theme descriptor' {
        # The .theme.json paints the IDE frame and points editorScheme at the
        # .icls next to it. If either half goes missing or the two copies of the
        # scheme drift, the frame and the editor stop agreeing.
        $problems = @()
        foreach ($file in $schemes) {
            $twin = Join-Path $bundled $file.Name
            if (-not (Test-Path -LiteralPath $twin)) {
                $problems += "$($file.Name) is not bundled with the plugin"
                continue
            }
            if ((Get-FileHash $twin).Hash -ne (Get-FileHash $file.FullName).Hash) {
                $problems += "$($file.Name) differs between schemes/ and the plugin"
            }

            $descriptor = Join-Path $bundled ($file.BaseName + '.theme.json')
            if (-not (Test-Path -LiteralPath $descriptor)) {
                $problems += "$($file.BaseName) has no theme descriptor"
                continue
            }
            $theme = Get-Content -LiteralPath $descriptor -Raw | ConvertFrom-Json
            if (-not $theme.dark) { $problems += "$($file.BaseName) is not marked dark" }
            if ($theme.editorScheme -ne "/themes/$($file.Name)") {
                $problems += "$($file.BaseName) points at $($theme.editorScheme)"
            }
        }
        ($problems -join '; ') | Should Be ''
    }

    It 'are all registered in the plugin descriptor' {
        $descriptorPath = Join-Path $repoRoot 'jetbrains\plugin\src\main\resources\META-INF\plugin.xml'
        $xml = [xml](Get-Content -LiteralPath $descriptorPath -Raw)
        $providers = $xml.SelectNodes('//themeProvider')
        $providers.Count | Should Be 6

        $problems = @()
        foreach ($provider in $providers) {
            $relative = $provider.path -replace '/', '\'
            $path = Join-Path $repoRoot "jetbrains\plugin\src\main\resources$relative"
            if (-not (Test-Path -LiteralPath $path)) {
                $problems += "$($provider.id) points at a missing file"
            }
        }
        ($problems -join '; ') | Should Be ''
    }
}
