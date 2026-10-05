(defvar fiend--file-name-handler-alist file-name-handler-alist)
(setq gc-cons-threshold (* 128 1024 1024)
      gc-cons-percentage 0.6
      file-name-handler-alist nil)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024)
                  gc-cons-percentage 0.1
                  file-name-handler-alist fiend--file-name-handler-alist)))

(setq inhibit-startup-message t)
(setq ns-use-native-fullscreen nil) ; fixes tooltip popup bug

;; Emacs 29? EWS leverages functionality from the latest Emacs version.

(when (< emacs-major-version 29)
  (error "Emacs Writing Studio requires Emacs version 29 or later"))

;; Custom settings in a separate file and load the custom settings

(setq-default custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

(keymap-global-set "C-c w v" 'customize-variable)

;; Display line numbers
(column-number-mode)
(global-display-line-numbers-mode t)

(add-hook 'window-setup-hook 'toggle-frame-maximized t)

(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

(use-package all-the-icons
   :if (display-graphic-p)
   :defer t)
  ;; bdf fonts
  (add-to-list 'bdf-directory-list "/usr/local/share/emacs/fonts/bdf")

;; helpful replaces the default emacs help docs
(use-package helpful
  :defer t
  :custom
(counsel-describe-function-function #'helpful-callable)
(counsel-describe-variable-function #'helpful-variable)
:bind
([remap describe-function] . counsel-describe-function)
([remap describe-command] . helpful-command)
([remap describe-variable] . counsel-describe-variable)
([remap describe-key] . helpful-key))

(org-babel-do-load-languages
   'org-babel-load-languages
   '((python . t)))

  (setenv "PATH" (concat (getenv "PATH") ":/Users/fiend/mambaforge/bin"))
(add-to-list 'exec-path "/Users/fiend/mambaforge/bin")

(setq python-shell-interpreter "ipython"
	python-shell-interpreter-args "-i --simple-prompt")

;; Set package archives

;; Package Management

(require 'package)
      
  (setq package-archives
        '(("melpa"  . "https://melpa.org/packages/")
          ("org"    . "https://orgmode.org/elpa/")
          ("gnu"    . "https://elpa.gnu.org/packages/")
          ;; fiend - was missing here even though it's referenced in
          ;; package-archive-priorities below - package-install would have
          ;; had no idea where "nongnu" pointed. Needed for org-contrib.
          ("nongnu" . "https://elpa.nongnu.org/nongnu/")))
    ;; fiend - setting preference for melpa
    (setq package-archive-priorities '(("melpa"  . 100)
    				   ("gnu"    . 50)
    				   ("nongnu" . 0)))

    (package-initialize)
    
    (unless package-archive-contents
    (package-refresh-contents))

  ;; Use-package config
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)

(setq use-package-always-ensure t
      package-native-compile t
      warning-minimum-level :emergency)

;; Load EWS functions

(load-file (concat (file-name-as-directory user-emacs-directory) "ews.el"))

;; Check for missing external software
;;
;; - soffice (LibreOffice): View and create office documents
;; - zip: Unpack ePub documents
;; - pdftotext (poppler-utils): Convert PDF to text
;; - ddjvu (DjVuLibre): View DjVu files
;; - curl: Reading RSS feeds
;; - convert (ImageMagick) or gm (GraphicsMagick): Convert image files 
;; - latex (TexLive, MacTex or MikTeX): Preview LaTex and export Org to PDF
;; - hunspell: Spellcheck. Also requires a hunspell dictionary
;; - grep: Search inside files
;; - gs (GhostScript) or mutool (MuPDF): View PDF files
;; - mpg321, ogg123 (vorbis-tools), mplayer, mpv, vlc: Media players
;; - git: Version control

(ews-missing-executables
 '("soffice"
   "zip"
   "pdftotext"
   "ddjvu"
   "curl"
   ("convert" "gm")
   "latex"
   "hunspell"
   "grep"
   ("gs" "mutool")
   ("mpg321" "ogg123" "mplayer" "mpv" "vlc")
   "git"))

(use-package swiper
  :ensure t
  :bind (("C-s" . swiper)))

;;; LOOK AND FEEL

(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

;; Short answers only please

(setq use-short-answers t)

;; Spacious padding

(use-package spacious-padding
  :custom
  (line-spacing 3)
  :init
  (spacious-padding-mode 1))

;; Modus Themes
(use-package modus-themes
  :custom
  (modus-themes-italic-constructs t)
  (modus-themes-bold-constructs t)
  (modus-themes-mixed-fonts t))

(use-package doom-themes
  :init
  (load-theme 'doom-bluloco-dark t))

;; Mixed-pich mode

(use-package mixed-pitch
  :hook
  (text-mode . mixed-pitch-mode))

(set-face-attribute 'default nil :family "Menlo")
(set-face-attribute 'fixed-pitch nil :family "Menlo")
(set-face-attribute 'variable-pitch nil :family "Avenir Next")

;; SPC t f: pick prose/code, then an installed family. Until restart.
(defun fiend/set-font (faces family)
  "Set FAMILY on FACES globally (prose = variable-pitch, code = default)."
  (interactive
   (let ((target (completing-read "Font for: " '("prose" "code") nil t)))
     (list (if (string= target "prose") '(variable-pitch) '(default fixed-pitch))
           (completing-read (format "%s font: " target)
                            (seq-remove (lambda (f) (string-prefix-p "." f))
                                        (delete-dups (sort (font-family-list) #'string<)))
                            nil t))))
  (dolist (face faces)
    (set-face-attribute face nil :family family))
  ;; mixed-pitch snapshots font families buffer-locally when enabled,
  ;; so re-toggle it wherever it's on to pick up the new family.
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (bound-and-true-p mixed-pitch-mode)
        (mixed-pitch-mode -1)
        (mixed-pitch-mode 1)))))

;; Window management
;; Split windows sensibly

(setq split-width-threshold 120
      split-height-threshold nil)

;; Keep window sizes balanced

(use-package balanced-windows
  :config
  (balanced-windows-mode))

;; MINIBUFFER COMPLETION

;; Enable vertico

(use-package vertico
  :init
  (vertico-mode)
  :custom
  (vertico-sort-function 'vertico-sort-history-alpha))

(use-package vertico-posframe
  :after vertico
  :custom
  (vertico-posframe-poshandler #'posframe-poshandler-frame-center)
  (vertico-posframe-parameters
   '((left-fringe . 8)
     (right-fringe . 8)))
  :config
  (vertico-posframe-mode 1))

;; Persist history over Emacs restarts.

(use-package savehist
  :init
  (savehist-mode))

;; Search for partial matches in any order

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides
   '((file (styles partial-completion)))))

;; Enable richer annotations using the Marginalia package

(use-package marginalia
  :init
  (marginalia-mode))

(use-package which-key
  :ensure t
  :config
  (which-key-mode 1)
  (setq which-key-idle-delay 0.2))

;; Improved help buffers

(use-package helpful
   :bind
   (("C-h f" . helpful-function)
    ("C-h x" . helpful-command)
    ("C-h k" . helpful-key)
    ("C-h v" . helpful-variable)))

;;; Text mode settings

(use-package text-mode
  :ensure
  nil
  :hook
  (text-mode . visual-line-mode)
  :init
  (delete-selection-mode t)
  :custom
  (sentence-end-double-space nil)
  (scroll-error-top-bottom t)
  (save-interprogram-paste-before-kill t))

;; Check spelling with flyspell and hunspell

;(use-package spell-fu
;:hook
;((text-mode . spell-fu-mode)
; (prog-mode . spell-fu-mode))
;:config
;(setq spell-fu-idle-delay 0.5))

;;; Ricing Org mode

(use-package org
  :custom
  (org-startup-indented t)
  (org-hide-emphasis-markers t)
  (org-startup-with-inline-images t)
  (org-image-actual-width '(450))
  (org-fold-catch-invisible-edits 'error)
  (org-pretty-entities t)
  (org-use-sub-superscripts "{}")
  (org-id-link-to-org-use-id t)
  (org-fold-catch-invisible-edits 'show))

;; RET: follow link in Normal/Motion, plain newline in Insert

(defun fiend/org-open-at-point-in-emacs ()
    "Follow the link at point, forcing it open inside Emacs
(e.g. Dired for a directory) instead of deferring to org-file-apps
or an external/system application."
    (interactive)
    (org-open-at-point '(4)))

  ;; This section tangles early in init.el, well before (use-package evil
  ;; ...) further down - a plain (with-eval-after-load 'org ...) here fires
  ;; as soon as Org loads (which is immediately, a few lines up), which is
  ;; before Evil exists yet. That's a void-function error on
  ;; evil-define-key, and since it's uncaught, everything later in init.el
  ;; never runs - including the dashboard startup-buffer setup and the
  ;; general.el leader-key (SPC) bindings. Confirmed cause of both symptoms
  ;; ("dropped into scratch" + "SPC doesn't work") after tangling the
  ;; previous version of this block. Nesting under 'evil too defers the
  ;; whole thing until *both* are loaded, regardless of which finishes
  ;; loading first or where either block physically sits in the file.
  (with-eval-after-load 'evil
    (with-eval-after-load 'org
      (evil-define-key '(normal motion) org-mode-map
        (kbd "RET") 'fiend/org-open-at-point-in-emacs)))

;; Show hidden emphasis markers

(use-package org-appear
  :hook
  (org-mode . org-appear-mode))

;; LaTeX previews

(use-package org-fragtog
  :after org
  :hook
  (org-mode . org-fragtog-mode)
  :custom
  (org-startup-with-latex-preview nil)
  (org-format-latex-options
   (plist-put org-format-latex-options :scale 2)
   (plist-put org-format-latex-options :foreground 'auto)
   (plist-put org-format-latex-options :background 'auto)))

;; Org modern: Most features are disabled for beginning users

(use-package org-modern
  :hook
  (org-mode . org-modern-mode)
  :custom
  ;; No heading icons: fold arrows swap glyphs on every fold/move and
  ;; trigger system font-fallback lookups (laggy). Plain stars instead.
  (org-modern-star nil)
  (org-modern-table nil)
  (org-modern-keyword nil)
  (org-modern-timestamp nil)
  (org-modern-priority nil)
  (org-modern-checkbox nil)
  (org-modern-tag nil)
  (org-modern-block-name nil)
  (org-modern-keyword nil)
  (org-modern-footnote nil)
  (org-modern-internal-target nil)
  (org-modern-radio-target nil)
  (org-modern-statistics nil)
  (org-modern-progress nil))

;; Consult convenience functions

(use-package consult
  :bind
  (("C-c w h" . consult-org-heading)
   ("C-c w g" . consult-grep)))

;; INSPIRATION

;; Doc-View

(use-package doc-view
  :custom
  (doc-view-resolution 300)
  (large-file-warning-threshold (* 50 (expt 2 20))))

;; PDF Tools (better PDF viewing than DocView)

(use-package pdf-tools
  :config
  (pdf-tools-install)
  (setq pdf-view-display-size 'fit-page)
  ;; Evil-mode keybindings for PDF navigation
  (with-eval-after-load 'evil
    (evil-define-key 'normal pdf-view-mode-map
      (kbd "n") 'pdf-view-next-page
      (kbd "p") 'pdf-view-previous-page
      (kbd "j") 'pdf-view-next-line-or-next-page
      (kbd "k") 'pdf-view-previous-line-or-previous-page
      (kbd "gg") 'pdf-view-first-page
      (kbd "G") 'pdf-view-last-page)))

;; Read ePub files

(use-package nov
  :init
  (add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode)))

;; Reading LibreOffice files

;; Fixing a bug in Org Mode pre-9.7
;; Org mode clobbers associations with office documents

(use-package ox-odt
  :ensure nil
  :config
  (add-to-list 'auto-mode-alist
               '("\\.\\(?:OD[CFIGPST]\\|od[cfigpst]\\)\\'"
                 . doc-view-mode-maybe)))

;; open org links to pdfs in emacs. append (not replace!) so the
;; built-in (auto-mode . emacs) and (directory . emacs) defaults
;; survive - a plain setq here previously wiped them out, which made
;; .org/denote links fall through to org-file-apps-macos's `open`
;; fallback and spawn a whole new Emacs.app window.
(setq org-file-apps
    (append '(("\\.pdf\\'" . find-file))
            org-file-apps))

;; reuse the current window for file-resolving links (this covers
;; denote: links too, since denote-link-ol-follow hands off to
;; org-link-open-as-file) instead of Org's default
;; find-file-other-window split.
(setf (alist-get 'file org-link-frame-setup) 'find-file)

;; Managing Bibliographies
(setq ews-bibtex-directory (expand-file-name "~/jdp/denote-lib/")
      ews-bibtex-files "\\.bib\\'")   ;; regexp, not a list

(use-package bibtex
  :custom
  (bibtex-user-optional-fields
   '(("keywords" "Keywords to describe the entry" "")
     ("file"     "Relative or absolute path to attachments" "" )))
  (bibtex-align-at-equal-sign t)
  :config
  (ews-bibtex-register)
  :bind
  (("C-c w b r" . ews-bibtex-register)))

;; Biblio package for adding BibTeX records

;; :ensure nil - biblioq is no longer on any configured archive
;; (renamed/removed upstream, per Open Issues in CLAUDE.md). With
;; use-package-always-ensure t, leaving :ensure unset meant every
;; startup tried to install it, and package.el's fallback when it
;; can't find a package is a full package-refresh-contents across
;; every archive (melpa/orgmode/gnu/nongnu) before giving up -
;; confirmed 2026-09-21 as the actual cause of a startup that looked
;; hung (multi-minute network refresh, not an infinite loop or
;; anything related to that session's org-agenda/PKB tag changes).
;; This can't break anything currently working, since the package
;; already fails to load every time regardless.
(use-package biblioq
  :ensure nil
  :bind
  (("C-c w b b" . ews-bibtex-biblio-lookup)))

;; Citar to access bibliographies

(use-package citar
  :defer t
  :custom
  (citar-bibliography ews-bibtex-files)
  :bind
  (("C-c w b o" . citar-open)))

;; Read RSS feeds with Elfeed

(use-package elfeed
  :custom
  (elfeed-db-directory
   (expand-file-name "elfeed" user-emacs-directory))
  (elfeed-show-entry-switch 'display-buffer)
  :bind
  ("C-c w e" . elfeed))

;; Configure Elfeed with org mode

(use-package elfeed-org
  :config
  (elfeed-org)
  :custom
  (rmh-elfeed-org-files
   (list (concat (file-name-as-directory (getenv "HOME")) "elfeed.org"))))

;; Easy insertion of weblinks

(use-package org-web-tools
  :bind
  (("C-c w w" . org-web-tools-insert-link-for-url)))

;; Emacs Multimedia System

(use-package emms
  :config
  (require 'emms-setup)
  (require 'emms-mpris)
  (emms-all)
  (emms-default-players)
  (emms-mpris-enable)
  :custom
  (emms-browser-covers #'emms-browser-cache-thumbnail-async)
  :bind
  (("C-c w m b" . emms-browser)
   ("C-c w m e" . emms)
   ("C-c w m p" . emms-play-playlist )
   ("<XF86AudioPrev>" . emms-previous)
   ("<XF86AudioNext>" . emms-next)
   ("<XF86AudioPlay>" . emms-pause)))

(use-package openwith
  :config
  (openwith-mode t)
  :custom
  (openwith-associations nil))

(defvar fiend/base-agenda-files
  ;; conferences.org moved into pkb/ as the conferences hub note
  ;; (2026-10-05), so the pkb/ glob below picks it up - listing it here
  ;; too would only point at a file that no longer exists.
  '("~/jdp/readme.org"
    "~/acropolis/inbox.org"
    "~/acropolis/readme.org")
  "Fixed base org-agenda-files list, independent of the pkb/notes globs
in PKB AGENDA FILES below. Kept as its own variable so that section can
recompute org-agenda-files from scratch (base + fresh globs) without
needing to know or re-derive this list.")

(use-package org
  :custom
  (org-default-notes-file "~/acropolis/inbox.org")
  (org-agenda-files fiend/base-agenda-files)
  ;; finances/assets/health used to be hardcoded here via their stable
  ;; symlinks, but PKB AGENDA FILES (further down) now globs pkb/ directly
  ;; and picks up the real underlying files - keeping both meant those three
  ;; were being scanned twice.
  (org-goto-interface 'outline-path-completion)
  (org-todo-keywords
   '((sequence "TASK(a)" "TODO(t)" "NEXT(n)" "IDEA(i)" "|" "DONE(d)")
     (sequence "HOLD(h)" "WAITING(w)" "DEADLINE(D)" "|" "CANCELLED(c)")))
  ;; Previously undefined, so "someday" etc. had no real identity - they
  ;; only worked because org-agenda-custom-commands (further down)
  ;; happened to hardcode the literal strings. Scoped to the tags this
  ;; 2026-09-21 pkb/ cleanup actually touched, not a full registry -
  ;; other tags (dissertation, service, life, etc.) stay freely-typed.
  (org-tag-alist
   '(("bigpicture" . ?B)
     ("someday" . ?S)
     ("ideation" . ?I)
     ("knowledge" . ?K)
     ("project" . ?P)
     ("media" . ?M)))
  ;; Was unset, so completions were never timestamped - no CLOSED: line on
  ;; any DONE/CANCELLED item so far. 'time adds one automatically (no note
  ;; prompt, just the timestamp) - the prerequisite for the "w" weekly wins
  ;; agenda view below (ORG-SUPER-AGENDA) to have anything to show. Only
  ;; applies going forward; existing DONE items in pkb notes stay
  ;; untouched, so the wins view starts clean from here.
  (org-log-done 'time)
  ;; Replaces the old JDP/Acropolis/Emacs split (which readme file a task
  ;; belonged to). readme.org is no longer the landing zone, so templates
  ;; are keyed by the same category tags as the super-agenda dashboard and
  ;; pkb filenames instead - one shared vocabulary. Tagging correctly at
  ;; capture time means an item shows up in the right dashboard group
  ;; immediately, even before it's been processed out of inbox.org.
  ;;
  ;; "t" = task capture (quick actionable item, stays in inbox.org, tagged).
  ;; "n" = note capture (reference material, not a task - creates a real
  ;; Denote note in pkb/ directly via denote-org-capture, bypasses inbox.org
  ;; entirely). Bibliographic notes stay separate via citar-open/citar-create-note,
  ;; untouched here.
  (org-capture-templates
   '(("t" "Task")
     ("td" "Dissertation" entry
      (file+olp "~/acropolis/inbox.org" "1) Process inbox" "Captured task pile")
      "** TODO %? :dissertation:")
     ("ts" "Service" entry
      (file+olp "~/acropolis/inbox.org" "1) Process inbox" "Captured task pile")
      "** TODO %? :service:")
     ("tl" "Life Admin" entry
      (file+olp "~/acropolis/inbox.org" "1) Process inbox" "Captured task pile")
      "** TODO %? :life:")
     ("te" "Teaching" entry
      (file+olp "~/acropolis/inbox.org" "1) Process inbox" "Captured task pile")
      "** TODO %? :teaching:")
     ("tt" "Tools" entry
      (file+olp "~/acropolis/inbox.org" "1) Process inbox" "Captured task pile")
      "** TODO %? :tool:")
     ("tj" "Journal" entry
      (file+olp "~/acropolis/inbox.org" "1) Process inbox" "Captured task pile")
      "** TODO %? :journal:")
     ("tm" "Media" entry
      (file+olp "~/acropolis/inbox.org" "1) Process inbox" "Captured task pile")
      "** TODO %? :media:someday:")
     ("tg" "Magic the Gathering" entry
      (file+olp "~/acropolis/inbox.org" "1) Process inbox" "Captured task pile")
      "** TODO %? :mtg:")
     ("tf" "Fishing" entry
      (file+olp "~/acropolis/inbox.org" "1) Process inbox" "Captured task pile")
      "** TODO %? :fishing:")
     ("tc" "Cooking" entry
      (file+olp "~/acropolis/inbox.org" "1) Process inbox" "Captured task pile")
      "** TODO %? :cooking:")
     ("th" "Home Server" entry
      (file+olp "~/acropolis/inbox.org" "1) Process inbox" "Captured task pile")
      "** TODO %? :homeserver:")
     ("n" "Note (Denote)")
     ;; Bug fix: org-capture-templates entries need a TEMPLATE slot between
     ;; the TARGET and the properties plist, even when the target function
     ;; generates its own content. It was missing, so :no-save (meant to be
     ;; a property) was being read as the template argument instead,
     ;; shifting everything after it out of plist alignment - hence "Wrong
     ;; type argument: plistp". The `nil` below is that missing slot.
     ;;
     ;; Still prompts for title/keywords manually, doesn't pre-fill the
     ;; category tag yet - noted as a possible later refinement.
     ("nk" "Knowledge" plain (function denote-org-capture) nil
      :no-save t :immediate-finish nil :kill-buffer t :jump-to-captured t)
     ("ni" "Ideation" plain (function denote-org-capture) nil
      :no-save t :immediate-finish nil :kill-buffer t :jump-to-captured t)
     ("nw" "Writing" plain (function denote-org-capture) nil
      :no-save t :immediate-finish nil :kill-buffer t :jump-to-captured t))))

;; SPC o c: drop straight into Insert state

(add-hook 'org-capture-mode-hook #'evil-insert-state)

;; org-checklist (checkbox reset on repeat)

(use-package org-contrib
  :ensure t)
(require 'org-checklist)

;; Denote

;; denote-link-or-create creates a new note (when your input doesn't match
;; an existing one) directly in whatever denote-directory currently is -
;; which is the denote-lib/ root (custom.el), not pkb/. That's how a note
;; created via C-c w d i ended up sitting next to notes/ instead of inside
;; pkb/. Same "silo" rebind used by fiend/pkb-extract-subtree-to-note
;; (SPC p n), just wrapped around the stock command instead of a
;; from-scratch one. pkb/ vs notes/ vs any further split is still an open
;; question (see redesign tasks) - this just makes "create a new linked
;; note" default somewhere sane in the meantime. denote-insert-link
;; (C-c w d l) is untouched since it only links to notes that already
;; exist, so it never had anywhere wrong to create anything.
(defun fiend/pkb-link-or-create ()
  "Like `denote-link-or-create', but any newly created note lands in pkb/."
  (interactive)
  (let ((denote-directory (expand-file-name "pkb/" (denote-directory))))
    (call-interactively #'denote-link-or-create)))

(use-package denote
  :defer t
  :custom
  (denote-sort-keywords t)
  :hook
  (dired-mode . denote-dired-mode)
  :custom-face
  (denote-faces-link ((t (:slant italic))))
  :init
  (require 'denote-org-extras)
  :bind
  (("C-c w d b" . denote-find-backlink)
   ("C-c w d d" . denote-date)
   ("C-c w d f" . denote-find-link)
   ("C-c w d h" . denote-org-extras-link-to-heading)
   ("C-c w d i" . fiend/pkb-link-or-create)
   ("C-c w d k" . denote-rename-file-keywords)
   ("C-c w d l" . denote-insert-link)
   ("C-c w d n" . denote-subdirectory)
   ("C-c w d r" . denote-rename-file)
   ("C-c w d R" . denote-rename-file-using-front-matter)))

;; Consult-Notes for easy access to notes

(use-package consult-notes
  :bind
  (("C-c w f"   . consult-notes)
   ("C-c w d g" . consult-notes-search-in-all-notes))
  :init
  (consult-notes-denote-mode))

;; Citar-Denote to manage literature notes

(use-package citar-denote
  :custom
  (citar-open-always-create-notes t)
  :init
  (citar-denote-mode)
  :bind
  (("C-c w b c" . citar-create-note)
   ("C-c w b n" . citar-denote-open-note)
   ("C-c w b x" . citar-denote-nocite)
   :map org-mode-map
   ("C-c w b k" . citar-denote-add-citekey)
   ("C-c w b K" . citar-denote-remove-citekey)
   ("C-c w b d" . citar-denote-dwim)
   ("C-c w b e" . citar-denote-open-reference-entry)))

;; Explore and manage your Denote collection

(use-package denote-explore
  :bind
  (;; Statistics
   ("C-c w x c" . denote-explore-count-notes)
   ("C-c w x C" . denote-explore-count-keywords)
   ("C-c w x b" . denote-explore-barchart-keywords)
   ("C-c w x e" . denote-explore-barchart-filetypes)
   ;; Random walks
   ("C-c w x r" . denote-explore-random-note)
   ("C-c w x l" . denote-explore-random-link)
   ("C-c w x k" . denote-explore-random-keyword)
   ("C-c w x x" . denote-explore-random-regex)
   ;; Denote Janitor
   ("C-c w x d" . denote-explore-identify-duplicate-notes)
   ("C-c w x z" . denote-explore-zero-keywords)
   ("C-c w x s" . denote-explore-single-keywords)
   ("C-c w x o" . denote-explore-sort-keywords)
   ("C-c w x w" . denote-explore-rename-keyword)
   ;; Visualise denote
   ("C-c w x n" . denote-explore-network)
   ("C-c w x v" . denote-explore-network-regenerate)
   ("C-c w x D" . denote-explore-degree-barchart)))

;; Set some Org mode shortcuts

(use-package org
  :bind
  (:map org-mode-map
        ("C-c w n" . ews-org-insert-notes-drawer)
        ("C-c w p" . ews-org-insert-screenshot)
        ("C-c w c" . ews-org-count-words)))

;; Distraction-free writing

(use-package olivetti
  :demand t
  :bind
  (("C-c w o" . ews-olivetti)))

;; Undo Tree

(use-package undo-tree
  :config
  (global-undo-tree-mode)
  :custom
  (undo-tree-auto-save-history nil)
  :bind
  (("C-c w u" . undo-tree-visualise)))

;; Export citations with Org Mode

(require 'oc-natbib)
(require 'oc-csl)

(setq org-cite-global-bibliography ews-bibtex-files
      org-cite-insert-processor 'citar
      org-cite-follow-processor 'citar
      org-cite-activate-processor 'citar
      
;; Always use natbib + chicago-doi for LaTeX export
      org-cite-export-processors
      '((latex natbib "chicago-doi")
        (t basic)))

;; Lookup words in the online dictionary

(use-package dictionary
  :custom
  (dictionary-server "dict.org")
  :bind
  (("C-c w s d" . dictionary-lookup-definition)))

(use-package powerthesaurus
  :bind
  (("C-c w s p" . powerthesaurus-transient)))

;; Writegood-Mode for weasel words, passive writing and repeated word detection

(use-package writegood-mode
  :bind
  (("C-c w s r" . writegood-reading-ease)
   ("C-c w s l" . writegood-grade-level))
  :hook
  (text-mode . writegood-mode))

;; Titlecasing

(use-package titlecase
  :custom
  (titlecase-style 'apa)
  :bind
  (("C-c w s t" . titlecase-dwim)
   ("C-c w s c" . ews-org-headings-titlecase)))

;; Abbreviations

(add-hook 'text-mode-hook 'abbrev-mode)

;; Lorem Ipsum generator

(use-package lorem-ipsum
  :custom
  (lorem-ipsum-list-bullet "- ") ;; Org mode bullets
  :init
  (setq lorem-ipsum-sentence-separator
        (if sentence-end-double-space "  " " "))
  :bind
  (("C-c w s i" . lorem-ipsum-insert-paragraphs)))

;; ediff

(use-package ediff
  :ensure nil
  :custom
  (ediff-keep-variants nil)
  (ediff-split-window-function 'split-window-horizontally)
  (ediff-window-setup-function 'ediff-setup-windows-plain))

(use-package fountain-mode)

(use-package markdown-mode)

;; Generic Org Export Settings

(use-package org
  :custom
  (org-export-with-drawers nil)
  (org-export-with-todo-keywords nil)
  (org-export-with-broken-links t)
  (org-export-with-toc nil)
  (org-export-with-smart-quotes t)
  (org-export-date-timestamp-format "%e %B %Y"))

;; epub export

(use-package ox-epub
  :demand t
  :init
  (require 'ox-org))

;; LaTeX PDF Export settings

(require 'ox)          ;; Core Org export framework
(require 'ox-beamer)   ;; Beamer backend (Org -> LaTeX Beamer

(use-package ox-latex
  :ensure nil
  :demand t
  :custom
  ;; Multiple LaTeX passes for bibliographies
  (org-latex-pdf-process
   '("pdflatex -interaction nonstopmode -output-directory %o %f"
     "bibtex %b"
     "pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"
     "pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"))
  ;; Clean temporary files after export
  (org-latex-logfiles-extensions
   (quote ("lof" "lot" "tex~" "aux" "idx" "log" "out"
           "toc" "nav" "snm" "vrb" "dvi" "fdb_latexmk"
           "blg" "brf" "fls" "entoc" "ps" "spl" "bbl"
           "tex" "bcf"))))

;; dark mode (via srey)
  (use-package pdf-tools
    :defer t
    :config
    (pdf-tools-install :no-query)
    (add-hook 'pdf-view-mode-hook #'my/pdf-dark-mode-by-time)
    (define-key pdf-view-mode-map (kbd "M-d") #'pdf-view-midnight-minor-mode))

  ;; Custom function for dark PDF mode
(defun my/pdf-dark-mode-by-time ()
(let* ((hour (string-to-number (format-time-string "%H")))
       (night (or (< hour 7) (>= hour 18))))
  (setq-local pdf-view-midnight-colors '("#f8f8f2" . "#282a36"))
  (message "[pdf-dark] hour=%s night=%s tz=%s" hour night (format-time-string "%Z"))
  (pdf-view-midnight-minor-mode (if night 1 -1))))


(setq TeX-view-program-selection '((output-pdf "PDF Tools"))
      TeX-source-correlate-start-server t)

;; Optional: use C-c C-v to open PDF in same window
(add-hook 'TeX-after-compilation-finished-functions
          #'TeX-revert-document-buffer)

;;sync - click in the pdf to return to the spot in the org file
(setq TeX-command-extra-options "-shell-escape -synctex=1")

;; EWS paperback configuration

(with-eval-after-load 'ox-latex
  (add-to-list
   'org-latex-classes
   '("ews"
     "\\documentclass[11pt, twoside]{memoir}
      \\setstocksize{9.25in}{7.5in}
      \\settrimmedsize{\\stockheight}{\\stockwidth}{*}
      \\setlrmarginsandblock{2cm}{1cm}{*} 
      \\setulmarginsandblock{1.5cm}{2.25cm}{*}
      \\checkandfixthelayout
      \\setcounter{tocdepth}{0}
      \\OnehalfSpacing
      \\usepackage{ebgaramond}
      \\usepackage[htt]{hyphenat}
      \\chapterstyle{bianchi}
      \\setsecheadstyle{\\normalfont \\raggedright \\textbf}
      \\setsubsecheadstyle{\\normalfont \\raggedright \\textbf}
      \\setsubsubsecheadstyle{\\normalfont\\centering}
      \\usepackage[font={small, it}]{caption}
      \\pagestyle{myheadings}
      \\usepackage{ccicons}
      \\usepackage[authoryear]{natbib}
      \\bibliographystyle{apalike}
      \\usepackage{svg}"
     ("\\chapter{%s}" . "\\chapter*{%s}")
     ("\\section{%s}" . "\\section*{%s}")
     ("\\subsection{%s}" . "\\subsection*{%s}")
     ("\\subsubsection{%s}" . "\\subsubsection*{%s}"))))

;;; ADMINISTRATION

;; Bind org agenda command and custom agenda

(use-package org
  :custom
  (org-agenda-custom-commands
   '(("e" "Agenda, next actions and waiting"
      ((agenda "" ((org-agenda-overriding-header "Next three days:")
                   (org-agenda-span 3)
                   (org-agenda-start-on-weekday nil)))
       (todo "NEXT" ((org-agenda-overriding-header "Next Actions:")))
       (todo "WAITING" ((org-agenda-overriding-header "Waiting:")))))))
  :bind
  (("C-c a" . org-agenda)))

;; FILE MANAGEMENT

;; Enable GNU ls if installed
(when (executable-find "gls")
  (setq insert-directory-program "gls"))
  
  (use-package dired
    :ensure
    nil
    :commands
    (dired dired-jump)
    :custom
    (dired-listing-switches
     "-goah --group-directories-first --time-style=long-iso")
    (dired-dwim-target t)
    (delete-by-moving-to-trash t)
    :init
    (put 'dired-find-alternate-file 'disabled nil))

;; Hide hidden files

(use-package dired
  :ensure nil
  :hook (dired-mode . dired-omit-mode)
  :bind (:map dired-mode-map
              ( "."     . dired-omit-mode))
  :custom (dired-omit-files "^\\.[a-zA-Z0-9]+"))

;; Backup files

(setq-default backup-directory-alist
              `(("." . ,(expand-file-name "backups/" user-emacs-directory)))
              version-control t
              delete-old-versions t
              create-lockfiles nil)

;; Recent files

(use-package recentf
  :config
  (recentf-mode t)
  :custom
  (recentf-max-saved-items 50)
  :bind
  (("C-c w r" . recentf-open)))

;; Bookmarks

(use-package bookmark
  :custom
  (bookmark-save-flag 1)
  :bind
  ("C-x r d" . bookmark-delete))

;; Image viewer

(use-package emacs
  :custom
  (image-dired-external-viewer "gimp")
  :bind
  ((:map image-mode-map
         ("k" . image-kill-buffer)
         ("<right>" . image-next-file)
         ("<left>"  . image-previous-file))
   (:map dired-mode-map
         ("C-<return>" . image-dired-dired-display-external))))

(use-package image-dired
  :bind
  (("C-c w I" . image-dired))
  (:map image-dired-thumbnail-mode-map
        ("C-<right>" . image-dired-display-next)
        ("C-<left>"  . image-dired-display-previous)))

;; ADVANCED UNDOCUMENTED EXPORT SETTINGS FOR EWS

;; Use GraphViz for flow diagrams
;; requires GraphViz software
;; D2 diagrams (added 2026-09-30, for linux_box/wiki/homeserver-map.org):
;; ob-d2 from MELPA + the d2 binary at /usr/local/bin/d2. GUI Emacs
;; doesn't inherit the shell PATH, so add /usr/local/bin explicitly.
;; Each org-babel-do-load-languages call *replaces* the language list,
;; so python (also set in the python interpreter block) is repeated here.
(use-package ob-d2)
(add-to-list 'exec-path "/usr/local/bin")
(org-babel-do-load-languages
 'org-babel-load-languages
 '((python . t)
   (dot . t)    ; GraphViz dot
   (d2 . t)))   ; D2 (ob-d2)

(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(setq display-line-numbers-type 'relative
    display-line-numbers-width 3)

(add-to-list 'load-path (expand-file-name "fiend_tools" user-emacs-directory))
(require 'my-pkb-picker)

(use-package evil
  :ensure t
  :init
  (setq evil-want-keybinding nil)
  (setq evil-want-integration t)
  :config
  (evil-mode 1)
  (evil-define-key 'insert evil-insert-state-map (kbd "C-g") 'evil-normal-state)
  (evil-define-key 'insert evil-insert-state-map (kbd "C-h") 'evil-delete-backward-char-and-join)
  (evil-set-initial-state 'messages-buffer-mode 'normal)
;; Use visual line motions even outside of visual-line-mode buffers
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)
  (evil-set-initial-state 'messages-buffer-mode 'normal)
  (evil-set-initial-state 'dashboard-mode 'normal))

(use-package evil-commentary
:ensure t
:after evil
:bind (:map evil-normal-state-map
  ("gc" . evil-commentary))) 

;evil collection enables evil keybindings globally
(use-package evil-collection
:after evil
:init
;; evil-collection's dired normal-state keys shadow two of mine:
;; SPC -> dired-next-line (blocks the leader) and "." ->
;; dired-clean-directory (blocks the dired-omit-mode dotfile toggle).
;; The setup hook runs after its keys are bound, so these win. Added
;; in :init because dired may already be loaded when init runs.
(add-hook 'evil-collection-setup-hook
          (lambda (mode &rest _)
            (when (eq mode 'dired)
              (evil-collection-define-key 'normal 'dired-mode-map
                (kbd "SPC") nil
                "." 'dired-omit-mode))))
:config
(evil-collection-init))

;; need this to make evil-undo work
(use-package undo-tree
:ensure t
:after evil
:diminish
:config
(evil-set-undo-system 'undo-tree)
(global-undo-tree-mode 1))

(use-package magit
  :ensure t)

(use-package general
  :ensure t
  :after evil
  :config
  (general-evil-setup t)

  (general-create-definer fiend/leader-keys
    :states '(normal visual motion emacs)
    :prefix "SPC"
    :global-prefix "C-SPC")

  ;; Leader bindings go here 
  (fiend/leader-keys
    "t"  '(:ignore t :which-key "toggles")
    "tt" '(counsel-load-theme :which-key "choose theme")
    "w"  '(evil-window-map :which-key "window")
    "."  '(counsel-find-file :which-key "find file")
    "b"  '(:ignore t :which-key "bookmark")
    "bb" '(bookmark-bmenu-list :which-key "list")
    "bm" '(bookmark-set :which-key "set")
    "bd" '(bookmark-delete :which-key "delete")
    "br" '(bookmark-rename :which-key "rename")
    "d" '(dired :which-key "dired")
    "g" '(magit-status :which-key "magit")
    "ts" '(hydra-text-scale/body :which-key "scale text")
    "tf" '(fiend/set-font :which-key "set font")
    "o"  '(hydra-org/body :which-key "org")
    "f" '(hydra-file/body :which-key "file")
    "p"  '(hydra-pkb/body :which-key "pkb")
    "c"   '(:ignore t :which-key "citar")
    "cc"  '(citar-insert-citation :which-key "insert citation")
    "cn" '(citar-denote-open-note :which-key "open note")
    "e"  '(ellama-transient-main-menu :which-key "ellama-menu")
    "x"  '(hydra-system/body :which-key "system")))

;; SPC x - system-level actions, one extra step past SPC R so a stray
;; keypress can't restart/quit Emacs by accident.
(use-package restart-emacs
  :ensure t)

(defun fiend/tangle-and-restart ()
  "Tangle fiend_ews.org into init.el, then restart Emacs."
  (interactive)
  (org-babel-tangle-file (expand-file-name "fiend_ews.org" user-emacs-directory))
  (restart-emacs))

(defhydra hydra-system (:timeout 4)
  "system"
  ("r" fiend/tangle-and-restart "tangle + restart")
  ("s" save-some-buffers "save all buffers")
  ("q" save-buffers-kill-terminal "quit emacs")
  ("d" toggle-debug-on-error "toggle debug-on-error")
  ("p" package-list-packages "list packages"))

(defun fiend/evil-hook ()
(dolist (mode '(custom-mode
	eshell-mode
	git-rebase-mode
	erc-mode
	circe-server-mode
	circe-chat-mode
	circe-query-mode
	sauron-mode
	term-mode))
(add-to-list 'evil-emacs-state-modes mode)))

;; Ivy provides some improved functionality for certain commands
   ;; ivy-mode disabled 2026-09-03: was running simultaneously with
   ;; vertico-mode (MINIBUFFER COMPLETION section), each claiming the
   ;; default completing-read-function - only one can own that at a time.
   ;; Every binding below (swiper, counsel-*) still works unchanged, since
   ;; they call ivy-read directly and don't require ivy-mode to be active
   ;; globally; only plain, un-remapped completing-read calls elsewhere now
   ;; render via vertico instead of ivy.
   (use-package ivy
   ;; :config (ivy-mode 1)
   :bind (("C-s" . swiper)
   :map ivy-minibuffer-map
   ("TAB" . ivy-alt-done)
   ("C-l" . ivy-alt-done)
   ("C-j" . ivy-next-line)
   ("C-k" . ivy-previous-line)
   :map ivy-switch-buffer-map
   ("C-k" . ivy-previous-line)
   ("C-l" . ivy-done)
   ("C-d" . ivy-switch-buffer-kill)
   :map ivy-reverse-i-search-map
   ("C-k" . ivy-previous-line)
   ("C-d" . ivy-reverse-i-search-kill)))

   ;; ivy rich gives details and keybindings in the command buffer
   (use-package ivy-rich
   :init
   (ivy-rich-mode 1))

  ;; AMX tracks the history of commands and ranks them
  (use-package amx
    :ensure t
    :after ivy
    :custom
    (amx-backend 'auto)
    (amx-save-file "~/.emacs.d/amx-items")
    (amx-history-length 50)
    (amx-show-keybindings nil)
    :config
    (amx-mode 1))

   ;; counsel has some functionality wth ivy
   (use-package counsel
   :bind (("M-x" . counsel-M-x)
   ("C-x b" . counsel-ibuffer)
   ("C-x C-f" . counsel-find-file)
   :map minibuffer-local-map
   ("C-r" . 'counsel-minibuffer-history)))

  ;; reposition ivy's window inside an emacs frame. adjust properties of frames
  (use-package ivy-posframe
  :ensure t
  :delight
  :custom
  (ivy-posframe-height-alist
    '((swiper . 15)
    (t . 10)))
  (ivy-posframe-display-functions-alist
    '((complete-symbol . ivy-posframe-display-at-point)
      (counsel-describe-function . nil)
      (counsel-describe-variable . nil)
      (swiper . nil)
      (swiper-isearch . nil)
      (t . ivy-posframe-display-at-frame-center)))
   :config
   (ivy-posframe-mode 1))

(setq ivy-posframe-parameters
      '((left-fringe . 8)
        (right-fringe . 8)))

(use-package hydra)

   ;; Resize text function
   (defhydra hydra-text-scale (:timeout 4)
   "scale text"
   ("j" text-scale-increase "in")
   ("k" text-scale-decrease "out")
   ("f" nil "finished" :exit t))

  ;; Org agenda split
   (defhydra hydra-org (:timeout 4)
   "org agenda"
   ("c" org-capture "capture")
   ("a" org-agenda "agenda")
   ;; "x" mirrors the "x" already in C-c C-x C-a - same mnemonic, much
   ;; shorter chord: SPC o x instead of the full four-key sequence.
   ("x" org-archive-subtree "archive")
   ("i" fiend/jump-to-inbox "inbox"))

   ;; Org file split
   (defhydra hydra-file (:timeout 4)
   "file"
   ("r" counsel-recentf "recent")
   ("s" save-buffer "save")
   ("." find-file "find"))

  ;; PKB menu
(defhydra hydra-pkb (:timeout 4)
  "pkb"
  ("p" fiend/pkb-pick-by-title "picker (title)")
  ("t" my/pkb-pick-by-tag "picker (tag)")
  ("n" fiend/pkb-extract-subtree-to-note "new note")
  ("f" fiend/pkb-refile-to-top "file in note")
  ("g" consult-notes-search-in-all-notes "search text")
  ("v" fiend/pkb-transcribe-video "transcribe video"))



;; Inbox-zero nudge: counts everything still nested under inbox.org's
  ;; "Captured task pile" heading, regardless of TODO state or tag. Defined
  ;; before the dashboard package loads since it's a plain function - the
  ;; body only runs once the dashboard actually renders.
  (defun fiend/inbox-unprocessed-count ()
    "Count headlines nested under \"Captured task pile\" in inbox.org.
Returns 0 if the file or heading can't be found."
    (let ((file (expand-file-name "~/acropolis/inbox.org")))
      (if (not (file-exists-p file))
          0
        (with-current-buffer (find-file-noselect file)
          (org-with-wide-buffer
           (goto-char (point-min))
           (if (re-search-forward "^\\*+ .*Captured task pile" nil t)
               (let ((subtree-end (save-excursion
                                     (org-back-to-heading t)
                                     (org-end-of-subtree t t)
                                     (point))))
                 (count-matches "^\\*+ " (line-end-position) subtree-end))
             0))))))

  (defun fiend/jump-to-inbox ()
    "Open inbox.org at the Captured task pile heading, ready to process."
    (interactive)
    (find-file (expand-file-name "~/acropolis/inbox.org"))
    (goto-char (point-min))
    (when (re-search-forward "^\\*+ .*Captured task pile" nil t)
      (org-back-to-heading t)
      (org-show-subtree)))

  (defun fiend/dashboard-insert-inbox (list-size)
    "Dashboard section nagging toward inbox zero."
    (let ((count (fiend/inbox-unprocessed-count)))
      (dashboard-insert-heading "Inbox" nil)
      (insert "\n    ")
      (if (> count 0)
          (insert (propertize
                   (format "%d unprocessed item%s waiting - SPC o i to process"
                           count (if (= count 1) "" "s"))
                   'face 'warning))
        (insert (propertize "inbox zero" 'face 'success)))))

  (use-package dashboard
    :ensure t
    :init
    (setq dashboard-banner-logo-title "SEE YOU SPACE COWBOY")
    (setq dashboard-startup-banner "~/.emacs.d/gengar.png") ;; path to your image
    (setq dashboard-center-content t)
    ;; Inbox first: it's meant to be the first thing you see on startup,
    ;; priming the inbox-zero habit before recents pull focus elsewhere.
    ;; "agenda" dropped 2026-09-21: dashboard-insert-agenda scans all of
    ;; org-agenda-files (244 files as of this pkb/ cleanup) unconditionally
    ;; at every startup via dashboard-setup-startup-hook - confirmed via
    ;; *Messages* (files being visited, auto-save warnings) and a stack
    ;; sample (heavy buffer/text-property scanning) as the actual source
    ;; of a startup that looked hung, once the separate biblioq network-
    ;; refresh issue (see that use-package block) was ruled out. Since
    ;; fiend/refresh-agenda-files is already advised onto org-agenda
    ;; itself, dropping this widget makes the real scan lazy for free -
    ;; it only runs the first time org-agenda is actually invoked, not on
    ;; every startup regardless of whether the agenda gets looked at.
    (setq dashboard-items '((inbox   . 1)
                          (recents . 5)))
    ;; dashboard-footer-messages normally shows a random pick from a list of
    ;; joke quotes at the bottom - one message means the "random" pick is
    ;; always this one, giving a permanent on-screen reminder instead.
    (setq dashboard-footer-messages
          '("[a] peek at agenda   [A] full agenda dashboard"))
    :config
    (add-to-list 'dashboard-item-generators '(inbox . fiend/dashboard-insert-inbox))
    (dashboard-setup-startup-hook))
  (add-hook 'emacs-startup-hook
            (lambda ()
              (switch-to-buffer "*dashboard*")))

  ;; From the dashboard's agenda preview, `a` still jumps to that section to
  ;; browse/select a single truncated TODO (dashboard-item-shortcuts
  ;; default). `A` (capital) instead jumps straight into the full grouped
  ;; org-super-agenda dashboard (the "d" custom command) - the live,
  ;; editable buffer rather than the read-only preview.
  (defun fiend/dashboard-jump-to-super-agenda ()
    "From the dashboard, open the full grouped org-agenda dashboard."
    (interactive)
    (org-agenda nil "d"))

  ;; Plain define-key covers Emacs state. But if dashboard-mode ends up in
  ;; Evil's normal/motion state (evil-collection covers dashboard-mode),
  ;; Evil's own global binding for capital A (evil-append-line) sits above
  ;; the major-mode map and wins instead - same precedence issue as the
  ;; org-agenda j/k fix, just needing evil-define-key here rather than a
  ;; plain one. Bind both so it works regardless of which state Evil lands
  ;; the buffer in.
  (define-key dashboard-mode-map (kbd "A") #'fiend/dashboard-jump-to-super-agenda)
  (with-eval-after-load 'evil
    (evil-define-key '(normal motion) dashboard-mode-map
      (kbd "A") #'fiend/dashboard-jump-to-super-agenda))

;; Ellama's optional mode-line spinner dependency.
(use-package spinner
  :ensure t
  :demand t)

(use-package ellama
  :ensure t
  :after spinner
  :bind ("C-c e" . ellama)
  :hook (org-ctrl-c-ctrl-c-hook . ellama-chat-send-last-message)

  :custom
  ;; Show activity while Ellama is waiting for model output.
  (ellama-spinner-enabled t)
  (ellama-spinner-type 'progress-bar)

  :init
  (require 'llm-ollama)
  (setopt ellama-provider
          (make-llm-ollama
           :chat-model "llama3.1:latest"
           :embedding-model "nomic-embed-text"))

  :config
  ;; Agent defaults for long coding sessions: enable tools, compact old
  ;; context, show sub-agent buffers, enforce DLP, block irreversible actions,
  ;; and give agent loops enough steps to finish real work.
  (ellama-setup-agentic-coding)

  ;; With an SRT policy, normal tool confirmations are skipped, ordinary DLP
  ;; input findings are allowed, output findings are redacted, and
  ;; irreversible actions are still blocked. Without SRT, confirmations stay
  ;; active and ordinary DLP input/output findings ask first.
  ;; (ellama-setup-agentic-coding
  ;;  "~/.config/ellama/srt-autonomous.json")

  (ellama-context-header-line-global-mode +1)
  (ellama-session-header-line-global-mode +1))

(defun fiend/pkb-org-files ()
    "Real (non-symlink, non-lockfile) pkb notes for org-agenda-files."
    (seq-remove #'file-symlink-p
                (directory-files "~/jdp/denote-lib/pkb/" t "^[^.#].*\\.org\\'")))

  (defun fiend/bib-org-files ()
    "Real (non-symlink, non-lockfile) bibliographic notes for org-agenda-files.
Not currently called from fiend/refresh-agenda-files - notes/ was
dropped from org-agenda-files 2026-09-21 (own the prose above this
source block for why). Left defined so re-enabling it later is a
one-line change in that function, not a rewrite."
    (seq-remove #'file-symlink-p
                (directory-files "~/jdp/denote-lib/notes/" t "^[^.#].*\\.org\\'")))

  (defun fiend/refresh-agenda-files (&rest _)
    "Recompute org-agenda-files from the base list plus current pkb/
directory contents. Previously this glob only ran once at Emacs
startup (a plain setq/append), so org-agenda-files went stale for the
rest of the session whenever a pkb/ file was renamed, added, or
deleted after startup - confirmed 2026-09-18 when a pkb file rename
didn't show up in org-agenda until this was fixed. Resets fully from
fiend/base-agenda-files each time rather than appending onto whatever
org-agenda-files already was, so repeated calls don't accumulate
duplicates. notes/ (fiend/bib-org-files) dropped 2026-09-21 - see that
function's docstring."
    (setq org-agenda-files (append fiend/base-agenda-files (fiend/pkb-org-files))))

  (fiend/refresh-agenda-files)
  (advice-add 'org-agenda :before #'fiend/refresh-agenda-files)

  ;; Visible progress while org-agenda scans org-agenda-files - added
  ;; 2026-09-21 because a multi-file scan (even the ~69-file pkb/-only
  ;; scan, post notes/ removal above) gives no feedback otherwise, which
  ;; is indistinguishable from a real hang. org-agenda-prepare-buffers
  ;; (defined in org.el, not org-agenda.el) loops over org-agenda-files
  ;; calling org-check-agenda-file once per file with no batching - the
  ;; same function behind the "[R]emove from list" prompt from the
  ;; org-agenda-files bug earlier this session - so it's a reliable
  ;; once-per-file tick point without needing to touch org's own loop.
  (defvar fiend/agenda-progress--reporter nil)
  (defvar fiend/agenda-progress--n 0)

  (defun fiend/agenda-progress-start (files)
    (setq fiend/agenda-progress--reporter
          (make-progress-reporter "Scanning agenda files..." 0 (length files))
          fiend/agenda-progress--n 0))

  (defun fiend/agenda-progress-tick (&rest _)
    (when fiend/agenda-progress--reporter
      (setq fiend/agenda-progress--n (1+ fiend/agenda-progress--n))
      (progress-reporter-update fiend/agenda-progress--reporter
                                 fiend/agenda-progress--n)))

  (defun fiend/agenda-progress-done (&rest _)
    (when fiend/agenda-progress--reporter
      (progress-reporter-done fiend/agenda-progress--reporter)
      (setq fiend/agenda-progress--reporter nil)))

  (advice-add 'org-agenda-prepare-buffers :before #'fiend/agenda-progress-start)
  (advice-add 'org-check-agenda-file :before #'fiend/agenda-progress-tick)
  (advice-add 'org-agenda-prepare-buffers :after #'fiend/agenda-progress-done)

(setq org-agenda-prefix-format
      '((agenda  . " %i %?-12t% s")
        (timeline . " % s")
        (todo    . " %i")
        (tags    . " %i")
        (search  . " %i")))

(setq org-refile-targets
        '((fiend/pkb-org-files :maxlevel . 1)))

  ;; Plain headline text in completion, no file-path prefix - denote
  ;; filenames are long, and the headline itself is already the useful part
  ;; (typing "aag" surfaces "TASK AAG 2027" directly).
  (setq org-refile-use-outline-path nil
        org-outline-path-complete-in-steps nil
        org-refile-allow-creating-parent-nodes 'confirm)

  (defun fiend/pkb-candidates ()
    "Alist of (title . file) for every pkb note. Reuses
`my/pkb--title-for-display' from my-pkb-picker (#+title: front matter,
falling back to the denote filename title) - same lookup the SPC p p
title picker uses, so both stay in sync and stay stable no matter how
many :new: headings pile up at the top of a file."
    (mapcar (lambda (f) (cons (my/pkb--title-for-display f) f))
            (my/pkb--all-files)))

  (defun fiend/pkb-pick-by-title ()
    "Jump straight to a pkb note by title (SPC p p). Complements
`my/pkb-pick-by-tag' (SPC p t), which narrows by tag instead."
    (interactive)
    (let* ((candidates (fiend/pkb-candidates))
           (choice (completing-read "PKB note: " candidates nil t)))
      (find-file (cdr (assoc choice candidates)))))

  (defun fiend/pkb-refile-to-top ()
    "Cut the subtree at point and file it into an existing pkb note as a
new H1 at the very top of the file, tagged :new:. Meant to be triaged into
the note's real structure during a later review pass, then have the :new:
tag dropped."
    (interactive)
    (unless (org-at-heading-p) (org-back-to-heading t))
    (let* ((candidates (fiend/pkb-candidates))
           (choice (completing-read "File into pkb note: " candidates nil t))
           (target-file (cdr (assoc choice candidates))))
      (org-cut-subtree)
      (with-current-buffer (find-file-noselect target-file)
        (org-with-wide-buffer
         (goto-char (point-min))
         (when (re-search-forward "^\\* " nil t)
           (beginning-of-line))
         (org-paste-subtree 1)
         (org-back-to-heading t)
         (org-set-tags (delete-dups (cons "new" (org-get-tags nil t)))))
        (save-buffer))))

  ;; Refiled items were landing as the last child of the target headline,
  ;; buried behind the whole existing subtree - easy to miss without fully
  ;; expanding the note. Scoped to pkb/ paths only, so org-capture into
  ;; inbox.org's Captured task pile keeps its existing append-at-bottom
  ;; order. Now only relevant if you reach for plain org-refile directly
  ;; (see note above) rather than SPC p f.
  (setq org-reverse-note-order '(("/pkb/" . t)))

  ;; Video transcription - runs whisper inside the media-tools conda env
  ;; via `conda run', so no manual `conda activate' step is ever needed.
  ;; media-tools lives outside Homebrew entirely (Xcode on this machine is
  ;; too outdated for Homebrew's current bottles - confirmed via the App
  ;; Store itself reporting "not compatible with this machine", not just
  ;; the brew warning) - conda-forge ships precompiled binaries instead,
  ;; sidestepping the compiler toolchain question altogether.
  (defun fiend/pkb-transcribe-video (video)
    "Transcribe VIDEO with whisper (media-tools conda env) into an .srt
transcript in pkb/refs/, timestamped and searchable via
`consult-notes-search-in-all-notes' since refs/ sits inside
denote-directory. Runs async - transcription of a lecture-length video
takes minutes, and shouldn't block Emacs while it runs."
    (interactive (list (read-file-name "Video file: " "~/jdp/media/")))
    (let* ((outdir (expand-file-name "refs/" (denote-directory)))
           (default-directory outdir))
      (async-shell-command
       (format "conda run -n media-tools whisper %s --output_dir %s --output_format srt"
               (shell-quote-argument (expand-file-name video))
               (shell-quote-argument outdir))
       (format "*whisper-transcribe-%s*" (file-name-base video)))))

  (defun fiend/pkb-extract-subtree-to-note ()
    "Extract the org subtree at point into a new Denote note in pkb/.
Self-contained - denote-org-extras-extract-org-subtree, which this used
to wrap, turned out not to exist in the installed Denote version at all
(confirmed via C-h f; the \"Wrong type argument: commandp\" error was
just call-interactively's precondition check misreporting a void
function, not an interactive-vs-plain mismatch). Built instead on plain
`denote' and core Org primitives, both already proven to work elsewhere
in this config. Mirrors the extras command's documented behavior: the
subtree heading's own text becomes the new note's title, everything
else is inserted as-is."
    (interactive)
    (unless (org-at-heading-p) (org-back-to-heading t))
    (let ((title (nth 4 (org-heading-components)))
          ;; Explicit prompt, passed straight into `denote' below, rather
          ;; than relying on denote-prompts to fire it implicitly. Two
          ;; existing notes ended up with keywords in the filename but
          ;; nothing in #+filetags: - denote and org tags are the same
          ;; system (filetags ARE org tags, inherited by every heading in
          ;; the file), they only drift apart when keywords get added
          ;; after creation via a rename rather than at creation time.
          ;; Prompting here and handing the result to `denote' directly
          ;; keeps filename and front matter written from one value in
          ;; one step, so there's nothing to drift.
          (keywords (denote-keywords-prompt)))
      (org-cut-subtree)
      (let ((body (substring-no-properties (current-kill 0)))
            (denote-directory (expand-file-name "pkb/" (denote-directory))))
        (denote title keywords)
        (goto-char (point-max))
        (insert "\n"
                (with-temp-buffer
                  (insert body)
                  (goto-char (point-min))
                  ;; Drop just the heading line - its text already became
                  ;; the title above - keep everything else verbatim.
                  (when (looking-at "^\\*+ .*\n")
                    (delete-region (point) (match-end 0)))
                  (buffer-string)))
        (save-buffer))))

(use-package org-super-agenda
  :ensure t
  :after org
  :config
  (org-super-agenda-mode 1))

;; j -> org-agenda-goto-date and k -> org-agenda-capture are the *stock*
;; org-agenda-mode-map bindings. Seeing those specifically (instead of any
;; vim-style motion) means the agenda buffer is sitting in Evil's Emacs
;; state rather than Normal/Motion state, so org-agenda-mode-map wins
;; outright and evil-collection never gets a chance to remap anything.
;; Force the state and the bindings explicitly rather than relying on
;; evil-collection to catch this mode on its own.
(with-eval-after-load 'org-agenda
  (evil-set-initial-state 'org-agenda-mode 'motion)
  (evil-define-key '(normal motion) org-agenda-mode-map
    "j" 'org-agenda-next-line
    "k" 'org-agenda-previous-line
    ;; "/" is evil-search-forward by default in normal/motion state,
    ;; which is what actually ate the tag filter before.
    "/" 'org-agenda-filter-by-tag
    ;; org-agenda-filter-by-tag-refine doesn't exist in this Org version -
    ;; refine got folded into org-agenda-filter-by-tag's STRIP-OR-ACCUMULATE
    ;; argument. Per its docstring: C-u alone (`(4)) means STRIP/exclude,
    ;; not refine. C-u C-u (`(16)) is ACCUMULATE - it conses the new tag
    ;; onto the existing filter instead of replacing it, which is the
    ;; actual refine behavior. Simulating that double-prefix here.
    "\\" (lambda ()
           (interactive)
           (let ((current-prefix-arg '(16)))
             (call-interactively 'org-agenda-filter-by-tag)))
    ;; Same precedence issue as j/k/\ above - evil-forward-char sits above
    ;; the plain org-agenda-mode-map binding for org-agenda-log-mode, so
    ;; "l" was just moving the cursor instead of toggling log mode.
    "l" 'org-agenda-log-mode
    ;; Same precedence issue again, this time on RET: evil-motion-state-map
    ;; binds RET to evil-ret (line-move) globally, and since this map never
    ;; had its own RET entry, lookup fell straight through to that generic
    ;; binding instead of ever reaching org-agenda-mode-map's stock RET
    ;; (org-agenda-switch-to). Confirmed via C-h k RET reporting
    ;; "evil-motion-state-map RET" as the source.
    (kbd "RET") 'org-agenda-switch-to
    ;; Same precedence issue again, this time on v: evil-motion-state-map
    ;; binds v to evil-visual-char (Visual selection) globally, so "v"
    ;; opened Visual state instead of org-agenda-view-mode-dispatch, and
    ;; the following "d" ran evil-delete on the selection instead of
    ;; picking "day view" from a dispatch that never opened. Confirmed
    ;; via C-h k v reporting "VISUAL" (evil-visual-char), then C-h f
    ;; confirming org-agenda-view-mode-dispatch is real and is in fact
    ;; org-agenda-mode-map's own stock binding at v.
    "v" 'org-agenda-view-mode-dispatch))

;; Group headers carry their own local keymap
;; (org-super-agenda-header-map), applied as a raw `keymap` text property
;; on the header line. Emacs consults text-property keymaps directly,
;; ahead of and independent from Evil's per-state keymap machinery, so
;; evil-define-key has no effect here - it only targets keymaps Evil
;; actually tracks (major/minor mode maps), not ad hoc text-property ones.
;; A plain define-key is required instead.
(with-eval-after-load 'org-super-agenda
  (define-key org-super-agenda-header-map "j" 'org-agenda-next-line)
  (define-key org-super-agenda-header-map "k" 'org-agenda-previous-line))

(setq org-agenda-custom-commands
      (append org-agenda-custom-commands
              '(("d" "Dashboard (grouped)"
                 ((alltodo ""
                           ((org-agenda-overriding-header
                             " \\ refine   g reset\n")
                            (org-super-agenda-groups
                             ;; "media" and "project" joined this discard set 2026-09-21:
                             ;; media (music/movies/tv/books) was already being discarded
                             ;; as an accidental side effect of also carrying the "someday"
                             ;; filetag - there used to be a "Media" named group here too,
                             ;; but it could never fire, since :discard runs first and every
                             ;; media heading matched it via "someday" before reaching
                             ;; "Media". Removed that dead group, dropped "someday" from
                             ;; those files' filetags, and discard "media" directly instead,
                             ;; so the behavior (hidden from daily view) is intentional
                             ;; rather than incidental. "project" (dist-opt,
                             ;; spatial-clustering-experiment-kedron) added on the same
                             ;; pass - substantive personal projects not being worked
                             ;; currently, parked the same way rather than cluttering
                             ;; "Uncategorized". All four are reviewable on demand via
                             ;; the "s" command below instead of showing up daily.
                             '((:discard (:tag ("bigpicture" "someday" "media" "project")))
                               (:name "Dissertation & Service"
                                      :tag ("dissertation" "service" "AAG" "GGSA" "585" "exams" "mentorship"))
                               (:name "Next Actions"
                                      :todo "NEXT")
                               (:name "Waiting"
                                      :todo "WAITING")
                               (:name "Life Admin"
                                      :tag "life")
                               (:name "Teaching"
                                      :tag "teaching")
                               (:name "Knowledge / Reference"
                                      :tag "knowledge")
                               (:name "Ideation"
                                      :tag "ideation")
                               (:name "Writing"
                                      :tag "writing")
                               (:name "Tools"
                                      :tag "tool")
                               (:name "Personal Projects"
                                      :tag ("mtg" "fishing" "cooking" "homeserver"))
                               (:name "Journal / Reflection"
                                      :tag "journal")
                               (:name "Uncategorized"
                                      :anything t)))))))
                ("s" "Someday / Big Picture / Parked"
                 ((tags "bigpicture|someday|media|project"
                        ((org-agenda-overriding-header
                          "Someday / Big Picture / Parked - kept out of the daily dashboard on purpose\n"))))))))

;; Weekly wins: no dedicated command. A log-only view (entry-types
;; stripped to just closed items) silently loses those items whenever
;; org-super-agenda-mode is on globally, even with an explicit :log
;; selector - tried :anything and :log, both failed; toggling
;; org-super-agenda-mode off was the only thing that worked. Rather than
;; keep fighting that combination, the recognition pass now just reuses
;; the existing "a"/"e" agenda views (which mix normal entries with log
;; entries instead of showing log entries alone) plus a manual "l" press
;; - a pattern that already works, and keeps the hotkey surface smaller.

(setq org-archive-location "%s_archive::* Archived Tasks")
