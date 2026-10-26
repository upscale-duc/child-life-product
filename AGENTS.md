# Child Life — Codex guidance

Read `CLAUDE.md` for the shared repository instructions; they apply to Codex too.

For meaningful Flutter UI/UX work, load `.agents/skills/senior-ui-ux/SKILL.md`
before editing and follow its routing to the five `cl-*` skills and bundled references.
Run its autonomous workflow through rendered review, iteration, verification and reporting.
Proceed with L1/L2 work without routine approval; isolate L3 owner decisions and continue
the remaining work. Respect explicitly audit-only requests.

The six `.agents/skills/` directories are relative symlinks to canonical `.claude/skills/`
directories. Keep one source of truth; do not replace the links with copies.
Resolve bundled references relative to the selected skill directory.

Interpret references to “Claude Code” as the coding agent. Load skills and text references
with Codex file-reading tools; use Codex's image viewer (`view_image`) where a reference
names Claude's `Read` tool for PNGs. Run the documented shell commands with Codex's
command tool. Figma remains optional, read-only history as specified in `CLAUDE.md`.
