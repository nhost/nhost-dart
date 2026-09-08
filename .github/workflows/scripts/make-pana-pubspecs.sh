#!/usr/bin/env bash

# pana scores a package by resolving its dependencies from pub.dev. On a release
# commit the sibling constraints already name versions that are only published
# after the commit lands, so the resolution fails and pana exits with an error
# unless we rewrite the pubspecs first.
#
# The declared constraint in `dependencies` is the only lever available.
# `dependency_overrides` (and `pubspec_overrides.yaml`) cannot help: pana deletes
# both from the pubspec before *every* pub invocation. `pub get`, `pub upgrade`,
# `pub downgrade` and `pub outdated` all run inside
# `_withStripAndAugmentPubspecYaml`, which calls
# `parsed.remove('dependency_overrides')` — `lib/src/sdk_env.dart:645` in pana
# 0.23.5, the version baked into `axel-op/dart-package-analyzer@v3`. So the
# `.dart_tool/package_config.json` that `dart analyze` reads never sees a path
# override, however we write it. Do not re-add one; it is inert.
#
# So: rewrite each sibling constraint to the version currently published on
# pub.dev, which both `pub get` and `pub outdated --no-dependency-overrides` can
# solve.
#
# The consequence — and the reason this job is not a local-vs-local check — is
# that pana analyzes each package's *local* source against its *published*
# siblings. Local code targeting a sibling API that is not published yet
# analyzes as warnings, and any warning at all drops "Pass static analysis" from
# 50 to 30 points (`lib/src/report/static_analysis.dart:45-54`). That 20-point
# hole is what the per-package `MAX_PANA_MISSING_POINTS` budgets absorb: e.g.
# `nhost_auth_dart` carries a 40-point budget because local `NhostAuthClient`
# marks 11 members `@override` that the published `HasuraAuthClient` does not
# declare yet. Those budgets are release-window slack, not unexplained laxity.
#
# Local source against local siblings is covered by the separate `test-package`
# job (`melos bootstrap` + `melos analyze`).

set -e

script_dir=$(dirname "$BASH_SOURCE")
repo_dir=$(realpath "$script_dir/../../..")

get_packages() {
	ls -1 $repo_dir/packages
}

# Memo cache for `published_version`. Requires bash 4+, which the `ubuntu-latest`
# runner has.
declare -A published_version_cache

response_body=$(mktemp)
trap 'rm -f "$response_body"' EXIT

# Sets `published_version_result` to the latest version of a package on pub.dev,
# or to the empty string if the package has never been published. Only a
# definitive 404 counts as "never published"; every other failure (transport
# error, timeout after retries, 5xx, unparseable body, missing python3) exits
# non-zero rather than silently degrading the declared constraint.
#
# The result is returned in a global rather than on stdout so the memo cache
# survives the call: `latest=$(published_version ...)` would run the function in
# a subshell and throw the cache away with it.
published_version() {
	local package=$1
	if [ -n "${published_version_cache[$package]+set}" ]; then
		published_version_result=${published_version_cache[$package]}
		return
	fi

	local status version
	# The body is written to a file instead of being captured next to the `-w`
	# output, because with `--retry` curl appends the body of every failed attempt
	# to stdout: a recovered 503-then-200 would hand us two error pages glued in
	# front of the JSON. `-o` is truncated per attempt, so only the final body
	# survives and the retry actually helps.
	#
	# `--retry-all-errors` extends retries past curl's default retryable set to
	# cover connection resets. A 404 is not an error to curl (we do not pass
	# `--fail`), so it is answered immediately rather than retried.
	if ! status=$(curl -s --connect-timeout 10 --max-time 30 \
		--retry 3 --retry-delay 2 --retry-all-errors \
		-o "$response_body" -w '%{http_code}' \
		"https://pub.dev/api/packages/$package"); then
		echo "could not reach pub.dev for $package" >&2
		exit 1
	fi

	case "$status" in
	200)
		# `version` is declared by `local` above and assigned here on purpose.
		# Writing `local version=$(...)` would yield `local`'s exit status instead
		# of the command substitution's, hiding a failing python3 from `set -e`.
		version=$(python3 -c 'import sys, json; print(json.load(sys.stdin)["latest"]["version"])' \
			<"$response_body")
		;;
	404) version="" ;;
	*)
		echo "pub.dev returned $status for $package" >&2
		exit 1
		;;
	esac

	published_version_cache[$package]=$version
	published_version_result=$version
}

for target_package in $(get_packages); do
	# Skip directories that aren't packages yet, e.g. one holding only generated
	# example output.
	if [ ! -f "$repo_dir/packages/$target_package/pubspec.yaml" ]; then
		continue
	fi

	pushd $repo_dir/packages/$target_package >/dev/null

	for dependency_package in $(get_packages); do
		if [ "$target_package" == "$dependency_package" ]; then
			continue
		fi

		# Check if this package depends on the dependency_package (in dependencies or dev_dependencies)
		if grep -qE "^  $dependency_package:" pubspec.yaml; then
			published_version "$dependency_package"
			latest=$published_version_result
			if [ -z "$latest" ]; then
				# A wider constraint would not rescue this: `any` still makes pub ask
				# pub.dev for the version list, which 404s just the same. The only
				# thing that could work is a source pub can resolve without pub.dev,
				# and per the header comment pana strips path overrides.
				echo "$target_package depends on $dependency_package, which has never been published to pub.dev; pana cannot solve that constraint" >&2
				exit 1
			fi
			constraint="^$latest"

			echo "$target_package: $dependency_package -> $constraint"

			awk -v dep="$dependency_package" -v constraint="$constraint" '
          $0 ~ "^  " dep ":" { print "  " dep ": " constraint; next }
          { print }
        ' pubspec.yaml >pubspec.new
			mv pubspec.new pubspec.yaml
		fi
	done

	popd >/dev/null
done
