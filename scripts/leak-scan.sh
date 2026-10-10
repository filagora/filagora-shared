#!/usr/bin/env bash
# Scans tracked files for private details. Inputs (env):
#   LEAK_PATTERNS  newline-separated extended regexes (secret; may be empty on forks)
#   ALLOWED_EMAILS newline-separated addresses that are fine to publish
set -uo pipefail

status=0
files=$(git ls-files -z | tr '\0' '\n' | grep -Ev '(^|/)(composer\.lock|package-lock\.json)$' || true)

report() {
  echo "::error::$1"
  status=1
}

# 1. Custom patterns. Matches are reported by file and line only, never echoed,
#    so the CI log does not reveal what the pattern list is hiding.
if [ -n "${LEAK_PATTERNS:-}" ]; then
  printf '%s\n' "$LEAK_PATTERNS" | sed '/^[[:space:]]*$/d' > /tmp/leak-patterns.txt
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    if hits=$(grep -nIEif /tmp/leak-patterns.txt -- "$f" | cut -d: -f1 | paste -sd, -); [ -n "$hits" ]; then
      report "Forbidden pattern in $f (line(s) $hits)"
    fi
  done <<< "$files"
else
  echo "::warning::LEAK_PATTERNS is not available (fork or unset); custom pattern scan skipped."
fi

# 2. Any IPv4 literal, except loopback and unspecified addresses.
ipv4='\b((25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])\b'
while IFS= read -r f; do
  [ -f "$f" ] || continue
  hits=$(grep -nIEo "$ipv4" -- "$f" | grep -Ev ':(127\.0\.0\.1|0\.0\.0\.0)$' | cut -d: -f1 | paste -sd, -)
  [ -n "$hits" ] && report "IPv4 literal in $f (line(s) $hits)"
done <<< "$files"

# 3. Email addresses not on the allow-list.
printf '%s\n' "${ALLOWED_EMAILS:-}" | sed '/^[[:space:]]*$/d' > /tmp/allowed-emails.txt
email='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
while IFS= read -r f; do
  [ -f "$f" ] || continue
  hits=$(grep -nIEo "$email" -- "$f" | while IFS=: read -r line addr; do
    grep -qixF -- "$addr" /tmp/allowed-emails.txt || echo "$line"
  done | paste -sd, -)
  [ -n "$hits" ] && report "Non-allow-listed email in $f (line(s) $hits)"
done <<< "$files"

if [ "$status" -eq 0 ]; then
  echo "Leak scan clean."
fi
exit "$status"
