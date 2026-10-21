# Org-agenda strategy review (2026-10-20, parked)

Status: **parked, not approved, nothing applied.** Tracked as a TODO in the
emacs-config PKB note (`pkb/20250721T214640--emacs-config__tool.org`). The goal
is a written strategy for keywords, tags and dashboard views that both Dylan
and Claude can be pointed at. Follow-up to
[org-agenda-system-audit.md](org-agenda-system-audit.md).

## Context

Dylan is moving from directory-structured to-dos to one PKB note per project
that tracks its own to-dos. The keywords and tags predate that and predate
running Claude Code under herdr.

## Findings (usage counts across `pkb/` and `inbox.org`)

- `:project:` is a filetag on dist-opt and the kedron experiment, so the
  dashboard discards each whole note. That conflicts with project notes
  carrying live to-dos.
- `:someday:` is on 3 headings only (2 music TODOs, 2 "What did I learn"
  headings in the project notes).
- The conferences and job-hunt hubs date only the *next* step of each heading;
  the agenda surfaces by date, not by tag.
- TODO 66, TASK 37, NEXT 13, IDEA 24, CANCELLED 23, WAITING 4, HOLD 1,
  DEADLINE (keyword) 0.
- TASK is used both as a parent ("Tasks") and as a leaf ("Pay rent"), so it has
  no distinct meaning.

## Draft recommendation

Keywords:
- Keep TODO, NEXT, WAITING, HOLD, CANCELLED.
- Merge TASK into TODO (migrating ~37 PKB items needs approval).
- Move IDEA into the parked sequence next to HOLD (about 9 items leave the
  daily dashboard: 6 in dissertation-chapter-1, 2 in aag-2027, 1 in geog581).
- Drop the unused DEADLINE keyword (confusable with the `DEADLINE:` line).

Tags:
- `someday` = the single parked flag, placed on headings rather than filetags
  (Denote mirrors filetags into filenames, so filetags mean renames). Tags are
  the only thing that hides a subtree, since TODO states do not inherit.
- `project` = plain category, not parked; add a "Projects" dashboard group.
- `media` = category, dropped from the discard list; media notes also get
  `someday` (the `tm` capture template already does).
- `bigpicture` = drop the tag and discard rule; mark that note `someday`.
- `ideation`, `knowledge`, `focus` = unchanged.

Views:
- `"d"` dashboard discards only `:tag "someday"` and `:todo ("IDEA" "HOLD")`,
  and gains a "Projects" group.
- `"s"` becomes `tags-todo "someday"` plus `todo "IDEA|HOLD"`, renamed "Parked".

## Open decisions

1. TASK into TODO, and whether to migrate existing PKB items.
2. IDEA into the parked sequence.
3. `project` as a category only, `someday` as the sole parked flag.
