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

2026-09-23 fix | Dired: SPC leader and "." dotfile toggle were shadowed by evil-collection dired normal-state keys (SPC -> dired-next-line, "." -> dired-clean-directory). Fixed via evil-collection-setup-hook in evil-collection :init: SPC unbound in dired normal state (falls through to leader), "." -> dired-omit-mode. Scoped to dired only; SPC may be shadowed the same way in other evil-collection modes. Backup: fiend_ews.org.bak-2026-09-23d.

2026-09-23 note | Open lead on heading lag: if M-up/M-down on headings is still slow after org-modern-star nil, next suspect is org-indent-mode (org-startup-indented t), which recomputes line prefixes on subtree moves. Test: M-x org-indent-mode off in a big buffer.

2026-09-30 decision | org-babel D2 support: EWS "Advanced export settings" block now does (use-package ob-d2), adds /usr/local/bin to exec-path (d2 binary, copied from the official v0.9.0 release since brew install d2 failed on the outdated Xcode/no Command Line Tools), and loads python + dot + d2 in one org-babel-do-load-languages call. Each call replaces org-babel-load-languages, so the old dot-only call was quietly dropping python from the list. Verified: temp-copy tangle diff touches only this block; batch-executed a d2 block to SVG. Use: linux_box/wiki/homeserver-map.org. Backup: fiend_ews.org.bak-2026-09-30.

2026-10-05 change | fiend/base-agenda-files: dropped "~/jdp/conferences.org". The file moved into pkb/ as the Denote hub note 20261005T134223--conferences__hub_conferences.org, which the pkb/ glob (fiend/pkb-org-files) already includes, so there was no need to keep a separate base entry. It had gone stale partly because it was outside pkb searches. Verified: temp-copy tangle diff touches only this list. Backup: fiend_ews.org.bak-2026-10-05.

2026-10-05 change | org-capture "w" Weekly focus template: files "Week of <date> [/]" plus 3 empty checkboxes under inbox.org top-level "Weekly focus" heading (file+headline, :prepend t). Supports the Weekly Review "pick 2-3 focus items" step; old weeks get tagged :ARCHIVE: so they stay folded. Verified: temp-copy tangle diff touches only this entry, init.el parses. Backup: fiend_ews.org.bak-2026-10-05b.

2026-10-05 change | Weekly focus now shows in the agenda (rev. of "w" template above): template is "* Week of <Mon>--<Sun> :focus:" + "** TODO" children; range built from one date prompt by new fiend/weekly-focus-range. Week banner shows daily in the day view; new "This Week's Focus" super-agenda group tops the "d" dashboard (focus tag inherited). Dropped the [/] cookie. Old weeks: tag :ARCHIVE: to fold them and drop leftover TODOs from the agenda. Restored missing "* Weekly focus" heading in inbox.org and converted the 2026-10-05 week. Verified: temp tangle diff touches only these 3 spots; batch-rendered dashboard + day view on an inbox copy; range helper tested across DST/year end. Backups: fiend_ews.org.bak-2026-10-05b (pre-template), inbox.org.bak-2026-10-05.

2026-10-05 change | Weekly focus moved onto the week agenda: new custom "a" command ("Week agenda + focus", shadows built-in a, so SPC o a a) = tags-todo "focus" block on top + normal agenda. Week heading timestamp switched to inactive [Mon]--[Sun] (fiend/weekly-focus-range + 2026-10-05 entry in inbox.org) so it no longer bannered every day. "d" dashboard focus group kept. Verified: temp tangle diff only these spots; batch-rendered "a" view on inbox copy. Backups: fiend_ews.org.bak-2026-10-05c, inbox.org.bak-2026-10-05b.

2026-10-11 change | MTG collector deck editor wired in: new "** MTG COLLECTOR" section at the end of fiend_ews.org (after ARCHIVING). Two use-package forms (mtg-deck, mtg-idea; :ensure nil, :load-path ~/github/magic-collector/emacs, autoloaded commands) plus a general "SPC m" prefix: md deck editor, mc collection, mn new deck, ms search, mi idea table. The package itself lives in the magic-collector repo (emacs/, ~2k lines, ERT tests in emacs/test/); it talks to `mtg serve` over ssh (home server) by default, mtg-connection 'local for the Mac copy. Evil normal-state keys are defined by the package (g -> gr under Evil). Verified: temp-copy tangle diff touches only this block; block evaluated in emacs -Q with a stub leader definer (autoloads resolve). Live init.el not touched: SPC x r to tangle and restart. Backup: fiend_ews.org.bak-2026-10-11.

2026-10-11 change | MTG COLLECTOR block retargeted: the package moved inside the magic-collector repo to wiki/archive/emacs-package/ (set aside; the repo's web UI is the interface now), so both :load-path entries and the section's prose now point there. Bindings (SPC m ...) unchanged and still dormant until the next tangle. Remove the section outright if the package is never revived. Verified: temp-copy tangle diff touches only this block (init.el has not been re-tangled since the block was added); archived package's ERT tests pass from the new path. Backup: fiend_ews.org.bak-2026-10-11b.

2026-10-20 decision | Org-agenda keyword/tag/dashboard review parked. Draft recommendation (merge TASK into TODO, move IDEA to the parked sequence, drop the DEADLINE keyword, `someday` as the single heading-level parked tag, `project` as a plain category, dashboard discards only `someday` + IDEA/HOLD) written to wiki/org-agenda-strategy-review.md. Nothing applied. Tracked as a TODO in pkb/20250721T214640--emacs-config__tool.org to write the strategy down.

2026-10-21 change | Staged rewrite of fiend_ews.org as one chapter-per-function document at rewrite/fiend_ews.rewrite.org (Foundations, Control, Interface, Org Mode, Agenda, Notes and References, Files and Reading, Tools, Writing, Publication; prose then code; no code comments). Live fiend_ews.org and init.el NOT touched. Backups: fiend_ews.org.bak-2026-10-21 and ~/jdp/fiend_ews.org. Removed: MTG collector forms (3), commented spell-fu block, never-tangled doom-modeline/rainbow-delimiters text. Kept: ivy/counsel/swiper (bindings still call them). Verified: temp tangle (76 blocks) vs live init.el, read as forms: 181 identical, 5 docstring-only edits, 3 forms only in old (MTG), 0 only in new; sandbox batch load of old vs new init (copied emacs dir, --init-directory): features, minor modes, keymaps, custom variables and hooks identical (7281 lines, only sandbox paths differ). Details: wiki/fiend-ews-rewrite.md.

2026-10-21 change | Rewrite promoted: rewrite/fiend_ews.rewrite.org copied over fiend_ews.org and tangled to init.el (batch; Emacs not restarted, `SPC x r` to pick it up). init.el is byte-identical to the verified temp tangle. Backups: fiend_ews.org.bak-2026-10-21 (pre-rewrite org, also ~/jdp/fiend_ews.org), init.el.bak-2026-10-21 (pre-rewrite init).

2026-10-21 housekeeping | .emacs.d tidy: all fiend_ews.org.bak-* and init.el.bak-* moved into bak/ (not tracked); removed editor leftovers (#custom.el#, #init.el#, %backup%~ [stale Jul 2025 copy of a bib note], custom.el~, fiend_ews.org~, .fiend_ews.org.~undo-tree~), the spell-fu/ cache (spell-fu is no longer configured) and the staged rewrite/ copy (identical to the live fiend_ews.org). Removed ~/jdp/emacs.org (old copy of the config; still in the jdp repo history, deletion not committed).

2026-10-21 change | spell-fu removed entirely: dropped from `package-selected-packages` in custom.el and deleted elpa/spell-fu-20250712.1319. Backup: bak/custom.el.bak-2026-10-21. Sandbox load beforehand showed an identical state fingerprint. Restart Emacs to pick it up.

2026-10-21 change | Config backed up to the ThinkPad: bare repo `homeserver:~/emacs-config-backup.git` (branch fiendmacs, pushed over Tailscale since the ThinkPad has no GitHub key). Refresh with `git push ssh://homeserver/home/fiend/emacs-config-backup.git fiendmacs`. No Emacs on the ThinkPad by decision (config depends on the Mac: ~/jdp, Zotero). custom.el (gitignored, Customize output: citar/denote paths, bibliography, package-selected-packages) is not in any backup. Open: GitHub default branch is still master; Dylan to switch to fiendmacs in repo Settings (no gh CLI installed).

2026-10-21 decision | GitHub default branch is now fiendmacs (switched by Dylan). jdp repo is no longer tracked here; its leftover emacs.org deletion and ~/jdp/fiend_ews.org copy are out of scope.

2026-10-22 change | Bundle A from the capture-design report applied to fiend_ews.org (not tangled; Dylan runs `SPC x r`). (1) One library path: new Foundations section "Library path" with `fiend/denote-lib` (still `~/jdp/denote-lib/`) and `(setopt denote-directory ...)`; the agenda globs, `ews-bibtex-directory` and `my/pkb-dir` in fiend_tools/my-pkb-picker.el derive from it. custom.el left untouched (its old path values are now overridden). (2) Tags: `org-tag-alist` gains exclusive groups p1/p2/p3 and ideation/paper/relic; new agenda command `i` (ideas and papers by priority); dashboard `d` splits "Ideation" into P1/P2 above the rest. (3) `denote-excluded-directories-regexp` hides works/ from Denote. (4) `denote-org-extras` require removed; new `denote-org` block (installs from GNU ELPA at next start via use-package, needs network); `C-c w d h` now `denote-org-link-to-heading`. (5) `fiend/pkb-transcribe-video` writes to pkb/refs/. (6) New `fiend/pkb-promote` and fiend_tools/promote-idea.py (dry run by default). Capture templates (A.1) deliberately NOT changed (Dylan: on hold). Backups: bak/fiend_ews.org.bak-2026-10-22, bak/my-pkb-picker.el.bak-2026-10-22. Verified: temp tangle (77 blocks) diffed against init.el shows only these changes; all 190 forms of the new init read cleanly; Super Agenda `i` and `d` groups and the works/ exclusion tested in `emacs -Q` sandboxes; the `fiend/pkb-promote` wrapper and the full restart NOT run. Details: manager/capture-design-recommendation.md (A.3-A.5, A.7, A.8).

2026-10-22 change | Denote upgraded 4.0.0 -> 4.2.x (package-upgrade by Dylan) after `C-c w d h` failed with "denote-get-completion-table void": denote-org 0.3.0 needs a newer Denote than its declared minimum 4.0.0. Dylan confirmed the command works after restart. Closes the "denote package fails to init" open issue in CLAUDE.md. Rollback copy of the old package: bak/denote-4.0.0.elpa-2026-10-22. CLAUDE.md backup: bak/CLAUDE.md.bak-2026-10-22.

2026-10-22 change | Doom Modeline enabled in fiend_ews.org (new "Doom Modeline" section after Themes; not tangled, Dylan runs `SPC x r`). `doom-modeline-buffer-file-name-style` is `truncate-with-project`; PKB filenames are slugged in the display only via `fiend/mode-line-slug` on `doom-modeline-buffer-file-name-function` (`20260109T154328--home-server__homeserver_hub.org` shows as `home-server.org`; non-Denote and title-less names unchanged). Replaces the earlier custom `mode-line-buffer-identification` proposal. Backup: bak/fiend_ews.org.bak-2026-10-22b. Verified: temp tangle (78 blocks) diffed against init.el shows only this addition; slug regexp tested on sample names; `doom-modeline` loads under `emacs -Q` with package-initialize. Visual result and Nerd font NOT yet checked.

2026-10-23 change | Doom Modeline: added `doom-modeline-enable-word-count`, `doom-modeline-total-line-number` and `(display-time-mode 1)` to the Doom Modeline section of fiend_ews.org (not tangled; Dylan runs `SPC x r`). Backup: bak/fiend_ews.org.bak-2026-10-23. Verified: temp tangle diffed against init.el shows the earlier modeline block plus these three lines only. Visual result not checked.

2026-10-23 lint | `fiend/pkb-promote` wrapper run by Dylan as a dry run on the home-server note (slug homeserver): compilation finished in 0.45s. Same dry run repeated from the shell: plan lists 2 notes (home-server hub, torrenting), refs.bib with 0 of 0 keys, nothing written (no works/ dir exists). Closes the "wrapper NOT run" item from the 2026-10-22 Bundle A entry; the --execute path is still untested.
