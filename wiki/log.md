# Log

Append-only. Format: `## [YYYY-MM-DD] <type> | <title>`

## [2026-09-20] init | Wiki scaffolded for .emacs.d

Created `wiki/index.md` + `wiki/log.md` (plain files, not a Denote
silo — decided explicitly rather than inferred). Scaffold only, no
content yet. `CLAUDE.md` stays as the source of schema/hard-constraint
rules per its own existing convention; a "Wiki" pointer section was
added there. Populating this wiki — including with a pending org-agenda
+ PKB-tagging system audit (someday-tag usefulness, scheduling
disconnects, wiki/PKB consolidation) — is a separate, later task.

## [2026-09-21] fix | Startup hang traced to two causes, both resolved

Tag-consolidation pass (someday/ideation/bigpicture/media/project/
knowledge - see the still-pending audit write-up referenced above)
included an already-written-but-never-tangled fix for a real bug:
`org-agenda-files` was computed once at startup (a plain setq/append)
rather than recomputed per-agenda-call, so a pkb/ file rename mid-
session went stale until restart - `fiend/refresh-agenda-files` +
`advice-add` on `org-agenda` fixes this (was sitting unused in
fiend_ews.org since 2026-09-18).

Tangling that pass surfaced a separate, unrelated problem: startup
"hanging" for several minutes. Root-caused via a live CPU sample
(macOS `sample`) plus reading `*Messages*` after interrupting with
`C-g`, to two independent causes:
1. `biblioq` (use-package, `C-c w b b` binding) - confirmed gone from
   every package archive per this file's own Open Issues section, but
   still implicitly `:ensure t` via `use-package-always-ensure`, so
   every startup forced a full `package-refresh-contents` across all
   four archives trying (and failing) to find it. Fixed: `:ensure nil`.
2. Dashboard's `(agenda . 7)` widget (`dashboard-insert-agenda`)
   unconditionally scanning all of `org-agenda-files` (244 files as of
   this session's pkb/ cleanup) at every startup via
   `dashboard-setup-startup-hook`, regardless of whether the agenda
   was going to be looked at. Dropped from `dashboard-items` - the
   real scan is now lazy for free, since `fiend/refresh-agenda-files`
   is already advised onto `org-agenda` itself and only runs when that
   command is actually invoked.

Both fixes are in `fiend_ews.org`; `init.el` was regenerated via a
batch `org-babel-tangle-file` call (bypassing a still-stuck GUI Emacs
process that couldn't reach `SPC x r` interactively) rather than a
direct hand-edit, keeping `fiend_ews.org` as the single source of
truth per this file's own "never hand-edit init.el" rule.

**Follow-up (done later same session)**: `notes/` (bibliographic/
citar-denote literature notes, 175 files) was dropped from
`org-agenda-files` entirely - per-user, those are meant to be personal
thoughts on a source, linked from elsewhere, not a second home for
standalone TODO items. `fiend/bib-org-files` stays defined but unused,
so it's a one-line toggle back on. Cut the real `org-agenda` scan from
244 files to ~69. A visible progress indicator
(`fiend/agenda-progress-*`, advised onto
`org-agenda-prepare-buffers`/`org-check-agenda-file`) was also added
around that scan, so it's no longer indistinguishable from a hang.

Full audit write-up (the "someday isn't pulling its weight" question
this whole pass started from) is now at
[org-agenda-system-audit.md](org-agenda-system-audit.md) - includes
what's still open (two stale/duplicate TODOs in the `home-server` PKB
hub note, an empty `new-task.org` stub, a corrupted `torrenting.org`
entry).

## [2026-09-21] lint | CLAUDE.md Open Issues/Status caught up to reality

`CLAUDE.md`'s Open Issues and Status sections still described the
2026-09-02 startup-error snapshot and hadn't been touched by the same
day's later audit/fix pass (log entry above) or GEOG 581 setup —
drifted from actual state per this file's own "file it into the wiki"
rule. Corrected in place: `general.el` leader-key error and `biblioq`
marked resolved (confirmed harmless / fixed via `:ensure nil`,
respectively); GEOG 581 moved from "in progress" to "Working"; the
stale `org-agenda-files` code snippet (still showing `fiend/bib-org-files`
appended) replaced with the current base+pkb-glob-only form; the
Architecture "Export currently broken" line removed (contradicted the
Open Issues bullet next to it, which already said export is fine).
`denote-org-extras` and `history` corruption left open (unaddressed
this session). Two design questions sharpened into their own bullets
per user clarification: PKB tag taxonomy (structural vs. tag, per the
audit's "Still open" section) and personal-vs-professional task
organization/discovery/presentation — both still fully open, not
decided.

2026-09-23 decision | Drop org-modern heading icons (org-modern-star nil, fold arrows lagged on subtree moves via font fallback); explicit macOS-bundled fonts: default/fixed-pitch Menlo, variable-pitch Avenir Next, families only. Backup: fiend_ews.org.bak-2026-09-23. Branch fonts-lightweight-headings (c393a3a). wiki/ now tracked in git.

2026-09-23 decision | Live font switching: fiend/set-font on SPC t f (prose -> variable-pitch, code -> default+fixed-pitch; vertico list of installed families; until restart). Note: set-face-attribute is not an M-x command; built-in fallback is M-x set-face-font. Backup: fiend_ews.org.bak-2026-09-23b.

2026-09-23 fix | SPC t f did not change org buffer text: mixed-pitch-mode snapshots font families into buffer-local face remaps at enable time (mixed-pitch.el ~158-194). fiend/set-font now re-toggles mixed-pitch-mode in every buffer where it is on. Backup: fiend_ews.org.bak-2026-09-23c.
