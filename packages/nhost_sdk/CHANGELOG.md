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
