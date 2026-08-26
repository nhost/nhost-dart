#!/usr/bin/env bash

# In order to run pana against local package changes, we need to point the
# sibling dependencies at this checkout. That has to be done on two fronts,
# because pana looks at the pubspec in two different ways:
#
#   * `dependency_overrides` is what makes static analysis resolve against the
#     local sibling. It cannot be the only thing we do, because pana runs
#     `dart pub outdated ... --no-dependency-overrides`, which ignores it and
#     solves the declared constraint against pub.dev. On a release commit that
#     constraint names a version that is only published after the commit lands,
#     so solving fails and pana exits with an error.
#
#   * The declared constraint in `dependencies` is what that solve sees, so it
#     has to name something that already exists on pub.dev. We rewrite it to the
#     currently published version. A `path` dependency would also solve, but
#     costs 20 points under "Publishable packages can't have 'path'
#     dependencies", which drops the score below the gate.
#
# So: declared constraint stays resolvable and version-shaped, and the override
# carries the local code.

set -e

script_dir=`dirname "$BASH_SOURCE"`
repo_dir=`realpath "$script_dir/../../.."`
pana_package_root=/github/workspace

get_packages () {
  ls -1 $repo_dir/packages
}

# Latest version of a package on pub.dev, empty if it has never been published.
# Only a definitive 404 counts as "never published" (the caller then falls back
# to "any"). Any other failure (transport error, 5xx, missing python3) fails loud
# rather than silently degrading the declared constraint to "any".
published_version () {
  local body status
  if ! body=$(curl -s -w '\n%{http_code}' "https://pub.dev/api/packages/$1"); then
    echo "could not reach pub.dev for $1" >&2
    exit 1
  fi
  status=${body##*$'\n'}
  body=${body%$'\n'*}
  case "$status" in
    200)
      printf '%s' "$body" \
        | python3 -c 'import sys, json; print(json.load(sys.stdin)["latest"]["version"])'
      ;;
    404) ;;
    *)
      echo "pub.dev returned $status for $1" >&2
      exit 1
      ;;
  esac
}

for target_package in $(get_packages); do
  # Skip directories that aren't packages yet, e.g. one holding only generated
  # example output.
  if [ ! -f "$repo_dir/packages/$target_package/pubspec.yaml" ]; then
    continue
  fi

  pushd $repo_dir/packages/$target_package > /dev/null

    overrides=""
    for dependency_package in $(get_packages); do
      if [ "$target_package" == "$dependency_package" ]; then
        continue
      fi

      # Check if this package depends on the dependency_package (in dependencies or dev_dependencies)
      if grep -qE "^  $dependency_package:" pubspec.yaml; then
        latest=$(published_version "$dependency_package")
        if [ -n "$latest" ]; then
          constraint="^$latest"
        else
          # Never published, so there is nothing for pub to solve against.
          constraint="any"
        fi

        echo "$target_package: $dependency_package -> $constraint (overridden to local path)"

        awk -v dep="$dependency_package" -v constraint="$constraint" '
          $0 ~ "^  " dep ":" { print "  " dep ": " constraint; next }
          { print }
        ' pubspec.yaml > pubspec.new
        mv pubspec.new pubspec.yaml

        overrides="${overrides}  ${dependency_package}:
    path: ${pana_package_root}/packages/${dependency_package}
"
      fi
    done

    if [ -n "$overrides" ]; then
      echo "" >> pubspec.yaml
      echo "dependency_overrides:" >> pubspec.yaml
      printf "%s" "$overrides" >> pubspec.yaml
    fi

  popd > /dev/null
done
