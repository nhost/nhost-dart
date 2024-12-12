#/usr/bin/env bash
PREV_MONTH=$(date -v-1m +%Y-%m)

files=$(git log --since="$PREV_MONTH-01" --until="$PREV_MONTH-31" --name-only -- '**/CHANGELOG.md' | grep CHANGE | sort -u)

for file in $files; do
  name=$(basename $(dirname $file))
  last_release=$(grep '^## ' $file | awk '{ print substr($0, 4) }' | head -n 1)
  echo "@$name: $last_release [CHANGELOG.md](https://github.com/nhost/nhost-dart/blob/main/$file)"
done
