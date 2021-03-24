# Contributing to this repository
## Getting started

This repository contains multiple Dart/Flutter packages, which can be found
in the [`packages` directory](https://github.com/shyndman/nhost-dart/tree/main/packages).

We use a tool called [`melos`](https://pub.dev/packages/melos) to make this
process easier.

After cloning the repo, the first thing you should do is run the following
from the repository root:

```sh
pub get
pub global activate melos
melos bootstrap
```

This will install the necessary prequisites, and establish **path** dependencies
between our packages.

Path dependencies simplify development by taking the package repository and
version numbers out of the equation, meaning we can make changes freely across
package boundaries and have those changes be recognized by dependents instantly.

When it comes time to publish, `melos` will fix up the requirements
automatically.

### Commit message conventions

`melos` is able to automatically update the packages' version numbers and
[CHANGELOG.md](https://github.com/shyndman/nhost-dart/blob/main/packages/nhost_sdk/CHANGELOG.md)s
as long as commits follow the [Conventional
Commits](https://www.conventionalcommits.org/en/v1.0.0/) spec.

We've included a [VSCode
snippet](https://github.com/shyndman/nhost-dart/blob/main/.vscode/conventional-commits.code-snippets) with the repository that will help with the formatting.

Just write `ccommit` <kbd>Tab</kbd> in your commit message, and the snippet
will expand.

## Running tests

Tests are automatically run by GitHub on every commit, but if you want to
run them locally, run `melos run test`.

## Publishing
### Updating package versions

To version all packages in this repo that have been changed since the previous
release, just call `melos version`.

`melos` uses [Conventional
Commits](https://www.conventionalcommits.org/en/v1.0.0/) to determine which
semver components to increment. Handy!

It will automatically update each package's `pubspec.yaml` and `CHANGELOG.md`
files, create a new commit, and tag that commit with one or more version tags
(eg. `nhost_sdk-v1.3.5`).

If you want to update to pre-release versions instead, use `melos version
--prerelease`.

### Publishing

If you're unfamiliar with publishing Dart packages, you should read
the [Publishing Packages](https://dart.dev/tools/pub/publishing) guide before
you get started.

Publishing is done in two parts — a dry run, then the real deal. Here's how
it looks:

```sh
# Dry run by default. This will run a basic lint, and give you some feedback
# so you can gut check.
melos publish

# Publishes to pub.dev. No turning back.
melos publish --no-dry-run
```
