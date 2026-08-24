<#
.SYNOPSIS
    Records which editor colour names and theme category GUIDs a Visual Studio
    installation actually recognises.

.DESCRIPTION
    Visual Studio ignores a colour name it does not know. There is no error, no
    warning and no log entry - the token simply renders unthemed, and the only
    way to notice is to look at it. A .vstheme can therefore drift out of step
    with the IDE and still build, ship and install cleanly.

    This script reads the truth out of an installation and writes it to
    tests/fixtures/vs-classifications.json, so the test suite can check the
    themes against it without needing Visual Studio present. That split matters:
    the CI runner does not have the Visual Studio version these themes target,
    so a test that scanned an installation would find nothing and pass without
    verifying anything.

    Run it by hand when Visual Studio updates, the way gen-themes.py is run by
    hand when a palette changes, and commit the result. The diff is the review.

.PARAMETER Candidates
    Names to look for. Defaults to every <Color Name> in the repository's own
    .vstheme files, which is exactly the set that needs to be valid.

.PARAMETER OutputPath
    Where to write the fixture. Defaults to tests/fixtures/vs-classifications.json.

.PARAMETER InstallationPath
    Which installation to read. Defaults to the newest one vswhere reports.

.NOTES
    Names are matched as raw bytes in both UTF-8 and UTF-16LE, across every
    binary in the IDE directory rather than a hand-picked subset. Both parts
    matter: the brace pair classifications live in the editor platform rather
    than in Roslyn, so a narrower scan reports four perfectly valid names as
    missing.

    Category GUIDs are matched in their 16-byte little-endian form, not as text.
    A GUID written into a binary is a blob, so searching for the string spelling
    finds nothing and every category looks unrecognised.
#>
[CmdletBinding()]
param(
    [string[]]$Candidates,
    [string]$OutputPath,
    [string]$InstallationPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-RepositoryRoot {
    return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
}

function Get-VisualStudioInstallation {
    [CmdletBinding()]
    param([string]$InstallationPath)

    if (-not [string]::IsNullOrWhiteSpace($InstallationPath)) {
        if (-not (Test-Path -LiteralPath $InstallationPath -PathType Container)) {
            throw "Visual Studio installation not found: $InstallationPath"
        }
        return [pscustomobject]@{ Path = $InstallationPath; Version = 'unknown' }
    }

    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path -LiteralPath $vswhere -PathType Leaf)) {
        throw "vswhere.exe not found at '$vswhere'. Pass -InstallationPath explicitly."
    }

    $found = & $vswhere -all -prerelease -latest -format json | ConvertFrom-Json
    if ($null -eq $found -or $found.Count -eq 0) {
        throw 'vswhere reported no Visual Studio installations.'
    }

    $newest = $found | Sort-Object { [version]$_.installationVersion } -Descending | Select-Object -First 1
    return [pscustomobject]@{
        Path        = $newest.installationPath
        Version     = $newest.installationVersion
        DisplayName = $newest.displayName
    }
}

function Get-ThemeColorNames {
    <#
    .SYNOPSIS
        Every <Color Name> in the repository's .vstheme files, by category.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$RepositoryRoot)

    $categories = @{}
    $guids = @{}

    foreach ($theme in Get-ChildItem -Path $RepositoryRoot -Filter *.vstheme -Recurse) {
        [xml]$xml = Get-Content -Raw -LiteralPath $theme.FullName
        foreach ($category in $xml.SelectNodes("//*[local-name()='Category']")) {
            $name = [string]$category.Name
            $guids[$name] = ([string]$category.GUID).Trim('{', '}')
            if (-not $categories.ContainsKey($name)) { $categories[$name] = [System.Collections.Generic.HashSet[string]]::new() }
            foreach ($colour in $category.SelectNodes("*[local-name()='Color']")) {
                $null = $categories[$name].Add([string]$colour.Name)
            }
        }
    }

    return [pscustomobject]@{ Categories = $categories; Guids = $guids }
}

function Find-RecognizedTokens {
    <#
    .SYNOPSIS
        Reports which of the given names and GUIDs appear in the installation.
    .DESCRIPTION
        One pass over the binaries, testing every needle against each file, so
        the cost is one read of the IDE directory rather than one per name.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstallationPath,
        [Parameter(Mandatory)][string[]]$Names,
        [Parameter(Mandatory)][string[]]$Guids
    )

    Initialize-ByteSearch

    $ide = Join-Path $InstallationPath 'Common7\IDE'
    if (-not (Test-Path -LiteralPath $ide -PathType Container)) {
        throw "Expected an IDE directory at '$ide'."
    }

    # Ordinal, not a PowerShell hashtable: hashtable keys fold case, so "Keyword"
    # and "keyword" - which are two different colour names, one per editor
    # category - would collide and only one of the pair would ever be searched
    # for. The other would be reported as missing from Visual Studio despite
    # being present.
    $needles = [System.Collections.Generic.Dictionary[string, object]]::new(
        [System.StringComparer]::Ordinal)

    # Each needle twice: managed metadata strings are UTF-8, literals are UTF-16LE.
    foreach ($name in $Names) {
        $needles["name:$name"] = @(
            [System.Text.Encoding]::UTF8.GetBytes($name),
            [System.Text.Encoding]::Unicode.GetBytes($name)
        )
    }
    foreach ($guid in $Guids) {
        # ToByteArray is little-endian, which is how a GUID is written into a binary.
        $needles["guid:$guid"] = @(, ([guid]$guid).ToByteArray())
    }

    $found = [System.Collections.Generic.HashSet[string]]::new()
    $scanned = 0

    $extensions = @('.dll', '.exe', '.pkgdef', '.vsct', '.xml')
    foreach ($file in [System.IO.Directory]::EnumerateFiles($ide, '*', 'AllDirectories')) {
        if ($extensions -notcontains [System.IO.Path]::GetExtension($file).ToLowerInvariant()) { continue }

        try { $bytes = [System.IO.File]::ReadAllBytes($file) }
        catch { continue }

        $scanned++
        foreach ($key in @($needles.Keys)) {
            if ($found.Contains($key)) { continue }
            foreach ($needle in $needles[$key]) {
                if (Test-ByteSequence -Haystack $bytes -Needle $needle) {
                    $null = $found.Add($key)
                    break
                }
            }
        }
    }

    return [pscustomobject]@{ Found = $found; FilesScanned = $scanned }
}

function Initialize-ByteSearch {
    <#
    .SYNOPSIS
        Compiles the byte-sequence search used to scan the installation.
    .DESCRIPTION
        PowerShell cannot construct a Span, so the search cannot be written
        against MemoryExtensions directly from script. Compiling the one method
        that needs it keeps the vectorised IndexOf, which matters when the scan
        reads several gigabytes.
    #>
    if (-not ('GraphiteTheme.ByteSearch' -as [type])) {
        Add-Type -TypeDefinition @'
using System;

namespace GraphiteTheme
{
    public static class ByteSearch
    {
        public static bool Contains(byte[] haystack, byte[] needle)
        {
            return new ReadOnlySpan<byte>(haystack).IndexOf(new ReadOnlySpan<byte>(needle)) >= 0;
        }
    }
}
'@
    }
}

function Test-ByteSequence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Haystack,
        [Parameter(Mandatory)][byte[]]$Needle
    )

    return [GraphiteTheme.ByteSearch]::Contains($Haystack, $Needle)
}

function Invoke-ExportClassificationNames {
    [CmdletBinding()]
    param(
        [string[]]$Candidates,
        [string]$OutputPath,
        [string]$InstallationPath
    )

    $repoRoot = Get-RepositoryRoot
    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        $OutputPath = Join-Path $repoRoot 'tests\fixtures\vs-classifications.json'
    }

    $installation = Get-VisualStudioInstallation -InstallationPath $InstallationPath
    Write-Host "Reading $($installation.DisplayName) $($installation.Version)"
    Write-Host "  $($installation.Path)"

    $themeTokens = Get-ThemeColorNames -RepositoryRoot $repoRoot
    if ($null -eq $Candidates -or $Candidates.Count -eq 0) {
        # Deduplicated case-sensitively on purpose. The two editor categories
        # spell several roles differently by case - the legacy language service
        # uses "Keyword", "String" and "Comment" while the Roslyn category uses
        # "keyword", "string" and "comment" - and they are distinct colour names,
        # not spellings of one. Sort-Object -Unique folds case and would drop one
        # of each pair, leaving half the names unverified.
        $unique = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
        foreach ($set in $themeTokens.Categories.Values) {
            foreach ($name in $set) { $null = $unique.Add($name) }
        }
        $Candidates = @($unique) | Sort-Object
    }
    $guidCandidates = $themeTokens.Guids.Values | Sort-Object -Unique

    Write-Host "Looking for $($Candidates.Count) colour name(s) and $($guidCandidates.Count) category GUID(s)."

    $result = Find-RecognizedTokens `
        -InstallationPath $installation.Path `
        -Names $Candidates `
        -Guids $guidCandidates

    Write-Host "Scanned $($result.FilesScanned) file(s)."

    $recognizedNames = @($Candidates | Where-Object { $result.Found.Contains("name:$_") } | Sort-Object)
    $missingNames = @($Candidates | Where-Object { -not $result.Found.Contains("name:$_") } | Sort-Object)
    $recognizedGuids = @($guidCandidates | Where-Object { $result.Found.Contains("guid:$_") } | Sort-Object)
    $missingGuids = @($guidCandidates | Where-Object { -not $result.Found.Contains("guid:$_") } | Sort-Object)

    $fixture = [ordered]@{
        '$comment'       = 'Generated by scripts/Export-ClassificationNames.ps1. Do not edit by hand; re-run the script when Visual Studio updates and review the diff.'
        visualStudio     = [ordered]@{
            displayName = $installation.DisplayName
            version     = $installation.Version
        }
        filesScanned     = $result.FilesScanned
        recognizedNames  = $recognizedNames
        unrecognizedNames = $missingNames
        recognizedCategoryGuids = $recognizedGuids
        unrecognizedCategoryGuids = $missingGuids
    }

    $directory = Split-Path -Parent $OutputPath
    $null = New-Item -ItemType Directory -Force -Path $directory
    ($fixture | ConvertTo-Json -Depth 6) + "`n" | Set-Content -LiteralPath $OutputPath -Encoding utf8 -NoNewline

    Write-Host ''
    Write-Host "Recognized:   $($recognizedNames.Count) name(s), $($recognizedGuids.Count) GUID(s)"
    Write-Host "Unrecognized: $($missingNames.Count) name(s), $($missingGuids.Count) GUID(s)"
    foreach ($name in $missingNames) { Write-Host "  name  $name" }
    foreach ($guid in $missingGuids) { Write-Host "  guid  $guid" }
    Write-Host ''
    Write-Host "Wrote $OutputPath"
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-ExportClassificationNames `
        -Candidates $Candidates `
        -OutputPath $OutputPath `
        -InstallationPath $InstallationPath
}
