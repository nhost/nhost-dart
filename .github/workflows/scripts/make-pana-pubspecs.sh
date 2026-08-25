#!/usr/bin/env bash

# In order to run pana with local package changes, we need to establish path
# dependencies between the packages.
#
# These have to replace the version constraints in `dependencies` rather than go
# into `dependency_overrides`. pana drops the overrides before it runs
# `dart pub outdated`, so a constraint on a sibling version that is not on
# pub.dev yet fails version solving. That is exactly what a release commit looks
# like, since it bumps every sibling constraint to a version that is only
# published after the commit lands.

set -e

script_dir=`dirname "$BASH_SOURCE"`
repo_dir=`realpath "$script_dir/../../.."`
pana_package_root=/github/workspace

get_packages () {
  ls -1 $repo_dir/packages
}

for target_package in $(get_packages); do
  # Skip directories that aren't packages yet, e.g. one holding only generated
  # example output.
  if [ ! -f "$repo_dir/packages/$target_package/pubspec.yaml" ]; then
    continue
  fi

  pushd $repo_dir/packages/$target_package > /dev/null

    for dependency_package in $(get_packages); do
      if [ "$target_package" == "$dependency_package" ]; then
        continue
      fi

      # Check if this package depends on the dependency_package (in dependencies or dev_dependencies)
      if grep -qE "^  $dependency_package:" pubspec.yaml; then
        echo "$target_package: rewriting $dependency_package to a path dependency"
        awk -v dep="$dependency_package" \
            -v path="$pana_package_root/packages/$dependency_package" '
          $0 ~ "^  " dep ":" {
            print "  " dep ":"
            print "    path: " path
            next
          }
          { print }
        ' pubspec.yaml > pubspec.new
        mv pubspec.new pubspec.yaml
      fi
    done

  popd > /dev/null
done
