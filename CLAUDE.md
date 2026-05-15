# CLAUDE.md

## Rules

These rules apply to every task in this project unless explicitly overridden. Bias: caution over speed on non-trivial work. Use judgment on trivial tasks.

### Rule 1 — Think Before Coding
State assumptions explicitly. If uncertain, ask rather than guess. Present multiple interpretations when ambiguity exists. Push back when a simpler approach exists. Stop when confused. Name what's unclear.

### Rule 2 — Simplicity First
Minimum code that solves the problem. Nothing speculative. No features beyond what was asked. No abstractions for single-use code. Test: would a senior engineer say this is overcomplicated? If yes, simplify.

### Rule 3 — Surgical Changes
Touch only what you must. Clean up only your own mess. Don't "improve" adjacent code, comments, or formatting. Don't refactor what isn't broken. Match existing style.

### Rule 4 — Goal-Driven Execution
Define success criteria. Loop until verified. Don't follow steps. Define success and iterate. Strong success criteria let you loop independently.

### Rule 5 — Use the model only for judgment calls
Use me for: classification, drafting, summarization, extraction. Do NOT use me for: routing, retries, deterministic transforms. If code can answer, code answers.

### Rule 6 — Token budgets are not advisory
Per-task: 4,000 tokens. Per-session: 30,000 tokens. If approaching budget, summarize and start fresh. Surface the breach. Do not silently overrun.

### Rule 7 — Surface conflicts, don't average them
If two patterns contradict, pick one (more recent / more tested). Explain why. Flag the other for cleanup. Don't blend conflicting patterns.

### Rule 8 — Read before you write
Before adding code, read exports, immediate callers, shared utilities. "Looks orthogonal" is dangerous. If unsure why code is structured a way, ask.

### Rule 9 — Tests verify intent, not just behavior
Tests must encode WHY behavior matters, not just WHAT it does. A test that can't fail when business logic changes is wrong.

### Rule 10 — Checkpoint after every significant step
Summarize what was done, what's verified, what's left. Don't continue from a state you can't describe back. If you lose track, stop and restate.

### Rule 11 — Match the codebase's conventions, even if you disagree
Conformance > taste inside the codebase. If you genuinely think a convention is harmful, surface it. Don't fork silently.

### Rule 12 — Fail loud
"Completed" is wrong if anything was skipped silently. "Tests pass" is wrong if any were skipped. Default to surfacing uncertainty, not hiding it.

## Perl Rules

**MANDATORY: load the `perl-core` skill via the Skill tool before editing any Perl code in the workspace.** It encodes Getty's house rules (module loading, Moose patterns, cpanfile versioning for Getty-authored CPAN distributions, style). The rules below are the TL;DR — the skill has the full list and rationale.

- **`use Module;`** to load modules. `require` only when you absolutely know why (runtime plugin loading, not just "I want lazy").
- **`->instance`** for MooX::Singleton / MooseX::Singleton classes. `->new` for everything else.
- **Never copy a `$VERSION` from a Getty-authored repo into a cpanfile** — repo is the next unreleased version. Check `cpanm --info` for the actual released version. Every Getty-authored dependency must be pinned to its latest released CPAN version.

## Workspace Overview

This is a DBIO driver distribution for PostgreSQL with the Apache AGE graph extension.

Apache AGE adds openCypher graph query support to PostgreSQL. This driver integrates with DBIO::PostgreSQL and provides graph lifecycle management plus cypher() SQL function execution.

## Distribution Configuration

Uses `[@DBIO]` plugin bundle with core = 1.

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