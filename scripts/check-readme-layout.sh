#!/usr/bin/env bash
# Fails unless the README's `##` headings are exactly the common package layout, in order, and
# the `###` headings under "What it provides" are exactly Overview, Tables, Commands, Events,
# Access, Using it.
# The docs site builds each package's page from its README, so every package must read the same.
#
#   README_EXTRA_SECTIONS  newline-separated `##` headings allowed in addition (the package
#                          skeleton's "how to use this template" section)
#   README                 path to check (default README.md)
set -euo pipefail

readme="${README:-README.md}"
expected=(
  "What it provides"
  "Requirements"
  "Install"
  "Configuration"
  "Extending"
  "Testing"
  "Local development (DDEV)"
  "Licence"
)

if [ ! -f "$readme" ]; then
  echo "::error::$readme not found"
  exit 1
fi

extras="${README_EXTRA_SECTIONS:-}"

actual=()
while IFS= read -r heading; do
  if [ -n "$extras" ] && printf '%s\n' "$extras" | grep -qxF -- "$heading"; then
    continue
  fi
  actual+=("$heading")
done < <(awk '/^```/ { fence = !fence; next } !fence && /^## / { sub(/^## +/, ""); sub(/[[:space:]]+$/, ""); print }' "$readme")

provides_expected=(
  "Overview"
  "Tables"
  "Commands"
  "Events"
  "Access"
  "Using it"
)

provides_actual=()
while IFS= read -r heading; do
  provides_actual+=("$heading")
done < <(awk '/^```/ { fence = !fence; next }
  !fence && /^## / { in_provides = ($0 == "## What it provides"); next }
  !fence && in_provides && /^### / { sub(/^### +/, ""); sub(/[[:space:]]+$/, ""); print }' "$readme")

failed=0

if [ "${actual[*]-}" != "${expected[*]}" ]; then
  failed=1
  echo "::error file=$readme::README sections must be, in this order: $(printf '%s, ' "${expected[@]}" | sed 's/, $//')"
  echo "Found:"
  printf '  ## %s\n' "${actual[@]}"
fi

if [ "${provides_actual[*]-}" != "${provides_expected[*]}" ]; then
  failed=1
  echo "::error file=$readme::'What it provides' must have these ### sections, in this order: $(printf '%s, ' "${provides_expected[@]}" | sed 's/, $//')"
  echo "Found:"
  printf '  ### %s\n' "${provides_actual[@]}"
fi

if [ "$failed" -eq 0 ]; then
  echo "README layout ok."
  exit 0
fi

echo "Put anything else under 'Using it' as a #### heading. See filagora-package-skeleton."
exit 1
