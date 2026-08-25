[CmdletBinding(DefaultParameterSetName = 'Set')]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Version,

    # Report rather than write. The release workflow uses this to prove the tag
    # and the three manifests agree before it builds anything.
    [Parameter(ParameterSetName = 'Check')]
    [switch]$Check,

    [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

<#
    The six palettes now ship as three separately packaged extensions, and each
    packaging format keeps its version somewhere different: an XML attribute, a
    JSON property, a Gradle property. Releasing them under one number means three
    edits in three syntaxes, which is exactly the kind of thing that gets done
    twice out of three times.

    This script is the one place that knows where a version lives. Adding a
    fourth target is one entry in the table below rather than a fourth thing to
    remember on release day.
#>

if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    $RepositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
}

if ($Version -notmatch '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$') {
    throw "Version '$Version' must use stable MAJOR.MINOR.PATCH format."
}

# Each target names the file, a regex that captures the version in group 1, and
# how to put a new one back. The pattern anchors on enough surrounding text to be
# unambiguous: `Version=` appears three times in the vsixmanifest, and only the
# one on <Identity> is the extension's own.
$targets = @(
    @{
        Name    = 'Visual Studio'
        Path    = 'FocusThemes\source.extension.vsixmanifest'
        Pattern = '(?<=<Identity\b[^>]*?\sVersion=")([^"]+)(?=")'
    }
    @{
        Name    = 'VS Code / Cursor'
        Path    = 'vscode\package.json'
        Pattern = '(?<="version":\s")([^"]+)(?=")'
    }
    @{
        Name    = 'JetBrains'
        Path    = 'jetbrains\plugin\gradle.properties'
        Pattern = '(?<=^pluginVersion\s=\s)(\S+)(?=\s*$)'
        Options = [System.Text.RegularExpressions.RegexOptions]::Multiline
    }
)

$mismatched = @()

foreach ($target in $targets) {
    $path = Join-Path $RepositoryRoot $target.Path
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "$($target.Name) manifest not found: $($target.Path)"
    }

    $options = if ($target.ContainsKey('Options')) { $target.Options }
               else { [System.Text.RegularExpressions.RegexOptions]::None }

    # Read and write raw, preserving the file's own encoding and line endings.
    # These are hand-maintained files, not generated ones, so a release should
    # touch the version and nothing else.
    $text = [System.IO.File]::ReadAllText($path)
    $match = [regex]::Match($text, $target.Pattern, $options)
    if (-not $match.Success) {
        throw "Could not locate a version in $($target.Path). The file format changed; update scripts/Set-Version.ps1."
    }

    $current = $match.Groups[1].Value

    if ($Check) {
        $state = if ($current -eq $Version) { 'ok ' } else { 'BAD' }
        Write-Host ("  {0} {1,-18} {2,-10} {3}" -f $state, $target.Name, $current, $target.Path)
        if ($current -ne $Version) {
            $mismatched += "$($target.Path) is $current, expected $Version"
        }
        continue
    }

    if ($current -eq $Version) {
        Write-Host ("  unchanged {0,-18} {1}" -f $target.Name, $Version)
        continue
    }

    $updated = [regex]::Replace($text, $target.Pattern, $Version, $options)
    [System.IO.File]::WriteAllText($path, $updated)
    Write-Host ("  {0,-18} {1} -> {2}" -f $target.Name, $current, $Version)
}

if ($Check) {
    if ($mismatched.Count -gt 0) {
        throw ("Version mismatch. " + ($mismatched -join '; ') +
               ". Run: pwsh -File scripts/Set-Version.ps1 $Version")
    }
    Write-Host "All three manifests are at $Version."
}
