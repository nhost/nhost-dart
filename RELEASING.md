# Releasing

This repo is a [melos](https://melos.invertase.dev) monorepo. Each directory under
`packages/` is published to [pub.dev](https://pub.dev/publishers/nhost.io/packages)
as its own package under the `nhost.io` verified publisher.

Releases are automated with the same chain of workflows as `nhost/nhost`. Merging
to `main` keeps a release PR up to date, and merging the release PR publishes the
packages it bumps.

## How a release happens

1. Release PR. On every merge to `main`, except merges of the release PR itself,
   `ci_update_changelog.yaml` runs `melos version --yes --no-git-commit-version`.
   That bumps every package with versionable commits since its last
   `<package>-v<version>` tag, bumps the packages that depend on it, and writes
   the package changelogs and the root `CHANGELOG.md`. The workflow then opens or
   updates the `release(packages): <date>` PR from the `release/packages` branch.
   The branch is regenerated from `main` on every run, so edits pushed to it do
   not last; fix the commit messages or the code on `main` instead.

2. Releases. Merging the release PR runs `ci_create_release.yaml`. For each
   package whose version is not on pub.dev yet, it creates a GitHub release
   tagged `<package>-v<version>` on the merge commit, with that version's
   changelog section as the notes. The tags are what the next `melos version` run
   counts commits from.

3. Publish. `ci_release.yaml` runs for every published release and dispatches
   `wf_release_pub.yaml` on the release's tag. pub.dev rejects publishing from
   `release` events, but accepts a `workflow_dispatch` on a tag.

4. `wf_release_pub.yaml` publishes the package named by the tag. It first waits,
   for up to an hour, until the sibling versions the package depends on are on
   pub.dev, so all releases can be created at once and the packages still
   publish in dependency order. It then checks the tag against `pubspec.yaml`,
   validates the package with a dry run that resolves siblings from pub.dev,
   publishes over OIDC (no tokens), and posts the result to Discord.

Which commits bump a version is up to melos (6.x): `feat` is a minor bump;
`fix`, `bug`, `perf`, `refactor`, `revert` and `docs` are a patch bump; any
breaking change (`!` or a `BREAKING CHANGE:` footer) is a major bump. Other
types, such as `chore`, `ci` and `test`, release nothing.

## When something fails

Nothing retries on its own. A failed publish posts to Discord, and every package
that depends on it gives up waiting after an hour and posts too.

A re-run uses the tagged commit, including its copy of `wf_release_pub.yaml`. If
the cause is outside the repo, such as the pub.dev setup, the `pub.dev`
environment, or a pub.dev or network error, fix it, re-run the failed
`Publish <package>-v<version> to pub.dev` run from the Actions tab, then re-run
the dependents that gave up.

If the cause is in the tagged commit, such as the package failing the Validate
step or a bug in `wf_release_pub.yaml`, every re-run fails the same way. Land
the fix on `main` in a `fix` commit that changes the package's directory, since
melos ignores commits that do not, and merge the next release PR. It releases a
new version of the package and of every package that depends on it. The failed
versions are never published and need no further runs. Do not move or recreate
their tags.

Every workflow in the chain is safe to re-run:

- `ci_update_changelog.yaml` regenerates the release branch from `main`.
- `ci_create_release.yaml` skips packages that already have a release or are
  already on pub.dev.
- `wf_release_pub.yaml` treats a version that is already on pub.dev as success.

If a PR is merged in the seconds between a release PR merging and
`ci_create_release.yaml` creating its tags, melos does not find the new tags and
the release PR it produces bumps the just-released packages again. Re-run that
`ci_update_changelog.yaml` run once the releases exist.

## Publishing a single package by hand

If `ci_create_release.yaml` failed, re-run it instead. It tags the release PR's
merge commit and skips the packages that are already released.

Otherwise, create a release from the Releases page, the same way as on
`nhost/nhost`. Tag it `<package>-v<version>` with the version in that package's
`pubspec.yaml` on `main`, and target the merge commit of the release PR that set
that version, as `ci_create_release.yaml` does, not `main`. Package commits
merged since then would be published under that version without a changelog
entry, and melos would never count them for a later release.
`ci_release.yaml` then publishes it like any other release.

To publish a release whose tag already exists, run the "Publish to pub.dev"
workflow from the Actions tab and pick the tag as its ref.

## One-time setup

- The nhost-bot GitHub App needs access to `nhost/nhost-dart`.
  `ci_update_changelog.yaml` and `ci_create_release.yaml` act through its token,
  because pushes and releases made with the default `GITHUB_TOKEN` do not trigger
  other workflows.
- On pub.dev, for each package: Admin -> Automated publishing -> Enable
  publishing from GitHub Actions, with repository `nhost/nhost-dart`, tag pattern
  `<package>-v{{version}}` (e.g. `nhost_sdk-v{{version}}`), environment
  `pub.dev`, `workflow_dispatch` events enabled and `push` events disabled.
  Until a package has this, its publish run fails at the Publish step.
- In this repo's settings, create the `pub.dev` environment and limit its
  deployments to `*-v*` tags.
