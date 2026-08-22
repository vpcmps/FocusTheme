# Graphite and Focus Themes for Visual Studio

Two theme families for Visual Studio, packaged as independent VSIX extensions:

- **Graphite Theme** — a warm-grey light theme and a near-black dark theme.
- **Focus Themes** — six high-separation dark themes designed for fast scanning, each giving the five C# type kinds (class, interface, record, struct, and enum) a color of their own: Voltage, Ultraviolet, Reactor, Arcade, Signal, and Nightdive.

Both extensions target Visual Studio versions 17.9 through 18.x on AMD64 and ARM64.

Per-theme palette tables and the color-role reference live in the [project wiki](https://github.com/vpcmps/GraphiteTheme/wiki).

## Installation

### Visual Studio Marketplace

- [Graphite Theme](https://marketplace.visualstudio.com/items?itemName=vpcampos.GraphiteTheme)
- [Focus Themes](https://marketplace.visualstudio.com/items?itemName=vpcampos.FocusThemes)

Open **Extensions > Manage Extensions** in Visual Studio, search for the extension name, and choose **Download**.

### GitHub Release

Download the matching `.vsix` from the latest [GitHub Release](https://github.com/vpcmps/GraphiteTheme/releases), close Visual Studio, and run the package. Verify the downloaded file against `SHA256SUMS.txt` when installing outside the Marketplace.

## Development

```powershell
dotnet restore GraphiteTheme.slnx
dotnet build GraphiteTheme.slnx -c Release --no-restore
```

`Sample/AllTokens.cs` contains a compact catalogue of C# classifications for visually checking every theme.

## Release process

1. Update the `Version` in both `source.extension.vsixmanifest` files to the same stable `MAJOR.MINOR.PATCH` value.
2. Merge the version change into `main` and wait for CI.
3. Create and push the matching tag, for example `v1.0.0`.
4. The release workflow builds and validates both VSIX packages, then creates the GitHub Release.
5. Approve the `visual-studio-marketplace` environment deployment to publish both packages to the Marketplace.

Repository setup required before the first release is documented in [.github/RELEASING.md](.github/RELEASING.md).

## Privacy

These extensions contain local color themes and editor classification styles only. They do not collect telemetry, transmit data, or connect to remote services.

## License

[MIT](LICENSE.txt)
