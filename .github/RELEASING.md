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

## VS Code Marketplace

1. Sign in to the [Visual Studio Marketplace publisher portal](https://marketplace.visualstudio.com/manage) and create or reuse the publisher ID `vpcampos`.
2. Create the Personal Access Token in **Azure DevOps**, with **Organization: All accessible organizations** and **Scopes: Marketplace → Manage**. The same three rules as the Visual Studio token above apply, and fail the same unhelpful way.
3. Create a GitHub environment named `vscode-marketplace` and add the token as the environment secret `VSCE_PAT`.

This is a different extension from the Visual Studio one and needs its own listing, but the same Azure DevOps token can serve both if it is scoped as described.

## Open VSX

Open VSX is the registry Cursor, VSCodium, Gitpod and Eclipse Theia read. Microsoft's Marketplace terms permit only Microsoft's own products to query it, so those editors cannot see a VS Code extension published there — publishing to Open VSX is what makes the theme installable from their extensions panel rather than by hand from a `.vsix`.

1. Sign in to [open-vsx.org](https://open-vsx.org) with GitHub.
2. Sign the publisher agreement. Publication fails until this is done, with an error naming the agreement.
3. Create a namespace matching the `publisher` field in `vscode/package.json` (`vpcampos`).
4. Generate an access token from the profile settings page.
5. Create a GitHub environment named `open-vsx` and add it as the environment secret `OVSX_PAT`.

## JetBrains Marketplace

1. Sign in to [plugins.jetbrains.com](https://plugins.jetbrains.com) with a JetBrains account.
2. Upload the plugin `.zip` **once by hand**, from a GitHub Release or a local `gradle buildPlugin`. The first version of a plugin has to be uploaded manually; `publishPlugin` can only update a plugin that already exists.
3. Wait for the moderation review. First submissions are reviewed by a person and can take a few days; subsequent updates publish immediately.
4. Generate a token under **Profile → My Tokens**.
5. Create a GitHub environment named `jetbrains-marketplace` and add it as the environment secret `JETBRAINS_PUBLISH_TOKEN`.

Until step 2 is done, the `jetbrains-marketplace` job will fail. Leaving that environment without approvers is the simplest way to skip it.

## Environments and secrets, at a glance

| Environment | Secret | Publishes |
| --- | --- | --- |
| `visual-studio-marketplace` | `VS_MARKETPLACE_PAT` | Visual Studio |
| `vscode-marketplace` | `VSCE_PAT` | VS Code |
| `open-vsx` | `OVSX_PAT` | Cursor, VSCodium, Gitpod |
| `jetbrains-marketplace` | `JETBRAINS_PUBLISH_TOKEN` | Rider, PyCharm, other IntelliJ IDEs |

Each job reads only its own secret and waits on its own approval, so approving a release to one marketplace never authorises the others, and one marketplace rejecting a submission does not hold up the ones that accepted. None of these belong as repository-wide secrets.

## Extension tags

`VsixPublisher.exe` validates the `<Tags>` element of `source.extension.vsixmanifest` as a **single** tag against a 50-character limit — it does not split the string on commas. A comma-separated list longer than that is rejected with `VsixPub0023`, naming the whole string as the offending tag.

Both extensions therefore keep their manifest `<Tags>` under 50 characters, and declare the full tag list as an array under `identity.tags` in `vs-publish.json`, where each entry is measured on its own. When adding a tag, change the array; only extend the manifest string if it stays within the limit.

## GitHub Actions permissions

Allow workflows to create releases with the repository `GITHUB_TOKEN`. The release job explicitly requests `contents: write`; all other jobs retain read-only permissions.

## Publishing

All three extensions release under one version and one tag. Set it everywhere at once:

```powershell
pwsh -File scripts/Set-Version.ps1 2.1.0
```

That rewrites `FocusThemes/source.extension.vsixmanifest`, `vscode/package.json`, and `jetbrains/plugin/gradle.properties`. The release workflow re-runs the same script in `-Check` mode before building anything, so a tag that disagrees with any of the three fails in seconds rather than after two packaging jobs have produced mismatched artifacts.

Both Visual Studio source manifests must use the public display name `Publisher="Vinícius Campos"`. The immutable Marketplace publisher ID remains `vpcampos`.

After the version change is merged to `main`, create the matching tag:

```powershell
git tag v2.1.0
git push origin v2.1.0
```

The workflow then, in order:

1. Validates the tag, the ancestry, and all three manifest versions.
2. Builds and validates the Visual Studio VSIX, packages the VS Code extension, and builds and verifies the JetBrains plugin.
3. Creates the GitHub Release carrying all three packages plus `SHA256SUMS.txt`.
4. Waits for approval on each marketplace environment independently.

Every publishing job installs the artifact its packaging job produced, so what reaches a marketplace is the same bytes the GitHub Release carries. The one exception is JetBrains: `publishPlugin` builds its own archive rather than accepting a path, so that plugin is built twice from identical inputs.

If publication succeeds for one marketplace and fails for another, rerun just the failed job. `VsixPublisher.exe`, `vsce`, and `ovsx` can all safely resend the same version.
