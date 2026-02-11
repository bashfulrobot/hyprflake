# CLAUDE.md Optimization (on-demand)

Use this only when editing or restructuring `CLAUDE.md` or related docs.

Best-practices reference:
- https://www.builder.io/blog/claude-md-guide

## CLAUDE.md Structure

The top-level `CLAUDE.md` follows this pattern:

1. Keep it concise (under ~50 lines) with essentials, gotchas, and project map.
2. Use a single `@import` for `extras/docs/commands.md` to keep commands accessible.
3. Reference deep docs directly — no intermediate stub indexes.
4. Each doc reference includes a short description so Claude knows when to open it.
5. Move meta-guidance (like this file) out of the main CLAUDE.md.

## Process Summary (2026-02-11)

What was optimized:

- Rewrote `CLAUDE.md` from ~129 lines to ~41 lines.
- Added project conventions (formatter, linter, trailing newline rule).
- Replaced verbose sections (tree diagram, Quick Start, upstream links, maintenance guide) with concise equivalents.
- Created `extras/docs/commands.md` for just commands (imported via `@`).
- Referenced all doc files directly with contextual descriptions.
- Added gotchas: GPU mutual exclusivity, Stylix input requirement.

If updating further:

- Keep `CLAUDE.md` short; move detail into `docs/` or `extras/docs/` and reference directly.
- Add new rules only when real mistakes surface.
- Ensure every file ends with exactly one trailing newline.
