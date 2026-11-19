#!/usr/bin/env bash
# Prints the GitHub release notes for one package version: the entries melos
# wrote to the package's CHANGELOG.md for that version, grouped by commit type
# in the layout nhost/nhost's git-cliff releases use.
#
# Usage: release-notes.sh <CHANGELOG.md> <version> <tag> <date>

set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "usage: $0 <CHANGELOG.md> <version> <tag> <date>" >&2
  exit 2
fi

awk -v version="$2" -v tag="$3" -v date="$4" '
  BEGIN {
    n = split("FEAT FIX REFACTOR DOCS PERF STYLE TEST CHORE REVERT OTHER", order, " ")
    title["FEAT"] = "🚀 Features"
    title["FIX"] = "🐛 Bug Fixes"
    title["REFACTOR"] = "🚜 Refactor"
    title["DOCS"] = "📚 Documentation"
    title["PERF"] = "⚡ Performance"
    title["STYLE"] = "🎨 Styling"
    title["TEST"] = "🧪 Testing"
    title["CHORE"] = "⚙️ Miscellaneous Tasks"
    title["REVERT"] = "◀️ Revert"
    title["OTHER"] = "💼 Other"
  }

  $1 == "##" && $2 == version { found = 1; next }
  found && /^## / { exit }
  !found { next }

  /^ *- / {
    line = $0
    sub(/^ *- /, "", line)
    items[++count] = line
    next
  }

  # A wrapped entry continues on the following indented lines.
  count && /^  +[^ -]/ {
    line = $0
    sub(/^ +/, "", line)
    items[count] = items[count] " " line
  }

  function add(line,    breaking, group, scope, entry) {
    # "**BREAKING** **FIX**(scope): message (#123)."
    breaking = sub(/^\*\*BREAKING\*\* /, "", line)

    group = "OTHER"
    scope = ""
    if (match(line, /^\*\*[A-Z]+\*\*/)) {
      group = substr(line, 3, RLENGTH - 4)
      line = substr(line, RLENGTH + 1)
      if (match(line, /^\([^)]*\)/)) {
        scope = substr(line, 2, RLENGTH - 2)
        line = substr(line, RLENGTH + 1)
      }
      sub(/^: */, "", line)
      if (group == "CI") group = "CHORE"
      if (!(group in title)) group = "OTHER"
    } else if (line ~ /^Update a dependency/) {
      group = "CHORE"
    }

    sub(/ +$/, "", line)
    sub(/\.$/, "", line)
    line = toupper(substr(line, 1, 1)) substr(line, 2)

    entry = "- "
    if (scope != "") entry = entry "*(" scope ")* "
    if (breaking) entry = entry "⚠️ **BREAKING** ⚠️ "
    entries[group] = entries[group] entry line "\n"
  }

  END {
    if (!found) {
      print "release-notes.sh: no \"## " version "\" section" > "/dev/stderr"
      exit 1
    }
    if (!count) {
      print "release-notes.sh: no entries in \"## " version "\" section" > "/dev/stderr"
      exit 1
    }
    for (i = 1; i <= count; i++) add(items[i])
    printf "## [%s] - %s\n", tag, date
    for (i = 1; i <= n; i++) {
      g = order[i]
      if (g in entries) printf "\n### %s\n\n%s", title[g], entries[g]
    }
  }
' "$1"
