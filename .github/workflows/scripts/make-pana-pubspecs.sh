#!/usr/bin/env bash

# In order to run pana, we need to establish path dependencies between the
# packages.

set -e

script_dir=`dirname "$BASH_SOURCE"`
repo_dir=`realpath "$script_dir/../../.."`
pana_package_root=/github/workspace

get_packages () {
 ls -1 $repo_dir/packages
}

nl=$'\n'
for target_package in $(get_packages); do
  pushd $repo_dir/packages/$target_package

    for dependency_package in $(get_packages); do
      if [ $target_package == $dependency_package ]; then
        continue;
      fi
      escaped_absolute_dep_path=$(echo "$pana_package_root/packages/$dependency_package" | sed 's/\//\\\//g')
      echo "$dependency_package: rewrite to $escaped_absolute_dep_path"

      if egrep "$dependency_package" pubspec.yaml; then
        cat pubspec.yaml | \
          sed "s/$dependency_package:.*/$dependency_package:\\${nl}    path: $escaped_absolute_dep_path/" > pubspec.new

        mv pubspec.new pubspec.yaml
      fi
    done
  popd
done
