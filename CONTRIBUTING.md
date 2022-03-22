# Contributing to this repository
## Getting started

This repository contains multiple Dart/Flutter packages, which can be found
in the [`packages` directory](https://github.com/nhost/nhost-dart/tree/main/packages).

We [`melos`](https://pub.dev/packages/melos) to make building multiple packages
easier.

After cloning the repo, run this from the repo's root directory to get
everything set up:

```sh
dart pub get
dart run melos bootstrap
```

### Commit message conventions

We use [**Conventional Commits**](https://www.conventionalcommits.org/) format
for our commit messages, and this is validated on PRs via a GitHub action.

Why? Because it's machine readable, and we can automate some stuff around it
(using [`melos`](https://pub.dev/packages/melos)).

### VSCode snippet

We've included a [VSCode
snippet](https://github.com/nhost/nhost-dart/blob/main/.vscode/conventional-commits.code-snippets) with the repository that will help with the formatting.

Just write `ccommit` <kbd>Tab</kbd> in your commit message, and the snippet
will expand.

## Running tests

Tests are automatically run by GitHub on every commit, but if you want to
run them locally, run `dart run melos run test`.

## Publishing
### Updating package versions

To version all packages in this repo that have been changed since the previous
release, just call `dart run melos version`.

`melos` uses [Conventional
Commits](https://www.conventionalcommits.org/en/v1.0.0/) to determine which
semver components to increment. Handy!

It will automatically update each package's `pubspec.yaml` and `CHANGELOG.md`
files, create a new commit, and tag that commit with one or more version tags
(eg. `nhost_sdk-v1.3.5`).

If you want to update to pre-release versions instead, use
`dart run melos version --prerelease`.

### Publishing

If you're unfamiliar with publishing Dart packages, you should read
the [Publishing Packages](https://dart.dev/tools/pub/publishing) guide before
you get started.

Publishing is done in two parts — a dry run, then the real deal. Here's how
it looks:

```sh
# Dry run by default. This will run a basic lint, and give you some feedback
# so you can gut check.
dart run melos publish

# Publishes to pub.dev. No turning back.
dart run melos publish --no-dry-run
```
