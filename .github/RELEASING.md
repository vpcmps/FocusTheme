# Release configuration

The repository workflows build release artifacts without external credentials. Marketplace publication additionally requires the following one-time configuration.

## Visual Studio Marketplace

1. Sign in to the [Visual Studio Marketplace publisher portal](https://marketplace.visualstudio.com/manage).
2. Create the immutable publisher ID `vpcampos` and accept the publisher agreement.
3. Create a Personal Access Token with only the Marketplace publish/manage permission needed by `VsixPublisher.exe`.
4. In the GitHub repository, create an environment named `visual-studio-marketplace`.
5. Add the PAT as the environment secret `VS_MARKETPLACE_PAT`.
6. Add required reviewers to the environment and prevent self-review where repository policy permits it.

Do not add the Marketplace token as a repository-wide secret. Only the protected Marketplace job consumes it.

## GitHub Actions permissions

Allow workflows to create releases with the repository `GITHUB_TOKEN`. The release job explicitly requests `contents: write`; all other jobs retain read-only permissions.

## Publishing

Both source manifests must contain the same stable version and use `Publisher="vpcampos"`. After the version change is merged to `main`, create the matching tag:

```powershell
git tag v1.0.0
git push origin v1.0.0
```

The workflow creates the GitHub Release first. Marketplace publication begins only after the protected environment is approved. If publication succeeds for one extension and fails for the other, rerun the Marketplace job; `VsixPublisher.exe` can safely resend the same version.
