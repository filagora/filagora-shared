# Filagora shared workflows

Reusable GitHub Actions workflows (and the scripts they use) for the Filagora packages.
Each package's `ci.yml` calls these, so a fix here reaches every repository.

| Workflow | What it does |
| --- | --- |
| `tests.yml` | Installs the package into a Testbench app and runs Pest on a real MariaDB service. Inputs: `php-version`, `laravel`, `testbench`, `prefer`, `mariadb-version`, `meilisearch-version` (optional; starts Meilisearch on port 7700 with key `testing-master-key`, exported as `MEILISEARCH_HOST` and `MEILISEARCH_KEY`) |
| `lint.yml` | The README layout check (see below), `composer validate --strict`, Pint (check only), Larastan, `composer audit` |
| `leak-scan.yml` | Scans tracked files for private details (patterns from the `LEAK_PATTERNS` secret, any IPv4 literal, any email address not on the allow-list) and runs gitleaks |
| `release.yml` | On a tag, creates a GitHub release from the matching `CHANGELOG.md` section, with a **Database migrations** section on top when the release adds or changes migrations (see [docs/migration-safety.md](docs/migration-safety.md)) |
| `actionlint.yml` | Lints the workflows in this repository on every push and pull request |

## Using them

```yaml
jobs:
  tests:
    uses: filagora/filagora-shared/.github/workflows/tests.yml@master
  lint:
    uses: filagora/filagora-shared/.github/workflows/lint.yml@master
  leak-scan:
    uses: filagora/filagora-shared/.github/workflows/leak-scan.yml@master
    secrets: inherit
```

`leak-scan.yml` fetches `scripts/leak-scan.sh` from this repository at run time. Email
addresses on the domains reserved for documentation and testing (RFC 2606, for example
`example.com` or `*.test`) are ignored, because they cannot belong to anyone.

## README layout

The docs site builds each package's page from its `README.md`, so `lint.yml` fails unless the
README's `##` headings are exactly: What it provides, Requirements, Install, Configuration,
Extending, Testing, Local development (DDEV), Licence. Anything else goes under *What it
provides* as a `###` heading. `scripts/check-readme-layout.sh` does the check; the package
skeleton's README shows the layout.

## Migrations

A code rollback cannot undo a migration, so release migrations follow expand-then-contract: see
[docs/migration-safety.md](docs/migration-safety.md).

## Changing a workflow

`master` is protected: open a pull request and wait for `actionlint`. Callers use
`@master`, so a merged change takes effect everywhere at once.

## Licence

MIT. See [LICENSE](LICENSE).
