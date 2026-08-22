# Release configuration

The repository workflows build release artifacts without external credentials. Marketplace publication additionally requires the following one-time configuration.

## Visual Studio Marketplace

1. Sign in to the [Visual Studio Marketplace publisher portal](https://marketplace.visualstudio.com/manage).
2. Create the immutable publisher ID `vpcampos` and accept the publisher agreement.
3. Create the Personal Access Token in **Azure DevOps**, not in the Marketplace portal itself — the portal links out to `https://dev.azure.com/{organization}/_usersSettings/tokens`. Three settings matter, and getting any of them wrong produces the same unhelpful error:
   - **Organization: All accessible organizations.** A token scoped to a single organization cannot publish to the Marketplace, because the Marketplace is not an organization-scoped service. This is the most common mistake.
   - **Scopes: Marketplace → Manage.** `Acquire` or `Publish` alone is not enough for `VsixPublisher.exe`.
   - The account owning the token must be an owner or contributor of the `vpcampos` publisher.

   A token that fails any of these is rejected at authentication with `VsixPub0031` / `VS30063: You are not authorized to access https://marketplace.visualstudio.com`. The message names neither the organization scope nor the missing permission, so treat it as "the token is the wrong kind" rather than "the publisher is misconfigured". A GitHub PAT pasted in by mistake fails identically.
4. In the GitHub repository, create an environment named `visual-studio-marketplace`.
5. Add the PAT as the environment secret `VS_MARKETPLACE_PAT`.
6. Add required reviewers to the environment and prevent self-review where repository policy permits it.

Do not add the Marketplace token as a repository-wide secret. Only the protected Marketplace job consumes it.

## Extension tags

`VsixPublisher.exe` validates the `<Tags>` element of `source.extension.vsixmanifest` as a **single** tag against a 50-character limit — it does not split the string on commas. A comma-separated list longer than that is rejected with `VsixPub0023`, naming the whole string as the offending tag.

Both extensions therefore keep their manifest `<Tags>` under 50 characters, and declare the full tag list as an array under `identity.tags` in `vs-publish.json`, where each entry is measured on its own. When adding a tag, change the array; only extend the manifest string if it stays within the limit.

## GitHub Actions permissions

Allow workflows to create releases with the repository `GITHUB_TOKEN`. The release job explicitly requests `contents: write`; all other jobs retain read-only permissions.

## Publishing

Both source manifests must contain the same stable version and use the public display name `Publisher="Vinícius Campos"`. The immutable Marketplace publisher ID remains `vpcampos` in both `vs-publish.json` files. After the version change is merged to `main`, create the matching tag:

```powershell
git tag v1.0.0
git push origin v1.0.0
```

The workflow creates the GitHub Release first. Marketplace publication begins only after the protected environment is approved. If publication succeeds for one extension and fails for the other, rerun the Marketplace job; `VsixPublisher.exe` can safely resend the same version.
