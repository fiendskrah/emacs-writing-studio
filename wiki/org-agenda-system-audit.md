# Org-agenda / PKB tagging system audit (2026-09-21)

## The question

Whether the `someday` tag (and by extension the broader task-tracking
setup) wasn't pulling its weight because: (a) not enough of life is
loaded into the system, (b) the system has struck a working balance
between surfacing priorities and overwhelm, or (c) the system itself
has disconnects between its moving parts.

## Answer: (c), with (a) a minor factor and (b) not the problem

**(b) isn't the problem.** The dashboard's `org-super-agenda-groups`
already discarded `someday`/`bigpicture` from the daily view, with a
separate `"s"` command surfacing them on demand — a deliberate,
working anti-overwhelm mechanism.

**(a) is a minor factor at best.** Only 9 of 36 personal PKB files had
any `SCHEDULED`/`DEADLINE` at all, and nearly half of all those markers
sat in one file (the AAG conference note). But loading more
*unscheduled* content wouldn't fix surfacing — the gap was in which
primitives got used, not sheer volume.

**(c) was the real answer**, evidenced concretely:

1. `~/jdp/milestones.org`, `advising.org`, `work.org`, `emacs.org` all
   had real `SCHEDULED`/`DEADLINE` items but weren't in
   `org-agenda-files` — invisible to the agenda, full stop. (Decided
   out of scope for the agenda-files fix below — `milestones.org` is
   legacy content going back to 2021, not meant to be live-tracked.)
2. `custom.el` had a dead, stale `org-agenda-files` snapshot silently
   overwritten by `init.el` — harmless but a footgun for a future edit
   in the wrong file.
3. `someday` had no real identity — not in `org-tag-alist` (undefined
   entirely), working only because two hardcoded strings referenced it
   in `org-agenda-custom-commands`. Someday-tagged content (movies/tv/
   music/books lists) behaved identically to untagged content — a
   media-category label borrowing the GTD word "someday," not an
   actual deferred-action mechanism. `ideation` and `bucketlist` were
   the same: undated, no distinct agenda behavior.
4. Two stale/duplicate TODOs in the `home-server` PKB hub note (see
   "Still open" below).
5. This literally happened live in the same session — a reading-log
   request got filed in the wrong system (wiki, then PKB) on the first
   pass.

## What was fixed this session

- **The actual startup error** ("Non-existent agenda file...") — a
  fix already written in `fiend_ews.org` on 2026-09-18
  (`fiend/refresh-agenda-files` + `advice-add` on `org-agenda`,
  recomputing `org-agenda-files` per-call instead of once at startup)
  had just never been tangled. Tangled now.
- **Tag taxonomy consolidated**: `org-tag-alist` added (was
  undefined). `bigpicture`/`someday`/`media`/`project` are now in one
  consistent discard+review mechanism (dashboard `:discard` set + the
  `"s"` command) instead of three overlapping placeholder tags.
  `ideation` narrowed to genuine idea-sparks
  (`native-plants-and-biodiversity`, `pull-data-from-sd-data-portal`).
  `dist-opt`/`spatial-clustering-experiment-kedron` retagged
  `project` (they're real, substantive work, not ideas).
  `openstreetmap` retagged `knowledge`. `big-piture.org` renamed/
  retagged to `bigpicture` (fixing a typo and finally giving the
  agenda's `bigpicture` hook — referenced since before this tag
  existed anywhere — an actual file). Media notes
  (`music`/`movies`/`television`/`books`) dropped `someday`, kept
  `media`.
- **A startup hang** (unrelated to the above, traced via a macOS
  `sample` stack capture and `*Messages*` after `C-g`) had two causes:
  `biblioq` (a permanently-dead package, still implicitly `:ensure t`)
  forcing a full 4-archive network refresh every startup — fixed with
  `:ensure nil`; and the dashboard's `(agenda . 7)` widget eagerly
  scanning all of `org-agenda-files` (244 files) at every launch
  regardless of whether the agenda was going to be opened — dropped
  from `dashboard-items`, making the real scan lazy for free.
- **`notes/` (175 bibliographic/citar-denote files) dropped from
  `org-agenda-files` entirely** — per-user, those notes are meant to
  hold personal thoughts on a source, linked from elsewhere, not be a
  second home for standalone TODOs. Cuts the real `org-agenda` scan
  from 244 files to ~69. `fiend/bib-org-files` is left defined
  (unused) so it's a one-line toggle back on if needed.
- **A visible progress indicator** added around `org-agenda-files`
  scanning (`org-agenda-prepare-buffers`/`org-check-agenda-file`
  advice → a standard `progress-reporter`), so a multi-second scan is
  no longer indistinguishable from a hang.

## Still open

- **Two stale/duplicate TODOs in the `home-server` PKB hub note**
  (`~/jdp/denote-lib/pkb/20260109T154328--home-server__homeserver_hub.org`),
  both `DEADLINE: <2026-09-25>`: "implement github clone on
  homeserver" is already done (`linux_box` cloned via GitHub SSH per
  `acropolis/linux_box/wiki/todo-thinkpad-migration.md` line 93,
  superseded by the larger self-hosted-git-server TODO there) and
  "wipe and integrate kim's old macbook" is treated as loose
  "eventually" scope in that wiki's `index.md` but claimed due-in-days
  in the hub note. Not reconciled yet — deliberately deferred.
- Whether `ideation`/`knowledge`/`someday` should eventually be
  structural (TODO keyword states, or agenda views keyed off date
  presence/absence) rather than tags at all — raised but not decided;
  the current tag consolidation is a real improvement, not necessarily
  the final shape.
- `~/jdp/denote-lib/pkb/20260802T120351--new-task__ideation.org` is an
  empty stub, worth deleting.
- `~/jdp/denote-lib/pkb/20260802T112009--torrenting__homeserver_tool.org`
  had a corrupted "Books" entry noticed mid-session (lost its
  DEADLINE/checklist, garbled text) — flagged, not touched, not
  independently re-verified since.

## Later addition: weekly focus (2026-10-05)

Weekly Review step "pick 2-3 things to focus on" now has a home:
inbox.org top-level `* Weekly focus`, filled by capture `SPC o c w`
(one date prompt via `fiend/weekly-focus-range`; produces
`** Week of [Mon]--[Sun] :focus:` with `*** TODO` children, M-S-RET for
more). Surfaced once atop the week agenda by a custom `"a"` command
(shadows built-in `a`, so `SPC o a a`) and as a group in the `"d"`
dashboard.

Design choices, and why:
- Inactive date range: an active range bannered the heading on every
  agenda day, which Dylan didn't want.
- TODO headings, not checkboxes: checkboxes never reach the agenda.
- No `[/]` cookie: the item count varies week to week; Dylan didn't
  want the counter.
- Old weeks: tag `:ARCHIVE:` (C-c C-x a) to keep them folded; leftover
  TODOs then drop out of the agenda.

Still open: the Weekly Review's `RESET_CHECK_BOXES` drawer sits below
its checklist, not directly under the heading/planning line, so org
won't read it and the boxes won't auto-reset on repeat. Same for the
Quarterly Review.
