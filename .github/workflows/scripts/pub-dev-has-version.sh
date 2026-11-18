#!/usr/bin/env bash
# Usage: pub-dev-has-version.sh <package> <version>
#
# Exits 0 if <version> of <package> is on pub.dev, 1 if it is not (including
# when the package has never been published), and 2 if pub.dev could not be
# asked.

set -euo pipefail

name="$1"
version="$2"

body="$(mktemp)"
trap 'rm -f "$body"' EXIT

code="$(curl -sS --retry 3 -o "$body" -w '%{http_code}' \
  -H 'Accept: application/vnd.pub.v2+json' \
  "https://pub.dev/api/packages/$name")" || exit 2

case "$code" in
  200) ;;
  404) exit 1 ;;
  *)
    echo "pub.dev answered HTTP $code for $name" >&2
    exit 2
    ;;
esac

# jq -e exits 1 when the expression is false, and 2 or more if it cannot parse
# the response, which lines up with the exit codes above.
jq -e --arg version "$version" \
  'any(.versions[]; .version == $version)' "$body" >/dev/null
