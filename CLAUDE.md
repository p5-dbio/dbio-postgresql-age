# CLAUDE.md

## Perl Rules

**MANDATORY: load the `dbio-perl-core` skill before editing any Perl code.** DBIO project conventions.

- **`use Module;`** to load modules. `require` only when you absolutely know why (runtime plugin loading).
- **`->instance`** for singleton classes. `->new` for everything else.
- **Never copy a `$VERSION` from a repo into a cpanfile** — repo is the next unreleased version. Every dependency must be pinned to its latest released CPAN version.

## Workspace Overview

This is a DBIO driver distribution for PostgreSQL with the Apache AGE graph extension.

## Distribution Configuration

Uses `[@DBIO]` plugin bundle from `Dist::Zilla::PluginBundle::DBIO`.

## Testing

Tests use DBIO::Test::Storage (mock storage) for unit tests. Live tests require:
- PostgreSQL with Apache AGE extension
- Set `DBIO_TEST_PG_DSN` / `DBIO_TEST_PG_USER` / `DBIO_TEST_PG_PASS`

```bash
export DBIO_TEST_PG_DSN="dbi:Pg:database=myapp"
export DBIO_TEST_PG_USER=postgres
export DBIO_TEST_PG_PASS=secret
prove -l t/
```

## Deploy

Uses test-deploy-and-compare: introspect live DB, deploy to temp schema, introspect temp, diff, drop temp.