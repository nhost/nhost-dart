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

## Releasing

Releases are automated. Every merge to `main` updates a release PR with the next
version bumps and changelogs, and merging that PR publishes the bumped packages
to pub.dev. See [RELEASING.md](RELEASING.md) for how it works.

`melos` picks the version bumps from the [Conventional
Commits](https://www.conventionalcommits.org/en/v1.0.0/) since each package's
last release, so your commit messages decide which packages are released and
how far their versions move. Pick the type and any `!` carefully, since a
message cannot be changed once it is merged.

#[TODO]: In case of error eveything under example_Server can be deleted
