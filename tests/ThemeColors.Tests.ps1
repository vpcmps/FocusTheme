$repoRoot = Split-Path -Parent $PSScriptRoot

# Visual Studio ignores a colour name it does not recognise. There is no error,
# no warning and no log entry - the token simply renders unthemed. A theme can
# therefore name a classification that no longer exists, build, ship and install
# without anything going wrong until someone looks at the editor and notices a
# token is the wrong colour.
#
# These tests close that gap by checking the themes against a fixture recorded
# from a real installation by scripts/Export-ClassificationNames.ps1. The fixture
# is committed rather than generated here on purpose: the CI runner does not
# have the Visual Studio version these themes target, so a test that scanned an
# installation would find nothing and pass without verifying anything.

$fixturePath = Join-Path $PSScriptRoot 'fixtures\vs-classifications.json'

function Get-RepositoryThemeFile {
    # Recursing from the repository root reaches more than the repository: git
    # worktrees under .claude hold full copies of the tree at other commits, so a
    # plain -Recurse scan reads themes that were edited, deleted or never
    # corrected and reports them as current. Skipping dot-directories covers
    # .claude, .vs and .git in one rule; bin and obj are stale for the same reason.
    $root = [System.IO.Path]::GetFullPath($repoRoot).TrimEnd('\')
    Get-ChildItem -Path $repoRoot -Filter *.vstheme -Recurse | Where-Object {
        $parts = $_.FullName.Substring($root.Length).Trim('\').Split('\')
        -not ($parts | Where-Object { $_.StartsWith('.') -or $_ -in 'bin', 'obj' })
    }
}

# Names and GUIDs that are absent from Visual Studio 2026 and are expected to be.
# Each needs a reason: an unexplained entry here is indistinguishable from a bug
# somebody silenced.
$knownAbsent = @{
    # Legacy language service colour names from the era before Roslyn. They are
    # gone from Visual Studio 2026 entirely - not renamed, not built at runtime -
    # so the theme's entries for them do nothing. Harmless for C#, where Roslyn
    # always supplies semantics and Text Editor MEF Items wins, but they are dead
    # configuration and the fallback separation they imply does not happen.
    'String(C# @ Verbatim)'       = 'Legacy language service name, removed from VS 2026'
    'User Types(Value types)'     = 'Legacy language service name, removed from VS 2026'
    'User Types(Interfaces)'      = 'Legacy language service name, removed from VS 2026'
    'User Types(Delegates)'       = 'Legacy language service name, removed from VS 2026'
    'User Types(Enums)'           = 'Legacy language service name, removed from VS 2026'
    'User Types(Type parameters)' = 'Legacy language service name, removed from VS 2026'
}

$knownAbsentGuids = @{
    # ShellInternal is a theme colour category consumed by the shell's theming
    # system, not a Fonts and Colors category, so it is not registered the way
    # the editor categories are. Its absence from the scan is expected.
    '5af241b7-5627-4d12-bfb1-2b67d11127d7' = 'ShellInternal is a theme category, not a Fonts and Colors category'
}

Describe 'Theme colour names are recognised by Visual Studio' {
    It 'has a fixture recorded from a real installation' {
        Test-Path -LiteralPath $fixturePath -PathType Leaf | Should Be $true
        $fixture = Get-Content -Raw -LiteralPath $fixturePath | ConvertFrom-Json
        $fixture.visualStudio.version | Should Not BeNullOrEmpty
        $fixture.filesScanned -gt 0 | Should Be $true
    }

    It 'names only classifications that exist in that installation' {
        $fixture = Get-Content -Raw -LiteralPath $fixturePath | ConvertFrom-Json
        $recognized = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]$fixture.recognizedNames, [System.StringComparer]::Ordinal)

        $unexpected = @()
        foreach ($theme in Get-RepositoryThemeFile) {
            [xml]$xml = Get-Content -Raw -LiteralPath $theme.FullName
            foreach ($colour in $xml.SelectNodes("//*[local-name()='Color']")) {
                $name = [string]$colour.Name
                if ($recognized.Contains($name)) { continue }
                if ($knownAbsent.ContainsKey($name)) { continue }
                $unexpected += "$($theme.Name): $name"
            }
        }

        # Reported by name so a failure says which colour, in which theme.
        ($unexpected -join '; ') | Should Be ''
    }

    It 'uses category GUIDs that exist in that installation' {
        $fixture = Get-Content -Raw -LiteralPath $fixturePath | ConvertFrom-Json
        $recognized = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]$fixture.recognizedCategoryGuids, [System.StringComparer]::OrdinalIgnoreCase)

        $unexpected = @()
        foreach ($theme in Get-RepositoryThemeFile) {
            [xml]$xml = Get-Content -Raw -LiteralPath $theme.FullName
            foreach ($category in $xml.SelectNodes("//*[local-name()='Category']")) {
                $guid = ([string]$category.GUID).Trim('{', '}')
                if ($recognized.Contains($guid)) { continue }
                if ($knownAbsentGuids.ContainsKey($guid)) { continue }
                $unexpected += "$($theme.Name): $($category.Name) {$guid}"
            }
        }

        ($unexpected -join '; ') | Should Be ''
    }

    It 'keeps every documented exception genuinely absent' {
        # If Microsoft brings one of these back, the exception should be removed
        # rather than left to hide a name that now works.
        $fixture = Get-Content -Raw -LiteralPath $fixturePath | ConvertFrom-Json
        $recognized = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]$fixture.recognizedNames, [System.StringComparer]::Ordinal)

        $stale = @($knownAbsent.Keys | Where-Object { $recognized.Contains($_) })
        ($stale -join '; ') | Should Be ''
    }

    It 'states only roles the colour actually has a slot for' {
        # The failure this closes: a colour entry has a Background slot and a
        # Foreground slot, and most colour names carry only one. `ToolWindowText`
        # paints text, but its value lives in the Background slot - the two slots
        # are positions in a record, not "fill" and "text". State the slot a
        # colour does not have and Visual Studio drops the value silently, so the
        # theme installs and simply does not paint that token.
        #
        # Five Environment colours shipped that way. Checking the name alone
        # could not see it: every one of those names was valid.
        $fixture = Get-Content -Raw -LiteralPath $fixturePath | ConvertFrom-Json
        $slots = $fixture.colorRoleSlots
        $slots | Should Not BeNullOrEmpty

        $unexpected = @()
        foreach ($theme in Get-RepositoryThemeFile) {
            [xml]$xml = Get-Content -Raw -LiteralPath $theme.FullName
            foreach ($category in $xml.SelectNodes("//*[local-name()='Category']")) {
                foreach ($colour in $category.SelectNodes("*[local-name()='Color']")) {
                    $entry = "$([string]$category.Name)|$([string]$colour.Name)"
                    $known = $slots.PSObject.Properties[$entry]
                    # Only names Visual Studio registers under this category can be
                    # checked. A name it does not register there is a separate
                    # question, and the coverage test above owns it.
                    if ($null -eq $known) { continue }

                    $available = @([string[]]$known.Value)
                    foreach ($role in 'Background', 'Foreground') {
                        if ($null -eq $colour.SelectSingleNode("*[local-name()='$role']")) { continue }
                        if ($available -contains $role) { continue }
                        $unexpected += "$($theme.Name): $entry has no $role slot"
                    }
                }
            }
        }

        ($unexpected -join '; ') | Should Be ''
    }
}

Describe 'Focus themes cover the C# classifications Roslyn ships' {
    # Visual Studio ignores what a theme does not mention just as quietly as it
    # ignores what a theme misspells, so absence needs a test of its own. Without
    # one, a classification Roslyn adds in a future release goes unpainted and
    # nothing says so.
    #
    $knownUnpainted = @{}
    # Visual Basic only; the Focus family targets C#.
    foreach ($part in 'attribute name', 'attribute quotes', 'attribute value',
                      'cdata section', 'comment', 'delimiter', 'embedded expression',
                      'entity reference', 'name', 'processing instruction', 'text') {
        $knownUnpainted["xml literal - $part"] = 'Visual Basic only'
    }
    $knownUnpainted['roslyn test code'] = 'Internal to Roslyn test infrastructure'
    $knownUnpainted['roslyn test code markdown'] = 'Internal to Roslyn test infrastructure'

    It 'paints every classification except the documented exceptions' {
        $fixture = Get-Content -Raw -LiteralPath $fixturePath | ConvertFrom-Json
        $roslyn = @($fixture.colorRoleSlots.PSObject.Properties.Name |
            Where-Object { $_ -like 'Roslyn Text Editor MEF Items|*' } |
            ForEach-Object { $_.Split('|', 2)[1] })
        $roslyn.Count -gt 0 | Should Be $true

        $missing = @()
        foreach ($theme in Get-ChildItem -Path (Join-Path $repoRoot 'FocusThemes\Themes') -Filter *.vstheme) {
            [xml]$xml = Get-Content -Raw -LiteralPath $theme.FullName
            $painted = [System.Collections.Generic.HashSet[string]]::new(
                [string[]]@($xml.SelectNodes("//*[local-name()='Color']") | ForEach-Object { [string]$_.Name }),
                [System.StringComparer]::Ordinal)

            foreach ($name in $roslyn) {
                if ($painted.Contains($name)) { continue }
                if ($knownUnpainted.ContainsKey($name)) { continue }
                $missing += "$($theme.BaseName): $name"
            }
        }

        ($missing -join '; ') | Should Be ''
    }

    It 'keeps every unpainted exception genuinely unpainted' {
        # An exception left behind after the gap is filled hides the next gap.
        $stillListed = @()
        foreach ($theme in Get-ChildItem -Path (Join-Path $repoRoot 'FocusThemes\Themes') -Filter *.vstheme) {
            [xml]$xml = Get-Content -Raw -LiteralPath $theme.FullName
            foreach ($colour in $xml.SelectNodes("//*[local-name()='Color']")) {
                $name = [string]$colour.Name
                if ($knownUnpainted.ContainsKey($name)) { $stillListed += "$($theme.BaseName): $name" }
            }
        }

        ($stillListed -join '; ') | Should Be ''
    }
}

Describe 'Focus themes separate the five C# type kinds' {
    It 'gives class, interface, record, struct and enum distinct colours' {
        # The headline behaviour of the family. Asserted on the theme files so a
        # palette edit that collapses two kinds onto one hue fails here rather
        # than being noticed in a screenshot.
        $kinds = 'class name', 'interface name', 'record class name', 'struct name', 'enum name'

        foreach ($theme in Get-ChildItem -Path (Join-Path $repoRoot 'FocusThemes\Themes') -Filter *.vstheme) {
            [xml]$xml = Get-Content -Raw -LiteralPath $theme.FullName
            $colours = @{}
            foreach ($kind in $kinds) {
                $node = $xml.SelectSingleNode(
                    "//*[local-name()='Category'][@Name='Text Editor MEF Items']/*[local-name()='Color'][@Name='$kind']/*[local-name()='Foreground']")
                $node | Should Not BeNullOrEmpty
                $colours[$kind] = [string]$node.Source
            }

            $distinct = @($colours.Values | Sort-Object -Unique)
            "$($theme.BaseName): $($distinct.Count) distinct" | Should Be "$($theme.BaseName): 5 distinct"
        }
    }

    It 'renders interfaces in italic, which colour alone cannot express' {
        # A .vstheme carries colour only, so the interface/class distinction
        # depends on the MEF component as well as on the tint.
        $emphasis = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'FocusThemes\FocusEmphasis.cs')
        $emphasis -match '\["interface name"\]\s*=\s*Emphasis\.Italic' | Should Be $true
    }

    It 'never declares a foreground, so the theme keeps ownership of colour' {
        # The 2.0 bug in one assertion. Emphasis used to be exported as
        # ClassificationFormatDefinitions, and any format definition of ours for a
        # classification displaces the colour the theme gave it - which is how class,
        # record and interface names came to render as plain text. Emphasis is now
        # applied over the already-resolved properties, so the moment this file starts
        # naming a foreground again, that ownership has been taken back by mistake.
        # Comments are stripped first: the remarks in that file name ForegroundColor
        # while explaining the bug, and prose must not be able to fail this test.
        $code = (Get-Content -LiteralPath (Join-Path $repoRoot 'FocusThemes\FocusEmphasis.cs') |
            Where-Object { $_.TrimStart() -notmatch '^//' }) -join "`n"

        $code -match 'ForegroundColor|ForegroundBrush|SetForeground' | Should Be $false
        $code -match ':\s*ClassificationFormatDefinition' | Should Be $false
    }

    It 'emphasises exactly the documented set of classifications' {
        # Keeps the emphasis table and its rationale in step. A name added here without
        # a reason written down, or dropped without noticing, fails the build rather
        # than quietly changing how every theme reads.
        $expected = @(
            'class name', 'comment', 'extension method name', 'interface name',
            'keyword', 'keyword - control', 'method name', 'operator - overloaded',
            'parameter name', 'record class name', 'type parameter name',
            'xml doc comment - delimiter', 'xml doc comment - name',
            'xml doc comment - text'
        ) | Sort-Object

        $emphasis = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'FocusThemes\FocusEmphasis.cs')
        $actual = @([regex]::Matches($emphasis, '\["([^"]+)"\]\s*=\s*Emphasis\.') |
            ForEach-Object { $_.Groups[1].Value }) | Sort-Object

        ($actual -join ', ') | Should Be ($expected -join ', ')
    }
}
