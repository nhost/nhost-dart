#!/usr/bin/env bash
# Offline tests for release-notes.sh against a fixture changelog.
#
# Usage: release-notes.test.sh

set -u

script="$(dirname "$0")/release-notes.sh"
dir="$(mktemp -d)"
trap 'rm -rf "$dir"' EXIT

cat >"$dir/CHANGELOG.md" <<'EOF'
## 3.0.2

## 3.0.1

Fix the wrong bump from 3.0.0.

## 3.0.0

> Note: This release has breaking changes.

 - **FIX**: use pub add in the READMEs (#203).
 - **FEAT**(storage): added replaceFile method (#172).
 - **BREAKING** **FEAT**: increase flutter sdk constraint.
 - **CHORE**: bump lints.
 - **CI**: cache flutter.
 - **BUILD**: tweak something.
 - Update a dependency to the latest release.

## 2.0.0

 - **FIX**: older fix.
 - Add an overload for constructing a client using an Auth object, and not a full
   client.
EOF

failed=0

check() {
  local name=$1 version=$2 want_rc=$3 want=$4
  local got rc
  got="$("$script" "$dir/CHANGELOG.md" "$version" "pkg-v$version" 2026-11-19 2>"$dir/err")"
  rc=$?
  if [ "$rc" -eq "$want_rc" ] && [ "$got" = "$want" ]; then
    echo "ok   $name"
  else
    echo "FAIL $name: exit $rc, expected $want_rc"
    diff <(echo "$want") <(echo "$got")
    cat "$dir/err"
    failed=1
  fi
}

check "groups a version's entries by type" 3.0.0 0 "$(cat <<'EOF'
## [pkg-v3.0.0] - 2026-11-19

### 🚀 Features

- *(storage)* Added replaceFile method (#172)
- ⚠️ **BREAKING** ⚠️ Increase flutter sdk constraint

### 🐛 Bug Fixes

- Use pub add in the READMEs (#203)

### 💼 Other

- Tweak something

### ⚙️ Miscellaneous Tasks

- Bump lints
- Cache flutter
- Update a dependency to the latest release
EOF
)"

check "stops at the next version" 2.0.0 0 "$(cat <<'EOF'
## [pkg-v2.0.0] - 2026-11-19

### 🐛 Bug Fixes

- Older fix

### 💼 Other

- Add an overload for constructing a client using an Auth object, and not a full client
EOF
)"

check "fails on a missing version" 9.9.9 1 ""
check "fails on a version without entries" 3.0.1 1 ""
check "fails on an empty version" 3.0.2 1 ""

exit "$failed"
