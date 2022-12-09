## 3.0.0-dev.5

 - Update a dependency to the latest release.

## 3.0.0-dev.4

 - Update a dependency to the latest release.

## 3.0.0-dev.3

 - Update a dependency to the latest release.

## 3.0.0-dev.2

 - **FIX**: fix analyzer on ci for both stable and beta flutter sdk.

## 3.0.0-dev.1

 - Update a dependency to the latest release.

## 3.0.0-dev.0

> Note: This release has breaking changes.

 - **FIX**: upgrade deps.
 - **BREAKING** **FEAT**: increase flutter sdk constrain.

## 2.0.4

- **CHORE**: bump `nhost_sdk` version

## 2.0.3

- **CHORE**: bump `nhost_sdk` version

## 2.0.2

- **REVERT**: nhost_graphql_adapter: `nock` version bump.
- **FIX**: nhost_graphql_links: downgraded `nock` version.
- **FIX**: repo: broken links.

## 2.0.1

- **DOCS**: Update pubspec sample in READMEs.

## 2.0.0

- Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 2.0.0-beta.3

- Update a dependency to the latest release.

## 2.0.0-beta.2

> Note: This release has breaking changes.

- **BREAKING** **REFACTOR**: Rename signIn -> signInEmailPassword.

## 2.0.0-beta.1

> Note: This release has breaking changes.

- **BREAKING** **REFACTOR**: Change client names to include the word client.

## 2.0.0-beta.0

> Note: This release has breaking changes.

Migrate (partially) to the Nhost v2 backend.

- **FEAT** Slightly nicer GQL client creation (fewer parameters)

## 1.0.14

- **FIX**: Remove outdated links.

## 1.0.13

- Update a dependency to the latest release.

## 1.0.12

- **FIX**: Fix broken URLs across packages.
- **DOCS**: Remove mention of older Flutter support from READMEs.
- **CHORE**: Upgrade to latest stable SDK.
- **CHORE**: Upgrade dependencies.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.

## 1.0.11

- Update a dependency to the latest release.

## 1.0.10

- Update a dependency to the latest release.

## 1.0.9

- **FIX**: Upgrade graphql dependency to 5.0.0.

## 1.0.8

- Update a dependency to the latest release.

## 1.0.7

- Update a dependency to the latest release.

## 1.0.6

- Update a dependency to the latest release.

## 1.0.5

- Update a dependency to the latest release.

## 1.0.4

- Update a dependency to the latest release.

## 1.0.3

- Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 1.0.3-dev.5

- Update a dependency to the latest release.

## 1.0.3-dev.4

- Update a dependency to the latest release.

## 1.0.3-dev.3

- **STYLE**: Add a newline.
- **REFACTOR**: Remove the old link library.
- **REFACTOR**: Make use of nhost_gql_links in nhost_graphql_adapter.
- **REFACTOR**: Make use of nhost_gql_links in nhost_graphql_adapter.
- **CI**: Add an empty test file to satisfy CI.
- **CI**: Add an empty test folder.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.

## 1.0.3-dev.2

- Update a dependency to the latest release.

## 1.0.3-dev.1

- **REFACTOR**: Make use of nhost_gql_links in nhost_graphql_adapter.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.

## 1.0.3-dev.0

- Update a dependency to the latest release.

## 1.0.2

- **DOCS**: Fixed broken links in all README.md.

## 1.0.1

- **DOCS**: Update links to point to future repo home.
- **DOCS**: Add issue_tracker field to all pubspecs.
- **DOCS**: Update repository urls in pubspecs.
- **DOCS**: Update all version numbers in README getting starteds.
- **DOCS**: Update test badge on all repos.

## 1.0.0

- 🛳🐿

## 0.6.0+2

- Update a dependency to the latest release.

## 0.6.0+1

- **DOCS**: Update links in example READMEs to point to monorepo.
- **CHORE**: Update imports to point to new nhost_sdk top-level.
- **CHORE**: Update package repository URLs.

## 0.6.0

- Update to latest nhost_sdk

## 0.5.0

- Update to latest nhost_sdk

## 0.4.0

- Add an overload for constructing a client using an Auth object, and not a full
  NhostClient.

## 0.3.0

- Update to latest Nhost SDK

## 0.2.0

- API tweaks
  - All functions now take NhostClients, not Auth objects, as it's slightly
    easier to understand
  - Extract a combinedLinkForNhost which switches transport based on request
    type
- Add examples
- Add tests
- Improve documentation

## 0.1.0

- Re-introduce testing now that dependent packages are published

## 0.0.0

- First version, in pre-release
