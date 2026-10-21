# fiend_ews.org rewrite (2026-10-21, staged, not promoted)

Single-document rewrite of the literate config: Prevos EWS text and the
"fiendmacs" additions merged into chapters in load order. Staged at
`rewrite/fiend_ews.rewrite.org`; the live `fiend_ews.org` and `init.el` are
untouched. Safety copies: `fiend_ews.org.bak-2026-10-21` and
`~/jdp/fiend_ews.org`.

To promote: `cp rewrite/fiend_ews.rewrite.org fiend_ews.org`, then `SPC x r`.
Re-run the form comparison first if either file changed since.

## Structure

Chapters (one H1 each, one H2 per package, prose then code):
Introduction, Foundations, Control (Evil, Hydra, general), Interface, Org Mode,
Agenda, Notes and References, Files and Reading, Tools, Writing, Publication.
Order is dependency order: package management and `ews.el` before anything;
`hydra` before every `defhydra`; Evil before general and the Evil-dependent
overrides; Org before the agenda, dashboard and PKB helpers; Citar before
Citar Denote.

## Removed from the config

- **MTG collector** (two `use-package` forms and the `SPC m` leader block).
  Package was discarded; code lives in the magic-collector repo archive.
- **Commented-out spell-fu block** (flyspell was replaced by spell-fu, then both
  were disabled):
  ```elisp
  (use-package spell-fu
    :hook ((text-mode . spell-fu-mode) (prog-mode . spell-fu-mode))
    :config (setq spell-fu-idle-delay 0.5))
  ```
- **Dead text that was never tangled** (sat outside `begin_src` blocks):
  `rainbow-delimiters` (`:hook (prog-mode . rainbow-delimiters-mode)`), the
  `doom-modeline` block (`:init (doom-modeline-mode 1)`,
  `doom-modeline-buffer-file-name-style 'auto`, `doom-modeline-icon t`) and a
  `(load-theme 'doom-one t)`. Doom experiments can start from these.
- Comment-only `:exports none` blocks and all `;;` code comments.

## Kept on purpose (flag for later)

- **Ivy / Counsel / Swiper stay.** `ivy-mode` is off, but `C-s`, `M-x`, `C-x b`,
  `C-x C-f`, `SPC .`, `SPC t t`, `hydra-file` `r` and the `helpful` remaps call
  them directly. Deleting the block breaks those. Removing it means rebinding
  each to a Vertico/Consult equivalent first.
- `fiend/evil-hook` is defined but never attached to a hook.
- `(require 'denote-org-extras)` still fails at startup (known open issue).
- `doom-themes` with `doom-bluloco-dark` is the only theme loaded; the
  `modus-themes` form only sets variables.
- Duplicate forms retained so the tangle stays form-identical: two `helpful`,
  two `undo-tree`, two `pdf-tools`, two `dired`, several `org`; repeated
  `org-modern-keyword`, `evil-set-initial-state 'messages-buffer-mode`, and
  the two `org-babel-do-load-languages` calls.

## Rationale from removed comments (still true)

- **Org RET binding** is nested under both `evil` and `org`. A bare
  `with-eval-after-load 'org` fired before Evil existed and raised
  `void-function evil-define-key`, which aborted the rest of `init.el`
  (dashboard and leader keys never set up). In the rewrite Evil loads first,
  but the nesting stays.
- **Org RET** is bound per Evil state, not through `org-return-follows-link`
  (which also fired in Insert state and sent directory links to Finder).
- **Agenda keys** `j k / \ l RET v` are rebound because Evil's motion-state
  map outranks `org-agenda-mode-map`; the Super Agenda header keymap is a text
  property, so it needs a plain `define-key`.
- **Dired**: Evil Collection binds `SPC` and `.`; the setup hook restores them.
- **Dashboard**: the agenda widget was dropped because it scanned every agenda
  file at startup. `A` is bound twice (mode map and Evil states).
- **`biblioq`** needs `:ensure nil` or package.el refreshes every archive at
  each start (the 2026-09-21 startup hang).
- **Agenda files** are recomputed per `org-agenda` call (advice); `notes/` was
  dropped from the list 2026-09-21; `fiend/bib-org-files` is the one-line
  toggle.
- **Agenda category column** removed via `org-agenda-prefix-format`. Two
  earlier attempts (buffer-local `org-category` in `org-mode-hook`; rewriting
  the agenda buffer in `org-agenda-finalize-hook`) failed; the second hung the
  agenda.
- **Weekly focus**: inactive range so it is not bannered on each day; TODO
  children, not checkboxes; no `[/]` cookie; archive old weeks with `:ARCHIVE:`.
- **Weekly wins**: no dedicated view; a log-only view loses items when
  `org-super-agenda-mode` is on. Use the `a`/`e` views plus `l`.
- **Org-capture note templates** need the `nil` template slot or
  `:no-save` is read as the template (`Wrong type argument: plistp`).
- **`fiend/pkb-extract-subtree-to-note`** is self-contained because
  `denote-org-extras-extract-org-subtree` does not exist in the installed
  Denote. Keywords are prompted up front so filename and `#+filetags:` are
  written from one value.
- **`SPC p f`** files as a standalone top H1 tagged `:new:` (nesting it buried
  it a fold deep); clearing `:new:` is a weekly-review step.
- **Transcription** runs Whisper through `conda run -n media-tools` because
  Homebrew bottles do not work with the installed Xcode.
- **Stale snapshot**: `custom.el` once held a dead `org-agenda-files`; `init.el`
  value wins.

## Verification

See the log entry for the form comparison and load test results.
