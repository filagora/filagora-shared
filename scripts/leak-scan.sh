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

# 2. Any IPv4 literal, except loopback, unspecified and the documentation ranges reserved by
#    RFC 5737 (which cannot belong to anyone), and except numbers that only look like addresses:
#    those inside an SVG path's `d="..."` data and a four-part version after a slash, as in the
#    user-agent string `Chrome/127.0.0.0`.
ipv4='\b((25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])\b'
while IFS= read -r f; do
  [ -f "$f" ] || continue
  hits=$(sed -E 's/ d="[^"]*"//g; s#/[0-9]+(\.[0-9]+){3}##g' -- "$f" | grep -nIEo "$ipv4" | grep -Ev ':(127\.0\.0\.1|0\.0\.0\.0|192\.0\.2\.[0-9]+|198\.51\.100\.[0-9]+|203\.0\.113\.[0-9]+)$' | cut -d: -f1 | paste -sd, -)
  [ -n "$hits" ] && report "IPv4 literal in $f (line(s) $hits)"
done <<< "$files"

# 3. Email addresses not on the allow-list. Addresses on domains reserved for
#    documentation and testing (RFC 2606) cannot belong to anyone, so they are fine.
reserved='@([A-Za-z0-9-]+\.)*(example\.(com|org|net)|[A-Za-z0-9-]+\.test|test|example|invalid|localhost)$'
printf '%s\n' "${ALLOWED_EMAILS:-}" | sed '/^[[:space:]]*$/d' > /tmp/allowed-emails.txt
email='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
while IFS= read -r f; do
  [ -f "$f" ] || continue
  hits=$(grep -nIEo "$email" -- "$f" | while IFS=: read -r line addr; do
    # A "+" or "." before the address is punctuation around it (`+claudebot@example.com`), not part of it.
    addr=${addr#"${addr%%[![:punct:]]*}"}
    grep -qixF -- "$addr" /tmp/allowed-emails.txt && continue
    printf '%s' "$addr" | grep -qiE "$reserved" && continue
    echo "$line"
  done | paste -sd, -)
  [ -n "$hits" ] && report "Non-allow-listed email in $f (line(s) $hits)"
done <<< "$files"

if [ "$status" -eq 0 ]; then
  echo "Leak scan clean."
fi
exit "$status"
