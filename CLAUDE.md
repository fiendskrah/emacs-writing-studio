# Emacs Config — Project Context

Literate Emacs configuration for Dylan, a PhD student in his final year.
Source of truth is `fiend_ews.org`, tangled into `init.el`. Four concerns
drive most design decisions: dissertation writing, literature/reference
management, research note-taking, and deadline-driven task tracking.

## Wiki

Accumulated knowledge (audits, decision history, deeper background) for
this config lives in `wiki/`, not here — this file only holds rules
that must apply automatically every session. Start at `wiki/index.md`
for the full page catalog. `wiki/` is tracked in git (since 2026-09-23,
branch `fiendmacs`) - commit wiki changes, and only wiki changes.

When you read a new source or make a decision in a session: update the
relevant wiki page, and append an entry to `wiki/log.md` (format:
`<date> <type> | <title>`, e.g. `ingest` for a new source, `decision`
for a methods choice, `lint` for a health-check pass). Don't let
knowledge accumulate only in chat history — file it into the wiki so
the next session starts from it.

## Critical rule: never hand-edit `init.el`

`init.el` and `custom.el`'s auto-generated parts are fully regenerated
from `fiend_ews.org` via `org-babel-tangle-file`, bound as
`SPC x r` → `hydra-system` → `fiend/tangle-and-restart`. Direct edits to
`init.el` get silently overwritten on the next tangle/restart — this was
confirmed twice (edits reverted byte-for-byte per `git diff --stat`).

**All config changes go in `fiend_ews.org`.** Always tangle before
assuming a change didn't take effect.

`fiend_ews.org` was rewritten 2026-10-21 as one chapter per function, in
load order (Foundations, Control, Interface, Org Mode, Agenda, Notes and
References, Files and Reading, Tools, Writing, Publication): prose, then
code, no code comments. New code goes below its dependencies; rationale from
the old comments is in `wiki/fiend-ews-rewrite.md`. Backups before a change
go in `bak/` (untracked) as `fiend_ews.org.bak-<date>`; history lives in git
on branch `fiendmacs`, which is the main branch for this config.

## Architecture

- **Dissertation writing**: org-mode as the drafting/export surface.
- **Literature/reference management**: Zotero + Better BibTeX as source
  of truth, surfaced via `citar` / `org-cite`. Bib notes are found by
  the `bib` keyword under `denote-directory` (`citar-notes-paths` in `custom.el` is inert).
- **Research notes (PKB)**: Denote-based, root `~/acropolis/denote-library/`
  (moved there 2026-10-23 from `~/acropolis/jdp/denote-lib`, reached as
  `~/jdp/denote-lib` through a forwarding symlink kept for about 30 days;
  the path is written once, as `fiend/denote-lib` in the Foundations
  chapter), split into sibling dirs distinguished by Denote keyword:
  - `pkb/` — keyword `pkb` + topic keywords (`academia_pkb`,
    `tool_writing_pkb`); created via `denote-org-capture` or
    `fiend/pkb-extract-subtree-to-note`.
  - `bib_notes/` (renamed from `notes/` 2026-10-23) — keyword `bib`, one note per paper, plus the Better BibTeX export `full_lib.bib`; created/opened via
    `citar-denote` (`citar-denote-open-note`), linked via
    `#+reference: <citekey>` front matter.
  - Both dirs hold stable symlinks (`access.org`, `assets.org`) pointing
    at real timestamped files elsewhere. Any directory-glob function
    over these dirs must exclude them with
    `seq-remove #'file-symlink-p`, or headlines get double-counted.
  - `works/` — promoted projects, each its own git repo (frozen copies of
    notes share Denote IDs with live ones, so `denote-excluded-directories-regexp`
    hides `works/` from Denote). Stage keywords `ideation`, `paper`, `relic`;
    priority keywords `p1`-`p3`; agenda view `C-c a i`. Design:
    `~/acropolis/manager/capture-design-recommendation.md`.
  - **No placeholder notes**: don't pre-create a blank note for every
    citekey. Track unread items via the bare citekey in TODO items;
    only run `citar-create-note` / `citar-denote-create-note` once a
    paper is actually read. `citar-denote-nocite` surfaces unprocessed
    bibliography items without needing placeholders.
  - **Non-note attachments** (PDFs, receipts, etc.): loose files live
    flat in `pkb/refs/` (plain descriptive filenames, not Denote-identifier
    -named), linked from prose with `[[file:refs/<filename>][description]]`.
    Established precedent (mentorship note, DAG note), extended 2026-09-03
    for personal life-admin records (traffic ticket receipt in
    `finances.org`). **Personal/life-admin organization within pkb is an
    acknowledged unsettled area** — the structure was built around
    bibliographic notes and personal content is being fit in post-hoc; the
    the library's home was settled 2026-10-23 (`~/acropolis/denote-library`). Ask rather
    than assume placement for this kind of content; don't treat any single
    filing decision as a fixed convention yet.
  - **Full-text search**: `consult-notes-search-in-all-notes`, bound both
    at `C-c w d g` and `SPC p g` (hydra-pkb, added 2026-09-03) — searches
    note *contents* across all of `denote-directory` (both `pkb/` and
    `bib_notes/`), the fallback for when title/tag pickers (`SPC p p` /
    `SPC p t`) don't find it. Needs `ripgrep` on PATH (`consult-notes-use-rg`
    defaults `t`); installed via Homebrew 2026-09-03, confirmed working.
- **Task management**: `org-agenda` is the primary work-management
  surface (not secondary), covering dissertation work, coursework
  (e.g. GEOG 581, Fall 2026), and general obligations.
  - `org-agenda-files` assembly is base + `pkb/` glob only, recomputed
    per-call (`fiend/refresh-agenda-files`, advised onto `org-agenda`
    itself) rather than once at startup:
    ```elisp
    (setq org-agenda-files (append fiend/base-agenda-files (fiend/pkb-org-files)))
    ```
    `fiend/bib-org-files` (globs `bib_notes/`, the 175 bibliographic/
    citar-denote files) was dropped from the append 2026-09-21 — those
    notes are meant to hold personal thoughts on a source, not be a
    second home for standalone TODOs. The function is left defined but
    unused, a one-line toggle back on if needed.
  - `org-refile-targets` is **deliberately not** extended to `bib_notes/` —
    only references `fiend/pkb-org-files`, keeping project-task refiling
    separate from the pkb/notes split.
  - TODO keyword sequences (two independent sequences — note `DEADLINE`
    is a keyword in the second, distinct from the `DEADLINE:` planning
    line):
    ```elisp
    (org-todo-keywords
     '((sequence "TASK(a)" "TODO(t)" "NEXT(n)" "IDEA(i)" "|" "DONE(d)")
       (sequence "HOLD(h)" "WAITING(w)" "DEADLINE(D)" "|" "CANCELLED(c)")))
    ```
  - Recurring course meetings (e.g. GEOG 581): one headline with multiple
    plain active timestamps in the body, not a `SCHEDULED:` repeater
    (only one `SCHEDULED:` is honored per headline). Time ranges use no
    spaces around the hyphen: `11:00-12:40`.
  - `org-super-agenda` / `org-super-agenda-groups` and custom commands
    are expected to keep evolving — treat any current view as a
    snapshot, not a spec.
- **Remote compute**: research server "cogs" via tmux + Jupyter Lab over
  SSH port forwarding. Always give tmux sessions explicit names to avoid
  colliding with other users' unnamed sessions.
- **Completion framework**: vertico/orderless/marginalia/consult stack
  (EWS default) is the one actually active. `ivy`/`counsel`/`swiper`/
  `ivy-rich`/`ivy-posframe` are also configured (Interface chapter, "Swiper, Ivy and Counsel") but
  `(ivy-mode 1)` is deliberately not enabled (2026-09-03) — it was
  running simultaneously with `vertico-mode`, each claiming the default
  `completing-read-function`. Nothing was removed: `swiper`/`counsel-*`
  bindings (`C-s`, `C-x C-f`, `M-x`, `C-x b`, `SPC tt`, `SPC .`,
  hydra-file `r`) still work unchanged since they call `ivy-read`
  directly and don't need `ivy-mode` active globally — only plain,
  un-remapped `completing-read` calls now render via vertico instead of
  ivy. If you want ivy back as the default, add `:config (ivy-mode 1)` to the `ivy` block.
  `vertico-posframe` (added 2026-09-03, mirrors `ivy-posframe`'s
  frame-center positioning) makes vertico-driven commands — e.g. the PKB
  full-text search above — render centered too, instead of the plain
  bottom minibuffer.
  Backups of pre-change file states: `fiend_ews.org.bak-2026-09-03`
  (before ivy-mode/ripgrep fix), `fiend_ews.org.bak-2026-09-03b` (before
  vertico-posframe/hydra-pkb search binding).

## Open issues

- **Export**: `C-c C-e` works fine inside actual org buffers (confirmed
  2026-09-02) — earlier report of it being "broken" was from testing it
  outside an org document, where it's naturally unbound. Not a bug.
- ~~`general.el` leader-key setup error~~ — confirmed harmless (2026-09-21),
  no leader bindings actually broken. Resolved.
- ~~`biblioq` package unavailable~~ — fixed 2026-09-21 (`:ensure nil`,
  see `wiki/org-agenda-system-audit.md`); it was also the cause of a
  separate startup hang (forced a full 4-archive network refresh every
  launch). Resolved.
- ~~`denote` package fails to init (`denote-org-extras`)~~ — fixed 2026-10-22: Denote 4.0 moved its Org extras into the separate `denote-org` package; the config now loads that instead, and Denote was upgraded 4.0.0 → 4.2.x because `denote-org` 0.3.0 needs a newer Denote (`denote-get-completion-table`). `C-c w d h` works. Resolved.
- **`history` file corrupted** at line 31 (`evil-jumps-history` has a
  dangling `#99#` circular-reference with no matching `#99=`) — savehist
  errors loading it on every startup. Low priority, not blocking.
- **No documented rationale** for org-roam, vulpea, org-noter, or why
  Denote was chosen over alternatives. Don't
  assume these were considered and rejected — ask rather than infer if
  they come up.
- **PKB tag taxonomy design** (2026-09-21 audit consolidated
  `bigpicture`/`someday`/`media`/`project`/`ideation`/`knowledge`, but
  flagged whether these should eventually be structural — TODO keyword
  states or date-presence-keyed agenda views — rather than tags at all;
  see `wiki/org-agenda-system-audit.md` "Still open"). Still an open
  design question, not decided.
- **Personal vs. professional task organization**: how life-admin/
  personal tasks and dissertation/coursework/professional tasks should
  be organized, discovered, and presented separately (or not) in
  org-agenda — overlaps with the pkb personal-content-placement
  question above. Open design question.
- Spaced review / zettelkasten-style backlinking: not yet discussed
  whether wanted.

## Status

**Working**: tangle-then-restart workflow; Denote PKB split with symlink
exclusion; citar/citar-denote/org-cite workflow incl. no-placeholder
policy; org-agenda-files assembly (`bib_notes/` dropped 2026-09-21 — see
below); TODO keyword sequences; org export (`C-c C-e`, confirmed working
inside org buffers); PKB full-text search
(`consult-notes-search-in-all-notes`, fixed 2026-09-03 by installing
ripgrep, now also on `SPC p g` and centered via `vertico-posframe`);
single active completion framework (vertico, `ivy-mode` disabled
2026-09-03, no bindings lost); Fall 2026 GEOG 581 agenda entries via the
single-headline/multiple-timestamps pattern; Doom Modeline (enabled 2026-10-22, replacing the stock bar; PKB
filenames are slugged in the display only via `fiend/mode-line-slug`; word
count, clock and total line number on); startup (no more hang or
blocking errors, per 2026-09-21 audit — `wiki/org-agenda-system-audit.md`).

**In progress**: `history` corruption (low priority) — see Open Issues.

**Planned**: ongoing literature notes in Denote as reading progresses;
continued iteration on `org-super-agenda` views; PKB tag taxonomy and
personal-vs-professional task organization design (see Open Issues).
