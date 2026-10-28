# Denote library: layout, repos, tags, deferred items (state as of 2026-10-23)

Written so it survives a cleared conversation. Design rationale and tested
code: `~/acropolis/manager/capture-design-recommendation.md`. Zotero/Drive audit:
`~/acropolis/manager/zotero-drive-audit-2026-10-22.md`. Decisions:
Claude memory `capture-decisions-2026-10-22`.

## Layout

`~/acropolis/denote-library/` is a plain folder (not a git repo).

| Path | What | Repo |
|---|---|---|
| `pkb/` | personal knowledge notes, hubs, ideas (Denote) | `github.com/fiendskrah/pkb` (SSH, `main`) |
| `bib_notes/` | one note per paper read (`#+reference:` citekey) and the Better BibTeX export `full_lib.bib` | `github.com/fiendskrah/bib_notes` (SSH, `main`) |
| `works/<slug>/` | promoted projects and relic snapshots | each its own local repo |

- The path is written once, as `fiend/denote-lib` in `fiend_ews.org` (Foundations,
  "Library path"). `denote-excluded-directories-regexp` hides `works/` from Denote
  so copied notes never appear twice; ripgrep and Claude sessions on
  `denote-library/` still search it.
- `~/pkb` and `~/jdp/denote-lib` are symlinks into it; the five shortcut symlinks in
  `pkb/` are relative.
- Pre-split history of the old single repo: `~/acropolis/denote-library-retired-2026-10-23/old-root-denote-library.git`
  (also on GitHub as `denote-library`).

## Backups

- GitHub: `~/acropolis/fiend_os/repo-sync/sync-repos.sh`, launchd agent
  `com.fiend.repo-sync`, hourly check, real work once per 7 days (next about
  2026-10-30). Push only, defensive, snapshot-commits `pkb` and `bib_notes`
  (`Auto-sync <host> <date>`). The bucket is `repos.conf`; log
  `~/Library/Logs/repo-sync.log`; off: `launchctl bootout gui/$(id -u)/com.fiend.repo-sync`.
- `*.pdf` is gitignored in both repos, so PDFs in `pkb/refs/` are not backed up.
- ThinkPad mirror (`linux_box/backups`): only `narsc-ml-paper` is on its list;
  adding `pkb`/`bib_notes` was deferred by Dylan.
- Zotero chain: Chrome connector -> Zotero -> linked files in
  `~/Library/CloudStorage/GoogleDrive-.../My Drive/zotero` (ZotMoov) -> Better BibTeX
  export `bib_notes/full_lib.bib` (absolute `file` paths) -> citar / citar-denote.
  Two old BBT registrations (`reading_list`, `quals`) cannot be removed from the menu.

## Tags (Denote keywords, so filetags)

- Stage, one of: `ideation` (seed), `paper` (promoted, being worked), `relic` (frozen).
- Priority, one of: `p1`, `p2`, `p3` (`p3` = parked).
- Org agenda: `C-c a i` lists ideas and papers by priority; the dashboard `d` splits
  Ideation into P1/P2. A note needs a headline (the `* IDEA` skeleton) to show up.
- Changing a keyword renames the file; the Denote ID does not change, so links hold.
- Other forms (`article`, `talk`, `oped`) can be added later as keywords.

## Works and relics

- Promotion is a copy: `fiend_tools/promote-idea.py` (`M-x fiend/pkb-promote`, dry run
  by default) copies a seed note, the notes it links, bib notes, PDFs and a subset
  `.bib` into `works/<slug>/` and runs `git init`. Never run on its own: Dylan decides.
- Relic snapshots: `fiend_tools/snapshot-relic.sh` (dry run by default). Done for
  `schoolneighborhoodconcordance` (Rey2024, key `rey2024MeasuringSpatial`),
  `contig_frag`, `seg-opt-district-bounds-2024`. Each has `SNAPSHOT.org`,
  `SKIPPED.tsv`, `.project`. Originals stay in `~/github/academic_projects`.
  More candidates: `fire_neighborhoods`, `spatial-clustering-experiment`,
  `state-academia`, `lamesa_cpob_survey`, the three `nsf-*` drafts.

## Deferred (Dylan's calls)

- Capture templates `nk`/`ni`/`nw` (A.1): they do not create notes today; tested fix
  in the report; on hold.
- `narsc-ml-paper` promotion (retroactive): Dylan will do it. Live repo, workers
  active; moving it breaks absolute paths in the launchd backup list
  (`linux_box/backups/scheduled-repos`), the crucible registry, its worktrees and
  Claude's per-project memory folders. Do not touch it meanwhile.
- `fiend/pkb-promote` stays untested until that promotion; do not prompt him to test it.
- Forwarding symlink `~/jdp/denote-lib` goes about 2026-11-22. Still depending on it:
  the two old BBT export registrations (remove their `autoExport` keys from Zotero's
  `prefs.js` with Zotero closed), Emacs state files (`.org-id-locations`, `bookmarks`,
  `recentf`, `places`), stale old config copies (`~/acropolis/fiend_ews.org`,
  `~/acropolis/jdp/fiend_ews.org`, `jdp/pkb-parser.el`), `jdp/written-quals/day2.run.xml`.
- Optional Zotero cleanup: 11 dead annotation attachments, `carruthers.pdf`, 56
  orphan files on Drive, 394 group-library PDFs not on Drive.
- Design questions closed 2026-10-26 (Dylan): tag taxonomy frozen as above (stage +
  priority only); personal and professional tasks share one agenda for now, and
  `~/acropolis/personal/` is ignored. Capture templates stay on hold. Revisit only if
  he raises it.
