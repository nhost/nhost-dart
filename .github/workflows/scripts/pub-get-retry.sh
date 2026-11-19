#!/usr/bin/env bash
# Usage: pub-get-retry.sh <minutes> <sibling>...
#
# Runs `flutter pub get` in the current directory. pub.dev caches the version
# listing that pub reads (dart-lang/pub-dev#8909), so for a few minutes after
# a sibling is published, resolving can still fail with "depends on <sibling>
# <constraint> which doesn't match any versions". This retries every 30
# seconds while the failure names one of <sibling>, for up to <minutes>, and
# fails at once on any other error.
#
# PUB_GET and PUB_GET_INTERVAL override the command and the interval, for
# tests.

set -uo pipefail

minutes="$1"
shift
siblings=" $* "
interval="${PUB_GET_INTERVAL:-30}"
deadline=$((SECONDS + minutes * 60))

out="$(mktemp)"
trap 'rm -f "$out"' EXIT

while true; do
  if ${PUB_GET:-flutter pub get} >"$out" 2>&1; then
    cat "$out"
    exit 0
  fi
  cat "$out"

  dep="$(sed -nE "s/.*depends on ([a-z0-9_]+) [^,]* which doesn't match any versions.*/\1/p" "$out" | head -n 1)"
  if [ -z "$dep" ] || [[ "$siblings" != *" $dep "* ]]; then
    exit 1
  fi
  if [ "$SECONDS" -ge "$deadline" ]; then
    echo "Gave up after $minutes minutes: pub.dev still lists no matching $dep version" >&2
    exit 1
  fi
  echo "pub.dev does not list the $dep version yet; retrying in ${interval}s"
  sleep "$interval"
done
