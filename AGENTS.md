# AGENTS

Guidance for AI coding agents working in `filagora-shared`. `CLAUDE.md` imports this file; edit here.

## What this is

Reusable GitHub Actions workflows and scripts for every Filagora package (public, MIT). Each package's `ci.yml` calls them with `uses: filagora/filagora-shared/.github/workflows/<name>.yml@master`, so **a merged change takes effect in every repository immediately**.

| File | Purpose |
| --- | --- |
| `.github/workflows/tests.yml` | Testbench app + Pest on a real MariaDB service; optional Meilisearch (port 7700, key `testing-master-key`) |
| `.github/workflows/lint.yml` | `composer validate --strict`, Pint (check only), Larastan, `composer audit` |
| `.github/workflows/leak-scan.yml` | Runs `scripts/leak-scan.sh` (fetched at run time) and gitleaks |
| `.github/workflows/release.yml` | On a tag, creates a GitHub release from the matching `CHANGELOG.md` section |
| `.github/workflows/actionlint.yml` | Lints this repo's workflows |

## Working here

- `master` is protected: branch, open a PR, wait for `actionlint`. Because callers pin `@master`, treat every change as a release to all packages: keep inputs backwards compatible (add optional inputs, do not rename or remove), and say in the PR which package to try it against.
- Run `actionlint` locally if available before pushing.
- Lessons already paid for: the gitleaks GitHub Action needs a paid licence for organisation accounts, so the workflow runs the pinned gitleaks CLI instead; GitHub Actions artifact billing makes upload-heavy steps expensive, so avoid artifacts unless needed.
- The leak scan's private pattern list comes from the `LEAK_PATTERNS` secret and is never echoed to logs. Do not print matches or write the patterns anywhere in this public repo. Reserved test/documentation email domains (RFC 2606) are allowed; any other email address or IPv4 literal (except 127.0.0.1 and 0.0.0.0) fails the scan.
- Never commit secrets. This repository is public.
- Confirm with the user before changing anything that alters billing, secrets or branch protection.
