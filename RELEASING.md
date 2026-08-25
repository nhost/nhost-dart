# Releasing

This repo is a [melos](https://melos.invertase.dev) monorepo. Each directory under
`packages/` is published to [pub.dev](https://pub.dev/publishers/nhost.io/packages)
as its own package under the `nhost.io` verified publisher.

A release has two phases:

1. Version and changelog: bump the changed packages and write their changelogs.
2. Publish: push the built packages to pub.dev.

Phase 1 is scripted through melos. Phase 2 is currently manual, and the goal is to
move it to tag-triggered CI (see "Automated publishing" below).

## Prerequisites

- The dev shell provides `dart`, `melos`, `flutter327`, and `nhost-cli`. Run
  everything through it: `nix develop -c bash -c "<command>"`, or enter it with
  `nix develop`.
- To publish manually you must be a member of the `nhost.io` publisher on pub.dev
  and be logged in (`dart pub login`). Automated publishing removes this
  requirement for everyone except whoever enables it once per package.

## Phase 1: version and changelog

From `main`, with the feature PRs already merged:

```
nix develop -c bash -c "melos version"
```

This reads conventional-commit history since the last release and, per package:

- bumps the version in `pubspec.yaml` following semver,
- prepends a `CHANGELOG.md` entry,
- bumps dependent packages whose sibling constraints changed,
- updates the aggregate root `CHANGELOG.md`,
- creates a commit `chore(release): Publish packages` and one git tag per bumped
  package (`<package>-v<version>`).

Open a PR for the release commit and let CI go green. The pana score job resolves
sibling packages through `.github/workflows/scripts/make-pana-pubspecs.sh`, which
rewrites each sibling constraint to its currently published version and adds a
local path override, so the job passes even though the bumped versions are not on
pub.dev yet.

If you hand-edit the bump instead of running `melos version`, remember the parts
melos would have done for you: the per-package changelog entries, the dependent
bumps, and the aggregate root `CHANGELOG.md` section.

## Phase 2: publish

### Automated publishing (target state)

Once configured, publishing is triggered by pushing the per-package tags that
`melos version` already creates. `.github/workflows/publish.yaml` picks up a tag
of the form `<package>-v<version>`, resolves the package, and runs
`flutter pub publish --force` for it using pub.dev OIDC (no tokens).

One-time setup, per package, by a publisher admin on pub.dev:

- Package admin -> Automated publishing -> Enable publishing from GitHub Actions
- Repository: `nhost/nhost-dart`
- Tag pattern: `<package>-v{{version}}` (e.g. `nhost_sdk-v{{version}}`)
- Environment: `pub.dev`

Then a release is:

```
git push --follow-tags origin main
```

Dependency ordering matters. A package cannot publish until the sibling versions
it depends on already exist on pub.dev (for example `nhost_dart 2.3.0` needs
`nhost_sdk 5.9.0` published first). Each tag push starts its own workflow run in
parallel, so push base packages first, let them finish, then the dependents; or
push everything and re-run the runs that failed because a dependency was not yet
available. Publish order for this workspace:

1. `nhost_sdk`
2. `nhost_gql_links`, `nhost_functions_dart`, `nhost_storage_dart`
3. `nhost_graphql_adapter`, `nhost_auth_dart`
4. `nhost_dart`, `nhost_flutter_auth`, `nhost_flutter_graphql`

### Manual publish (fallback / today)

Until automated publishing is enabled, publish from the dev shell as a publisher
member. Dry run first:

```
nix develop -c bash -c "melos run publish"
```

That validates every package with `pub publish --dry-run` (Dart and Flutter
packages, examples excluded). When it is clean, publish for real:

```
nix develop -c bash -c "melos run publish:real"
```

`publish:real` runs `pub publish --force` per package. melos publishes in
dependency order, so the ordering caveat above is handled for you.

After a manual publish, make sure the tags exist on the remote so history and
pub.dev agree:

```
git push --tags
```
