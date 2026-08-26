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

Then a release is: push the release commit, then push the per-package tags that
`melos version` created one at a time.

```
git push origin main
```

Do not push the tags with `git push --follow-tags` or `git push --tags`. GitHub
does not create a workflow run for every tag when more than three tags arrive in
a single push (see GitHub's "Events that trigger workflows" docs). A release here
tags nearly every package, well more than three, so a single multi-tag push would
start a publish run for at most three of them and silently skip the rest: the
tags exist, pub.dev is stale, and CI stays green because the runs were never
created. Push each tag on its own so every tag gets exactly one run.

Dependency ordering matters. A package cannot publish until the sibling versions
it depends on already exist on pub.dev (for example `nhost_dart 2.3.0` needs
`nhost_sdk 6.0.0` published first). Push one tier, wait for its runs to finish
and the new versions to appear on pub.dev, then push the next tier. All the
release tags point at the release commit, so `git tag --points-at HEAD` lists
them and each `git push` below sends a single tag:

```
# Tier 1
git push origin "$(git tag --points-at HEAD | grep '^nhost_sdk-v')"

# Tier 2 (after tier 1 is on pub.dev)
for pkg in nhost_gql_links nhost_functions_dart nhost_storage_dart; do
  git push origin "$(git tag --points-at HEAD | grep "^${pkg}-v")"
done

# Tier 3 (after tier 2 is on pub.dev)
for pkg in nhost_graphql_adapter nhost_auth_dart; do
  git push origin "$(git tag --points-at HEAD | grep "^${pkg}-v")"
done

# Tier 4 (after tier 3 is on pub.dev)
for pkg in nhost_dart nhost_flutter_auth nhost_flutter_graphql; do
  git push origin "$(git tag --points-at HEAD | grep "^${pkg}-v")"
done
```

Each loop runs one `git push` per package, so no push ever carries more than one
tag and every tag gets its own run. If a package's run fails because a dependency
was not published yet, wait for the dependency, then re-run that failed run from
the GitHub Actions UI; the tag already exists, so there is a run to re-run.
Pushing the same tag again is a no-op and will not start a new run.

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

`publish:real` runs `pub publish --force` per package with `--order-dependents`,
so melos publishes each package after the siblings it depends on. It runs the
pure-Dart packages first and the Flutter packages second, and no pure-Dart
package depends on a Flutter one, so the ordering caveat above is handled for
you.

After a manual publish, make sure the tags exist on the remote so history and
pub.dev agree:

```
git push --tags
```
