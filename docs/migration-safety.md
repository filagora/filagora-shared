# Migration safety

The packages ship database migrations, and a site deploys a package release together with its migrations.
A deploy can be rolled back by making the previous release current again, but **a migration cannot be rolled
back that way**. So a release's migrations must leave the database working for the *previous* release's code,
because that code is what runs again after a rollback (or while the old and new releases overlap during a deploy).

## The rule: expand, then contract

Split every destructive change across two releases.

| Release | Allowed | Not allowed |
| --- | --- | --- |
| **Expand** (release N) | add a table, add a nullable column or one with a default, add an index, backfill data | drop or rename anything, add a `NOT NULL` column with no default, change a column's type or length so existing code breaks |
| **Contract** (release N+1 or later, after N is live and no rollback to N-1 is wanted) | drop the old column or table, add the constraint, remove the fallback | |

A rename is an expand (add the new column, write to both), then a contract (drop the old one).

## Before tagging a release that has a migration

- [ ] The previous release's code runs unchanged against the schema after this migration.
- [ ] No released migration was edited. Add a new one instead; a changed old migration never runs again on a site that has applied it.
- [ ] It is safe on a table with a million rows: no full-table rewrite or long lock on a hot table (`threads`, `posts`, `users`) without a plan.
- [ ] A backfill is idempotent and can be re-run.
- [ ] The changelog entry says what the migration does.

## What the release workflow does

`release.yml` compares the tag with the previous `v*` tag. If anything under `database/migrations/` was added,
changed or renamed, it puts a **Database migrations** section at the top of the GitHub release notes listing the
files, and says so loudly when an already-released migration was modified or renamed. A site's Dependabot pull
request quotes those notes, so the reviewer sees the flag before merging the bump. It does not judge whether a
migration is safe: that is the checklist above, done by a person.

It does not fail the release. Package migrations live in `database/migrations/`; a package that keeps them
elsewhere is not scanned.
