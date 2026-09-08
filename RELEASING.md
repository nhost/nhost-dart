# Releasing

This repo is a [melos](https://melos.invertase.dev) monorepo. Each directory under
`packages/` is published to [pub.dev](https://pub.dev/publishers/nhost.io/packages)
as its own package under the `nhost.io` verified publisher.

A release has three phases:

1. Version and changelog: bump the changed packages and write their changelogs.
2. Land and tag: get the release commit onto `main`, then put one tag per bumped
   package on the commit that actually landed.
3. Publish: push the built packages to pub.dev.

Phase 1 is scripted through melos. Phase 2 is manual bookkeeping, and it is load
bearing: the tags it produces are the only trigger for automated publishing.
Phase 3 is currently manual, and the goal is to move it to tag-triggered CI (see
"Automated publishing" below).

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
rewrites each sibling constraint to its currently published version, so the job
can resolve even though the bumped versions are not on pub.dev yet. pana therefore
scores each package's local source against its *published* siblings; where the two
have diverged during a release window that shows up as static-analysis warnings,
which is what the `MAX_PANA_MISSING_POINTS` budgets in the per-package workflows
absorb. Local-source-against-local-siblings analysis is the `test-package` job's
job (`melos bootstrap` + `melos analyze`), not this one.

If you hand-edit the bump instead of running `melos version`, remember the parts
melos would have done for you: the per-package changelog entries, the dependent
bumps, and the aggregate root `CHANGELOG.md` section. It also skips the tags —
and since the tags are what trigger publishing, a hand-edited release that stops
here looks complete and publishes nothing. Phase 2 covers both paths, so follow
it either way.

## Phase 2: land the release commit and tag it

Phase 3 is driven entirely by tags, and the tags do not survive the merge on
their own. This repo squash-merges — `git log --merges origin/main` is empty and
every commit on `main` carries a `<title> (#N)` subject — and a squash merge
creates a *new* commit. Any tags `melos version` created stay on your pre-merge
tip, which is not an ancestor of `main`; pushing them as-is would hang release
tags off history `main` does not contain. That is also why the tags cannot simply
be pushed from the release branch.

So once the release PR is merged, put the tags on the merged commit:

```bash
git checkout main
git pull

# git tag -f below re-points tags onto whatever is now HEAD, so confirm HEAD is
# the merged release commit — not some later commit git pull brought down —
# before moving anything onto it.
git log -1 --oneline
```

If you ran `melos version`, the tags already exist with the right names on the
pre-merge tip of the release branch — move them:

```bash
# The release branch you just merged; its local tip still carries melos's tags.
release_branch=chore/release-6.0.0

for tag in $(git tag --points-at "$release_branch"); do
  git tag -f "$tag"   # re-point onto the merged commit, which is now HEAD
done
```

If you hand-edited the bump, no tags exist anywhere, so create them — one per
bumped package, and only for packages this release actually bumped:

```bash
git tag -f nhost_sdk-v6.0.0
git tag -f nhost_dart-v2.3.0
# ...one per bumped package
```

The version in the tag must match that package's `pubspec.yaml` version character
for character. `publish.yaml`'s "Verify the package exists and is publishable"
step compares the two and hard-fails before anything is uploaded, so a typo costs
you a red run rather than a bad publish.

Nothing has been pushed yet, so all of the above is safe to redo — `-f` is what
makes it re-runnable. Confirm the set before moving on:

```bash
git tag --points-at HEAD
```

That should list exactly one tag per bumped package, and nothing else. A tag for
an unbumped package means a publish run for a version already on pub.dev, which
fails; a missing tag means that package silently never publishes.

## Phase 3: publish

### Automated publishing (target state)

Once configured, publishing is triggered by pushing the per-package tags that
Phase 2 put on the release commit. `.github/workflows/publish.yaml` picks up a tag
of the form `<package>-v<version>`, resolves the package, checks its pubspec
version against the tag, authenticates to pub.dev over OIDC (no tokens; the
credential is provisioned by `dart-lang/setup-dart`), validates the package with
`flutter pub publish --dry-run`, and only then runs `flutter pub publish
--force`.

One-time setup, per package, by a publisher admin on pub.dev:

- Package admin -> Automated publishing -> Enable publishing from GitHub Actions
- Repository: `nhost/nhost-dart`
- Tag pattern: `<package>-v{{version}}` (e.g. `nhost_sdk-v{{version}}`)
- Environment: `pub.dev`

Until a package is enabled, its tag still starts a run — `publish.yaml` triggers
on `*-v*` — and pub.dev rejects the upload at the end. So a partially enabled
rollout is the expected state, not an edge case.

> **Pending:** the 6.0.0 release commit on this branch was hand-authored and
> carries no tags (`git tag --points-at HEAD` is empty; the newest tag in the repo
> is from 2024-07-19, so the last few releases were never tagged either). Nothing
> can publish until Phase 2 is run for it. Delete this note once those tags exist.

With Phase 2 done — release commit on `main`, tags on `HEAD`, nothing pushed yet
— a release is just pushing those tags, one at a time, in dependency order.

Do not push them with `git push --follow-tags` or `git push --tags`. GitHub does
not create tag push events *at all* when more than three tags arrive in one push:

> Events will not be created if more than 5,000 branches are pushed at once.
> Events will not be created for tags when more than three tags are pushed at
> once.

— ["Events that trigger workflows" → `push`](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#push).
The `create` event carries the same restriction.

It is a cliff, not a cap: at four or more tags you get *zero* runs, not three. A
release here tags nearly every package, so one multi-tag push publishes nothing
while looking like it worked — the tags exist, pub.dev is stale, and CI stays
green because not one run was ever created. If you are debugging a botched
release, do not go hunting for three successful runs and conclude the automation
half-worked; there will be none. Push each tag on its own so every tag gets
exactly one run.

Dependency ordering matters, and it is on you, not CI, to get it right. A package
cannot publish until the sibling versions it depends on already exist on pub.dev
(for example `nhost_dart 2.3.0` needs `nhost_sdk 6.0.0` published first). You
might expect an out-of-order push to fail loudly at the Validate step, but it
does not: every package ships a committed `pubspec_overrides.yaml` (melos-managed
`path: ../sibling` overrides), and `actions/checkout@v4` restores them, so the
Validate step's `flutter pub get` resolves every sibling from the checked-out
tree rather than pub.dev. That step goes green whether or not the sibling version
is published yet, and the package then uploads carrying a pub.dev constraint
(`^6.0.0`) that no published version satisfies — a silent bad release, not the
red run you were counting on. So the tiers below are load bearing: push one tier,
wait for its runs to finish *and* for the new versions to actually appear on
pub.dev, then push the next tier. Do not advance on a green checkmark alone.

The invariant that makes the tiers below reviewable: **no package in a tier may
depend on another package in the same tier.** Packages inside a tier are pushed
back-to-back with no wait, so a same-tier edge is a guaranteed failure rather
than a race. When the dependency graph changes, re-derive the tiers from the
`nhost_*` constraints in each `packages/*/pubspec.yaml` against that rule.

Phase 2 left every release tag on `HEAD`, so `git tag --points-at HEAD` finds
them. Not every release bumps every package, though, so resolve each tag through
a helper that skips cleanly when a package was not bumped — otherwise an unbumped
package degrades to `git push origin ""` (`fatal: invalid refspec ''`), which
scrolls past mid-sequence and reads like the transient run errors below:

```bash
push_tag() {
  local tag
  tag=$(git tag --points-at HEAD | grep "^$1-v" || true)
  if [ -z "$tag" ]; then
    echo "skip: $1 was not bumped in this release"
    return 0
  fi
  echo "pushing $tag"
  git push origin "$tag"
}
```

The `^` and the `-v` are both load bearing: anchoring is why `push_tag nhost_dart`
matches only `nhost_dart-v*` and not `nhost_auth_dart-v*`.

Paste `push_tag` into the shell you are releasing from before running any tier
below. Every tier calls it, so a fresh shell without it defined fails on the
first line.

```bash
# Tier 1
push_tag nhost_sdk

# Tier 2 (after tier 1 is on pub.dev)
for pkg in nhost_gql_links nhost_functions_dart nhost_storage_dart; do
  push_tag "$pkg"
done

# Tier 3 (after tier 2 is on pub.dev)
for pkg in nhost_graphql_adapter nhost_auth_dart; do
  push_tag "$pkg"
done

# Tiers 4-6 are one serial chain and cannot be collapsed into a single tier:
# nhost_flutter_auth -> nhost_dart, and nhost_flutter_graphql -> nhost_flutter_auth.

# Tier 4 (after tier 3 is on pub.dev)
push_tag nhost_dart

# Tier 5 (after tier 4 is on pub.dev)
push_tag nhost_flutter_auth

# Tier 6 (after tier 5 is on pub.dev)
push_tag nhost_flutter_graphql
```

Every `push_tag` runs at most one `git push` carrying exactly one tag, so no push
ever trips the three-tag limit and every tag gets its own run. Do not expect a
run to go red just because a dependency is not on pub.dev yet: the Validate step
resolves siblings locally through the committed overrides (see above), so a
premature push publishes badly rather than failing — waiting for each tier to
land is the only thing standing in for that missing check. If a run does fail for
a genuine transient reason, such as a pub.dev hiccup, re-run it from the GitHub
Actions UI once the cause is cleared; the tag already exists, so there is a run
to re-run. Pushing the same tag again is a no-op and will not start a new run.

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

Publish a given package manually *or* by tag, never both: the manual path uploads
it, and a later tag push would start a run that tries to upload the same version
again.

The tags still belong on the remote so history and pub.dev agree, so after a
manual publish push this release's tags — the same one-tag-per-push rule as
above, for the same reason:

```bash
for tag in $(git tag --points-at HEAD); do
  echo "pushing $tag"
  git push origin "$tag"
done
```

Not `git push --tags`. Beyond the three-tag event cliff, `--tags` pushes *every*
local tag rather than this release's: there are 347 of them here, and some (e.g.
`nhost_sdk-v5.3.1`) are not ancestors of `origin/main`, so it would publish stale
refs that were never meant to leave the machine. Scoping to `--points-at HEAD`
also means the loop simply does nothing if Phase 2 was skipped, instead of
failing on an empty refspec.

For any package whose automated publishing is already enabled on pub.dev, its tag
will start a run that fails at `flutter pub publish --force` with a
version-already-exists error. After a manual publish that failure is expected and
harmless — the version is up; the run is just late.
