# Focus Themes

[![Release](https://img.shields.io/github/v/release/vpcmps/FocusTheme?display_name=tag&sort=semver)](https://github.com/vpcmps/FocusTheme/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/vpcmps/FocusTheme/total)](https://github.com/vpcmps/FocusTheme/releases)
[![CI](https://github.com/vpcmps/FocusTheme/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/vpcmps/FocusTheme/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/vpcmps/FocusTheme)](https://github.com/vpcmps/FocusTheme/blob/main/LICENSE.txt)

Six high-separation dark themes for Visual Studio, VS Code, Cursor, Rider, and PyCharm, designed for fast scanning. Each gives the five C# type kinds — class, interface, record, struct, and enum — a color of its own: Voltage, Ultraviolet, Reactor, Arcade, Signal, and Nightdive.

All five editors are painted from **one palette table**, [`scripts/focuspalette.py`](scripts/focuspalette.py). Every theme file in this repository is generated from it, and no colour is written by hand anywhere else — a test enforces that. A hue changes in one place and the whole family follows.

| Editor | Artifact | Built by |
| --- | --- | --- |
| Visual Studio 17.9–18.x (AMD64, ARM64) | `FocusThemes/Themes/*.vstheme` in a VSIX | [`gen-themes.py`](FocusThemes/Themes/gen-themes.py) |
| VS Code, Cursor | [`vscode/`](vscode) extension | [`gen-vscode.py`](vscode/gen-vscode.py) |
| Rider, PyCharm, any IntelliJ IDE | [`jetbrains/schemes/*.icls`](jetbrains/schemes) and a plugin | [`gen-jetbrains.py`](jetbrains/gen-jetbrains.py) |

Per-theme palette tables and the color-role reference live in the [project wiki](https://github.com/vpcmps/FocusTheme/wiki).

## Installation

### Visual Studio Marketplace

[Focus Themes](https://marketplace.visualstudio.com/items?itemName=vpcampos.FocusThemes)

Open **Extensions > Manage Extensions** in Visual Studio, search for the extension name, and choose **Download**.

### GitHub Releases

Download the `.vsix` from the latest [GitHub Release](https://github.com/vpcmps/FocusTheme/releases), close Visual Studio, and run the package. Verify the downloaded file against `SHA256SUMS.txt` before installation.

### VS Code and Cursor

```bash
cd vscode && npx --yes @vscode/vsce package
```

Then **Extensions > … > Install from VSIX**, and pick a theme with **Preferences: Color Theme**. Cursor is a VS Code fork and installs the same package.

### Rider and PyCharm

For the editor only, no plugin and no build: **Settings > Editor > Color Scheme > ⚙ > Import Scheme**, and choose a file from [`jetbrains/schemes/`](jetbrains/schemes).

To colour the IDE frame as well, build the plugin and install it from disk:

```bash
cd jetbrains/plugin && gradle buildPlugin
```

## Development

Every theme file is generated output. Edit the palette, never a theme:

```bash
python scripts/gen-all.py
```

That rewrites all three families from [`scripts/focuspalette.py`](scripts/focuspalette.py) and prints a contrast report for each palette. CI regenerates and diffs, so a hand-edited theme fails the build.

```powershell
dotnet restore FocusThemes.slnx
dotnet build FocusThemes.slnx -c Release --no-restore
./scripts/Test.ps1
```

`Sample/AllTokens.cs` contains a compact catalogue of C# classifications for visually checking every theme.

### Accessibility

Every syntax hue clears WCAG AA (4.5:1) against its own background; `gen-all.py` reports the ratio for each and exits non-zero if one drops below its floor. Comments, the gutter, and regex pattern text are held to 3:1 instead — deliberately, so commentary recedes rather than competing with code.

## Release process

1. Update the `Version` in `FocusThemes/source.extension.vsixmanifest` to a stable `MAJOR.MINOR.PATCH` value.
2. Merge the version change into `main` and wait for CI.
3. Create and push the matching tag, for example `v2.0.0`.
4. The release workflow builds and validates the VSIX package, then creates the GitHub Release.
5. Approve the `visual-studio-marketplace` environment deployment to publish it to the Marketplace.

Repository setup required before the first release is documented in [.github/RELEASING.md](.github/RELEASING.md).

## Privacy

These themes are local color themes and editor classification styles only. They do not collect telemetry, transmit data, or connect to remote services.

## License

[MIT](LICENSE.txt)
