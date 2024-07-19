## 5.3.1

 - **FIX**: handle null phoneNumber in User fromJson.

## 5.3.0

 - **FEAT**(nhost_flutter_auth): Allow displayName and locale to be passed on signInAnonymous (#131).

## 5.2.0

 - **FEAT**(nhost_flutter_auth): Allow displayName and locale to be passed on signInAnonymous (#131).

## 5.1.1

 - **FIX**: point to latest dep version to fix incompatible deps (#128).

## 5.1.0

 - **FEAT**(nhost_sdk): Allow metadata to be passed in signInWithSmsPassword… (#123).

## 5.0.0

 - **FEAT**(nhost_sdk): Allow metadata to be passed in signInWithSmsPassword… (#123).
 - **CHORE**(nhpst-sdk): remove support for using `localhost` in favor of passing `local` as subdomain when developing locally

## 4.1.0

 - **FEAT**(nhost-storage): added image transform options to getPresignedUrl (#102).

## 4.0.0

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 4.0.0-dev.18

 - **FIX**: trigger update.

## 4.0.0-dev.17

 - **FIX**: trigger build.

## 4.0.0-dev.15

 - **FIX**: pump sdk package version.

## 4.0.0-dev.13

 - **FEAT**: support for hasura auth and storage client and refactor them to accept only URL.

## 4.0.0-dev.12

 - **FIX**: update link to nhost_Dart from nhost_sdk.
 - **FEAT**: Support for Subdomain cloud hosting and ServiceUrls self-hosting Nhost projects.
 - **FEAT**: Support for Subdomain cloud hosting and ServiceUrls self-hosting Nhost projects.

## 4.0.0-dev.11

 - **FEAT**: seperating all clients into their own packages.
 - **FEAT**: maintian packages to high score.

## 4.0.0-dev.10

 - **FEAT**: add new packages placeholders.

## 4.0.0-dev.9

 - **FIX**: fix analyzer to fix ci.
 - **FEAT**: add signInAnonymous method.

## 4.0.0-dev.8

 - **FEAT**: add ticket to changePassword request.

## 4.0.0-dev.7

 - **FIX**: fix token expire time to be second and fix example of persistent token and silent login.

## 4.0.0-dev.6

 - **FIX**: bug in server and parsing user metadata.
 - **FEAT**: support for subdomain api.

## 4.0.0-dev.5

 - **FIX**: refresh token in query param.

## 4.0.0-dev.4

 - **FIX**: dependencies versioning.

## 4.0.0-dev.3

 - **FIX**: path could be any.

## 4.0.0-dev.2

 - **FIX**: fix analyzer on ci for both stable and beta flutter sdk.

## 4.0.0-dev.1

 - **FIX**: downgrade path to 1.8.2.

## 4.0.0-dev.0

> Note: This release has breaking changes.

 - **FIX**: upgrade deps.
 - **FIX**: upgrade deps for nhost sdk.
 - **BREAKING** **FEAT**: increase flutter sdk constrain.

## 3.0.4

- **FEAT**: Add `metadata` to sign up

## 3.0.3

- **FIX**: `lints` package moved to `dev_dependencies`

## 3.0.2

- **FIX**: nhost_graphql_links: downgraded `nock` version.
- **FIX**: repo: broken links.

## 3.0.1

- **DOCS**: Update pubspec sample in READMEs.

## 3.0.0

- Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 3.0.0-beta.3

- **FEAT**: Add endpoint for resending verification email.

## 3.0.0-beta.2

> Note: This release has breaking changes.

- **REFACTOR**: Change all instances of login to sign in.
- **REFACTOR**: Only create the session completer if required.
- **REFACTOR**: Remove AuthResponse's user parameter.
- **REFACTOR**: Add an exception base class.
- **FIX**: Null out the current user after the session is cleared.
- **BREAKING** **REFACTOR**: Rename signIn -> signInEmailPassword.
- **BREAKING** **REFACTOR**: Improve refresh-token based authentication.
- **BREAKING** **REFACTOR**: Rename all occurrences of jwt to accessToken.

## 3.0.0-beta.1

> Note: This release has breaking changes.

- **REFACTOR**: Add an ApiClient.request method for sending general requests.
- **FEAT**: Support additional HTTP methods on function calls.
- **FEAT**: Add a query string param to ApiClient.delete.
- **BREAKING** **REFACTOR**: Rename NhostFunctionsClient.{invoke, callFunction}.
- **BREAKING** **REFACTOR**: Change client names to include the word client.

## 3.0.0-beta.0

> Note: This release has breaking changes.

Migrate (partially) to the Nhost v2 backend.

- **FEAT** Single URL configuration of `NhostClient`s
- **FEAT** Serverless function calls, via `NhostClient.functions`
- **FEAT** GraphQL-based storage of file metadata
- **FEAT** Pre-signed URLs for sharing of protected files `Storage.getPresignedUrl`
- **FEAT** Additional image transformation parameters in `Storage.downloadImage`
- **REFACTOR** Dev server scripts/configs for running the examples
- **TEST** Improved testability with a new test dev server, HTTP proxy support in
  testing environments, and environment-driven logging

## 2.1.1

- **FIX**: Remove outdated links.

## 2.1.0

- **TEST**: Fix tests to run against a local Nhost instance.
- **REFACTOR**: Extract response handling logic into its own method.
- **FEAT**: Add support for reporting file upload progress.
- **FEAT**: Add FileMetadata.toString() method.
- **CHORE**: Update example to null-safety.

## 2.0.2

- **FIX**: Fix broken URLs across packages.
- **FIX**: Change early return condition for clear session.
- **DOCS**: Reformat a comment.
- **CHORE**: Upgrade to latest stable SDK.
- **CHORE**: Upgrade dependencies.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.

## 2.0.1

- **FIX**: Change early return condition for clear session.

## 2.0.0

> Note: This release has breaking changes.

- **DOCS**: Update major version in README.
- **DOCS**: Fix an incorrect method reference in a comment.
- **BREAKING** **FEAT**: Update auth state callback to include loading state.

## 1.1.1

- **FIX**: Upgrade graphql dependency to 5.0.0.

## 1.1.0

- **FEAT**: Add use of the logging package.

## 1.0.4

- **STYLE**: Reformat Dart files to pass CI.
- **FIX**: Add debug printing when token refreshes fail.
- **FIX**: Keep auth refresh-locked when a refresh is already in process.
- **CHORE**: Upgrade graphql dependency to 5.0.0-beta.2.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.

## 1.0.3

- Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 1.0.3-dev.2

> Note: This release has breaking changes.

- **REFACTOR**: Make use of nhost_gql_links in nhost_graphql_adapter.
- **REFACTOR**: Make use of nhost_gql_links in nhost_graphql_adapter.
- **FIX**: Couple build fixes.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.
- **BREAKING** **FIX**: Couple build fixes.

## 1.0.3-dev.1

> Note: This release has breaking changes.

- **REFACTOR**: Make use of nhost_gql_links in nhost_graphql_adapter.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.
- **BREAKING** **FIX**: Couple build fixes.

## 1.0.3-dev.0

- **FIX**: Add nullability to Session fields.
- **FIX**: Add nullability to Session fields.
- **CHORE**: Publish packages.
- **CHORE**: Publish packages.

## 1.0.2

- **FIX**: Add nullability to Session fields.
- **DOCS**: Fixed broken links in all README.md.

## 1.0.1

- **TEST**: Close Nhost client after each test.
- **TEST**: Add a stub user to the test session.
- **FIX**: Throw ArgumentError if list expected during deserialization.
- **DOCS**: Update links to point to future repo home.
- **DOCS**: Add issue_tracker field to all pubspecs.
- **DOCS**: Update repository urls in pubspecs.
- **DOCS**: Update all version numbers in README getting starteds.
- **DOCS**: Update test badge on all repos.
- **CHORE**: Remove unused function from tests.
- **CHORE**: Remove debug printing which is no longer needed.
- **CHORE**: Remove a couple of unnecessary toJson methods.
- **CHORE**: Remove several TODOs that have been answered.

## 1.0.0

- 🛳🐿

## 0.8.0+1

- **FIX**: Correct the refresh token lookup during OAuth login.
- **FIX**: Ensure that loading is set to false when no token is provided.
- **CI**: Set up repository-wide continuous tests.
- **CHORE**: Publish packages.

## 0.8.0

> Note: This release has breaking changes.

- **DOCS**: Update links in example READMEs to point to monorepo.
- **CHORE**: Update package repository URLs.
- **BREAKING** **REFACTOR**: Change name of public file to mirror package name.

## 0.7.0

- Add method to help with completing OAuth provider logins
- Change package name to nhost_sdk

## 0.6.0

- Fix bug in authentication state change. I missed a boolean.

## 0.5.0

- Remove isAuthenticated, and introduce authenticationState — a tri-state enum.
  Nullable booleans are too easy to make mistakes with.

## 0.4.0

- Remove dependency on dart:io

## 0.3.0

- Upgrade to work with latest nhost_graphql_adapter library, which had a few
  breaking changes

## 0.2.0

- Add fileToken support to storage APIs
- Remove dependency on json_serializable
- Improve examples

## 0.1.0

- Add support for auto-login, and externally provided refresh tokens

## 0.0.0

- First version, in pre-release
