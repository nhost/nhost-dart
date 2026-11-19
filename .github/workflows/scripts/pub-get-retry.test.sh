#!/usr/bin/env bash
# Offline tests for pub-get-retry.sh, with a fake `pub get` that fails a set
# number of times before it succeeds.
#
# Usage: pub-get-retry.test.sh

set -u

script="$(dirname "$0")/pub-get-retry.sh"
dir="$(mktemp -d)"
trap 'rm -rf "$dir"' EXIT

cat >"$dir/fake" <<'FAKE'
#!/usr/bin/env bash
n="$(cat "$FAKE_DIR/count" 2>/dev/null || echo 0)"
echo $((n + 1)) >"$FAKE_DIR/count"
if [ "$n" -lt "$FAKE_FAILS" ]; then
  echo "$FAKE_MESSAGE"
  exit 1
fi
echo "Got dependencies!"
FAKE
chmod +x "$dir/fake"

lag="Because nhost_dart depends on nhost_auth_dart ^2.8.0 which doesn't match any versions, version solving failed."
other="Because nhost_dart depends on http ^99.0.0 which doesn't match any versions, version solving failed."
network="Got socket error trying to find package nhost_sdk at https://pub.dev."

failed=0

# check <name> <fake failures> <fake message> <minutes> <expected exit> <expected calls>
check() {
  rm -f "$dir/count"
  FAKE_DIR="$dir" FAKE_FAILS="$2" FAKE_MESSAGE="$3" PUB_GET="$dir/fake" \
    PUB_GET_INTERVAL=0 "$script" "$4" nhost_sdk nhost_auth_dart nhost_dart \
    >"$dir/log" 2>&1
  rc=$?
  calls="$(cat "$dir/count")"
  if [ "$rc" = "$5" ] && [ "$calls" = "$6" ]; then
    echo "ok   $1"
  else
    echo "FAIL $1: exit $rc after $calls calls, expected exit $5 after $6"
    cat "$dir/log"
    failed=1
  fi
}

check "passes on the first try" 0 "$lag" 1 0 1
check "retries a lagging sibling, then passes" 3 "$lag" 1 0 4
check "gives up on a sibling after the budget" 1000 "$lag" 0 1 1
check "fails at once on a non-sibling" 1 "$other" 1 1 1
check "fails at once on any other error" 1 "$network" 1 1 1

exit "$failed"
