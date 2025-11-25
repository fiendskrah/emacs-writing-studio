(setq inhibit-startup-message t)
(setq ns-use-native-fullscreen nil) ; fixes tooltip popup bug

;; Emacs 29? EWS leverages functionality from the latest Emacs version.

(when (< emacs-major-version 29)
  (error "Emacs Writing Studio requires Emacs version 29 or later"))

;; Custom settings in a separate file and load the custom settings

(setq-default custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

(keymap-global-set "C-c w v" 'customise-variable)

;; Display line numbers
(column-number-mode)
(global-display-line-numbers-mode t)

(add-hook 'window-setup-hook 'toggle-frame-fullscreen t)

(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

(use-package all-the-icons
  :ensure t)
  ;; bdf fonts
  (add-to-list 'bdf-directory-list "/usr/local/share/emacs/fonts/bdf")

;; helpful replaces the default emacs help docs
(use-package helpful
  :ensure t
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

(use-package package
    :config
    
(require 'package)

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("org"   . "https://orgmode.org/elpa/") t)
(add-to-list 'package-archives '("elpa"  . "https://elpa.gnu.org/packages/") t))

;; Package Management

(use-package use-package
  :custom
  (use-package-always-ensure t)
  (package-native-compile t)
  (warning-minimum-level :emergency))

;; fiend - setting preference for melpa 
(setq package-archive-priorities '(("melpa"  . 100)
				   ("gnu"    . 50)
				   ("nongnu" . 0)))

(package-initialize)

(unless package-archive-contents
(package-refresh-contents))

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

;; Mixed-pich mode

(use-package mixed-pitch
  :hook
  (text-mode . mixed-pitch-mode))

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

;;open org links to pdfs in emacs
(setq org-file-apps
    '(("\\.pdf\\'" . find-file)))

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

(use-package biblioq
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

;; Fleeting notes

(use-package org
  :custom
  (org-default-notes-file "~/acropolis/inbox.org")
  (org-agenda-files
 '("~/jdp/readme.org"
   "~/jdp/conferences.org"
   "~/jdp/advising.org"
   "~/jdp/geog780/780.org"
   "~/acropolis/inbox.org"
   "~/acropolis/readme.org"
   "~/acropolis/personal/records/content.org"
   "~/acropolis/personal/media/movies.org"
   "~/acropolis/personal/records/finances.org"
   "~/acropolis/big_picture.org"))
  ;:bind
  ;(("C-c c" . org-capture)
  ; ("C-c l" . org-store-link))
:custom
  (org-goto-interface 'outline-path-completion)
  (org-capture-templates
 '(("j" "JDP" entry
    (file+olp "~/acropolis/inbox.org" "1) Process inbox" "Captured task pile" "JDP")
    "** TODO %?")
   ("a" "Acropolis" entry
    (file+olp "~/acropolis/inbox.org" "1) Process inbox" "Captured task pile" "Acropolis")
    "** TODO %?")
   ("e" "Emacs" entry
    (file+olp "~/acropolis/inbox.org" "1) Process inbox" "Captured task pile" "Emacs")
    "** TODO %?")))
(org-todo-keywords
 '((sequence "TASK(a)" "TODO(t)" "NEXT(n)" "IDEA(i)" "|" "DONE(d)")
   (sequence "HOLD(h)" "WAITING(w)" "DEADLINE(D)" "|" "CANCELLED(c)"))))

;; Denote

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
   ("C-c w d i" . denote-link-or-create)
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
(require 'ox-beamer)   ;; Beamer backend (Org -> LaTeX Beamer)

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
(org-babel-do-load-languages
 'org-babel-load-languages
 '((dot . t))) ; this line activates GraophViz dot

(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(setq display-line-numbers-type 'relative
    display-line-numbers-width 3)

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
    "RET" '(bookmark-bmenu-list :which-key "bookmarks")
    "o" '(org-agenda :which-key "agenda")
    "d" '(dired :which-key "dired")
    "g" '(magit-status :which-key "magit")
    "ts" '(hydra-text-scale/body :which-key "scale text")
    "o"  '(hydra-org/body :which-key "org")
    "f" '(hydra-file/body :which-key "file"))

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
        (add-to-list 'evil-emacs-state-modes mode))))

;; Ivy provides some improved functionality for certain commands
   (use-package ivy
   :config (ivy-mode 1)
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
 ("a" org-agenda "agenda"))

 ;; Org file split
 (defhydra hydra-file (:timeout 4)
 "file"
 ("r" counsel-recentf "recent")
 ("s" save-buffer "save")
 ("." find-file "find"))



(use-package dashboard
  :ensure t
  :init
  (setq dashboard-banner-logo-title "SEE YOU SPACE COWBOY")
  (setq dashboard-startup-banner "~/.emacs.d/gengar.png") ;; path to your image
  (setq dashboard-center-content t)
  ;; This makes dashboard the startup buffer
  (setq dashboard-items '((recents . 5)
                        (agenda  . 7)))
  :config
  (dashboard-setup-startup-hook))
(add-hook 'emacs-startup-hook
          (lambda ()
            (switch-to-buffer "*dashboard*")))
