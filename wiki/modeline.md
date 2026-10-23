# Mode line (Doom Modeline)

Written 2026-10-23 from a teaching session with Dylan, who had never looked at
the bottom bar. Config lives in `fiend_ews.org`, Interface chapter, section
"Doom Modeline" (after "Themes").

## What is configured

```elisp
(use-package doom-modeline
  :hook (after-init . doom-modeline-mode)
  :custom
  (doom-modeline-buffer-file-name-style 'truncate-with-project)
  (doom-modeline-buffer-file-name-function #'fiend/mode-line-slug)
  (doom-modeline-height 28)
  (doom-modeline-enable-word-count t)
  (doom-modeline-total-line-number t))
(display-time-mode 1)
```

- **Path style** `truncate-with-project`: file name shown from the project
  root. `pkb/` and `bib_notes/` are each their own git repo (since
  2026-10-23), so a PKB note shows as `pkb/<title>.org`.
- **Slug** (`fiend/mode-line-slug`, regexp `fiend/mode-line-denote-regexp`):
  display only, never renames. `20260109T154328--home-server__homeserver_hub.org`
  shows as `home-server.org`. Drops the timestamp, optional `==signature` and
  `__keywords`, keeps the title and the whole extension (`.org.gpg` too).
  Non-Denote names and Denote names with no `--title` pass through unchanged.
  The hover text still shows the real path. It plugs into
  `doom-modeline-buffer-file-name-function`, which receives the full path and
  returns the replacement; only the last component is rewritten. Tested on
  sample names (keywords, no keywords, signature, no title, plain files).
- **Added by Dylan's choice**: word count (Org/Markdown, selection count while
  text is highlighted), total line count (`12/340`), clock.
- Replaced the stock Emacs bar. Doom Modeline was installed but unloaded before;
  no rationale was ever recorded for that.

## Reading the bar (Doom's `main` layout, left to right)

Left: active-window colour bar; evil state (`<N>` `<I>` `<V>`); window number
(only with a numbering package, none here); search match count (`3/12`);
file icon + name + save marker (pencil/dot = unsaved, lock = read-only);
`@host` for TRAMP files; position (percent, line:column); selection info
(lines/chars/words while a region is active).

Right: org-clock timer (while clocked in) and other misc info; project name;
battery (only with `display-battery-mode`); input method; encoding (`LF UTF-8`);
major mode icon and name; git branch with status colour; flymake/flycheck
counts; clock (`display-time-mode`).

Minor modes are hidden by default (`doom-modeline-minor-modes nil`). Hover for
tooltips; many segments are clickable. Every option is a `doom-modeline-*`
variable (`M-x customize-group doom-modeline`); put changes in the `:custom`
list in `fiend_ews.org`.

For comparison, the stock Emacs 30.1 bar was: `U:**-` (encoding/eol, modified,
remote), buffer name padded to 12 characters, `All 12:3` position, vc branch,
evil tag (inserted after the position segment), `(Org Wk …)` major mode plus
minor-mode lighters, then `mode-line-misc-info`.

## Options not taken

- **Custom bar on the built-in `mode-line-format`**: a hand-written
  `mode-line-buffer-identification` `:eval` with an abbreviating path function
  (width budget 30, keep first two components, `~/jdp/../project-root/`
  style) and the same Denote regexp. Fully tested in batch and in a tty Emacs
  and ready, but Dylan chose Doom instead. Reconsider if Doom becomes a
  nuisance (icon fonts, height, startup cost).
- **`mood-line`, `minions`** (lighter alternatives; minions collapses minor
  modes into a menu): not tried.
- **Other segments, off by default**: battery (`display-battery-mode`),
  indentation info, minor modes, file size, github/mu4e/gnus/irc. Add only if
  missed.
- **Other `doom-modeline-buffer-file-name-style` values** (`file-name`,
  `relative-from-project`, `truncate-upto-project`, `auto`): changing style is a
  one-line edit; `truncate-with-project` was accepted as working.
- **Window-width-scaled path budget** (only relevant to the custom bar): skipped.

## Setup notes

- Needs the Nerd font for icons: `M-x nerd-icons-install-fonts` once, then
  restart (Dylan confirmed the bar works).
- `compat` was suspected missing but `doom-modeline` loads fine.
- `spacious-padding` coexists; height is set by `doom-modeline-height`.
- `format-mode-line` returns empty strings in `emacs --batch`; test mode-line
  code in a tty Emacs (`script -q /dev/null emacs -Q -nw -l test.el`) or call
  the functions directly.

## Deferred / open

- Nothing about the modeline is outstanding. Optional tuning only if the right
  side feels crowded (drop the clock or total line count).
- Related deferred items, not modeline: `fiend/pkb-promote --execute` is untested
  by decision until the narsc-ml-paper promotion; capture templates (A.1) on hold.
