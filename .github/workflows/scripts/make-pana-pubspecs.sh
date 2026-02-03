#!/usr/bin/env bash

# In order to run pana with local package changes, we need to establish path
# dependencies between the packages. We use dependency_overrides instead of
# modifying dependencies directly to avoid pana warnings about path dependencies.

set -e

script_dir=`dirname "$BASH_SOURCE"`
repo_dir=`realpath "$script_dir/../../.."`
pana_package_root=/github/workspace

get_packages () {
  ls -1 $repo_dir/packages
}

for target_package in $(get_packages); do
  pushd $repo_dir/packages/$target_package > /dev/null

    # Build dependency_overrides section
    overrides=""
    for dependency_package in $(get_packages); do
      if [ "$target_package" == "$dependency_package" ]; then
        continue
      fi

      # Check if this package depends on the dependency_package (in dependencies or dev_dependencies)
      if grep -qE "^  $dependency_package:" pubspec.yaml; then
        echo "$target_package: adding override for $dependency_package"
        overrides="${overrides}  ${dependency_package}:
    path: ${pana_package_root}/packages/${dependency_package}
"
      fi
    done

    # Append dependency_overrides to pubspec.yaml if we have any
    if [ -n "$overrides" ]; then
      echo "" >> pubspec.yaml
      echo "dependency_overrides:" >> pubspec.yaml
      printf "%s" "$overrides" >> pubspec.yaml
    fi

  popd > /dev/null
done
