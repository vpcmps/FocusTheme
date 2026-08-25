# Focus Themes for Visual Studio

[![Release](https://img.shields.io/github/v/release/vpcmps/FocusTheme?display_name=tag&sort=semver)](https://github.com/vpcmps/FocusTheme/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/vpcmps/FocusTheme/total)](https://github.com/vpcmps/FocusTheme/releases)
[![CI](https://github.com/vpcmps/FocusTheme/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/vpcmps/FocusTheme/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/vpcmps/FocusTheme)](https://github.com/vpcmps/FocusTheme/blob/main/LICENSE.txt)

Six high-separation dark themes for Visual Studio, designed for fast scanning. Each gives the five C# type kinds — class, interface, record, struct, and enum — a color of its own: Voltage, Ultraviolet, Reactor, Arcade, Signal, and Nightdive.

The extension targets Visual Studio versions 17.9 through 18.x on AMD64 and ARM64.

Per-theme palette tables and the color-role reference live in the [project wiki](https://github.com/vpcmps/FocusTheme/wiki).

## Installation

### Visual Studio Marketplace

[Focus Themes](https://marketplace.visualstudio.com/items?itemName=vpcampos.FocusThemes)

Open **Extensions > Manage Extensions** in Visual Studio, search for the extension name, and choose **Download**.

### GitHub Releases

Download the `.vsix` from the latest [GitHub Release](https://github.com/vpcmps/FocusTheme/releases), close Visual Studio, and run the package. Verify the downloaded file against `SHA256SUMS.txt` before installation.

## Development

```powershell
dotnet restore FocusThemes.slnx
dotnet build FocusThemes.slnx -c Release --no-restore
```

`Sample/AllTokens.cs` contains a compact catalogue of C# classifications for visually checking every theme.

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
