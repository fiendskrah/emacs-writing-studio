;;;; my-pkb-picker.el --- PKB tag picker  -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'subr-x)
(require 'tabulated-list)

;; --- paths & tiny utils -----------------------------------------------------
(defvar my/pkb-dir (expand-file-name "pkb/" (if (boundp 'fiend/denote-lib) fiend/denote-lib "~/acropolis/denote-library/"))
  "Directory containing PKB notes.")

(defun my/pkb--join (xs) (if xs (mapconcat #'identity xs " + ") ""))

;; --- file/tag indexing -------------------------------------------------------
(defun my/pkb--all-files ()
  "All candidate files in PKB. Excludes symlinks - the stable
access/assets/cooking/finances/health.org aliases already point at the
real timestamped files, which are covered here directly; including both
would double-list them, and if a symlink target has ever drifted, this
package errors outright rather than just duplicating an entry. Also
excludes lock/autosave files (leading . or #)."
  (seq-remove
   (lambda (f)
     (or (file-symlink-p f)
         (string-match-p "/[.#]" f)))
   (directory-files-recursively my/pkb-dir ".*\\.[[:alnum:]]+$")))

(defun my/pkb--file-tags (file)
  "Return atomic tags for FILE, splitting on + and then on _."
  (let ((name (file-name-nondirectory file)))
    (when (string-match "__\\(.*\\)\\.[^.]+$" name)
      (let* ((raw    (match-string 1 name))
             (chunks (split-string raw "\\+" t))
             (tokens (cl-mapcan (lambda (s) (split-string s "_" t)) chunks)))
        (delete-dups (mapcar #'downcase tokens))))))

(defun my/pkb--index ()
  "Return alist (TAG . FILES) across PKB."
  (let ((ht (make-hash-table :test 'equal)))
    (dolist (f (my/pkb--all-files))
      (dolist (tag (my/pkb--file-tags f))
        (push f (gethash tag ht))))
    (let (alist)
      (maphash (lambda (k v)
                 (push (cons k (cl-remove-duplicates v :test #'string=)) alist))
               ht)
      (sort alist (lambda (a b) (string-lessp (car a) (car b)))))))

(defun my/pkb--files-for-tags (index tags)
  "AND-match: files that have every TAGS."
  (let* ((lists (mapcar (lambda (tag) (cdr (assoc tag index))) tags)))
    (if (null lists) nil
      (cl-reduce (lambda (a b) (cl-intersection a b :test #'string=))
                 (cdr lists)
                 :initial-value (car lists)))))

(defun my/pkb--co-tag-index (files exclude-tags)
  "Alist (TAG . FILES) seen in FILES, excluding EXCLUDE-TAGS."
  (let ((ht (make-hash-table :test 'equal)))
    (dolist (f files)
      (dolist (tag (my/pkb--file-tags f))
        (unless (member tag exclude-tags)
          (push f (gethash tag ht)))))
    (let (alist)
      (maphash (lambda (k v)
                 (push (cons k (cl-remove-duplicates v :test #'string=)) alist))
               ht)
      (sort alist (lambda (a b) (string-lessp (car a) (car b)))))))

;; --- title & display helpers -------------------------------------------------
(defun my/pkb--pretty-title (file)
  "Best-effort title from Denote filename."
  (let ((base (file-name-nondirectory file)))
    (when (string-match "--\\([^_]+\\)__" base)
      (replace-regexp-in-string "-" " " (match-string 1 base)))))

(defun my/pkb--org-title-first-line (file)
  "Return #+title from the FIRST LINE of FILE (case-insensitive), or nil."
  (with-temp-buffer
    (insert-file-contents file nil 0 2048)
    (goto-char (point-min))
    (let ((case-fold-search t))
      (when (looking-at "^#\\+title:\\s-*\\(.*\\)$")
        (let* ((raw (string-trim (match-string 1)))
               (len (length raw)))
          (when (and (>= len 2)
                     (memq (aref raw 0) '(?\" ?'))
                     (eq (aref raw 0) (aref raw (1- len))))
            (setq raw (substring raw 1 -1)))
          raw)))))

(defun my/pkb--title-for-display (file)
  "Prefer #+title: on first line; otherwise Denote filename title."
  (or (my/pkb--org-title-first-line file)
      (my/pkb--pretty-title file)
      (file-name-nondirectory file)))

(defun my/pkb--tags-for-display (file)
  "Return a comma-separated string of atomic tags for FILE."
  (let* ((tags (my/pkb--file-tags file))
         (tags (sort (delete-dups (copy-sequence tags)) #'string-lessp)))
    (mapconcat #'identity tags ", ")))

;; --- hotkey stage ------------------------------------------------------------
(defvar my/pkb-hotkeys "asdfghjkl;wertyuiopzxcvbnm1234567890"
  "Keys used to select tags in the hotkey picker, in priority order.")

(defconst my/pkb--picker-buf "*PKB tag picker*")

(defun my/pkb--hotkeys-render (pairs selected-tags files co)
  "Render hotkey menu. PAIRS is (CHAR . TAG); CO is (TAG . FILES)."
  (with-current-buffer (get-buffer-create my/pkb--picker-buf)
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert (format "Selected: %s\n" (my/pkb--join selected-tags)))
      (insert (format "Matching files: %d\n\n" (length files)))
      (dolist (p pairs)
        (let* ((key (car p)) (tag (cdr p))
               (count (length (cdr (assoc tag co)))))
          (insert (format "[%c] %s (%d)\n" key tag count))))
      (insert "\n[RET] Go    [q] Quit\n")
      (special-mode)
      (setq-local cursor-type nil))
    (display-buffer (current-buffer))))

(defun my/pkb--pick-tag (tag-index prompt)
  "Pick a tag from TAG-INDEX (alist), showing counts."
  (let* ((cands  (mapcar (lambda (p)
                           (format "%s (%d)" (car p) (length (cdr p))))
                         tag-index))
         (choice (completing-read prompt cands nil t)))
    (substring choice 0 (string-match " (" choice))))

;; --- RESULTS BUFFER (tabulated-list-mode) -----------------------------------
(defconst my/pkb--results-buf "*PKB results*")

(defvar-local my/pkb--results-files nil)
(defvar-local my/pkb--results-selected nil)

(define-derived-mode my/pkb-results-mode tabulated-list-mode "PKB-Results"
  "List PKB matches. Keys: RET open, o other-window, r ripgrep, g refresh, q quit."
  (setq tabulated-list-format [("Title" 50 t)
                               ("Tags"  40 t)
                               ("File"   0 t)])
  (setq tabulated-list-padding 2)
  (setq tabulated-list-sort-key (cons "Title" nil))
  (setq-local tabulated-list-visit-function #'my/pkb--results-visit)
  (add-hook 'tabulated-list-revert-hook #'my/pkb--results-refresh nil t)
  (tabulated-list-init-header))

(defun my/pkb--results-entries ()
  "Build entries for `tabulated-list-entries` from `my/pkb--results-files`."
  (mapcar
   (lambda (f)
     (let ((title (my/pkb--title-for-display f))
           (tags  (my/pkb--tags-for-display f))
           (rel   (file-relative-name f my/pkb-dir)))
       ;; ID is the file path; vector are columns
       (list f (vector title tags rel))))
   my/pkb--results-files))

(defun my/pkb--results-visit (id)
  "Open the file whose tabulated-list ID is ID."
  (when (and id (file-exists-p id))
    (find-file id)))

(defun my/pkb--results-visit-other-window ()
  "Open the file at point in another window."
  (interactive)
  (let ((id (tabulated-list-get-id)))
    (when id (find-file-other-window id))))

(defun my/pkb--results-refresh ()
  "Refresh the results buffer from `my/pkb--results-files`."
  (setq tabulated-list-entries (my/pkb--results-entries))
  (tabulated-list-print t))

(defun my/pkb--results-open ()
  (interactive)
  (let ((f (tabulated-list-get-id)))
    (when f (find-file f))))

(defun my/pkb--results-open-other-window ()
  (interactive)
  (let ((f (tabulated-list-get-id)))
    (when f (find-file-other-window f))))

(defun my/pkb--results-ripgrep ()
  "Search within the current result set using consult-ripgrep (if available)."
  (interactive)
  (if (require 'consult nil t)
      (let ((default-directory my/pkb-dir))
        ;; Build --iglob filters for each file relative to pkb-dir
        (let* ((globs (mapcar (lambda (f)
                                (concat "--iglob="
                                        (shell-quote-argument
                                         (file-relative-name f my/pkb-dir))))
                              my/pkb--results-files))
               (consult-ripgrep-args
                (concat "rg --null --line-number --no-heading --smart-case --color never "
                        (string-join globs " "))))
          (consult-ripgrep my/pkb-dir)))
    (user-error "consult not available")))

(let ((map my/pkb-results-mode-map))
  (define-key map (kbd "RET")      #'my/pkb--results-open)
  (define-key map (kbd "<return>") #'my/pkb--results-open)
  (define-key map (kbd "C-m")      #'my/pkb--results-open)
  (define-key map (kbd "o")        #'my/pkb--results-visit-other-window)
  (define-key map (kbd "q")        #'quit-window))

(defun my/pkb--show-results (files selected-tags)
  "Display FILES in a tabulated list buffer."
  (let ((buf (get-buffer-create my/pkb--results-buf)))
    (with-current-buffer buf
      (my/pkb-results-mode)
      ;; keep these for revert etc.
      (setq my/pkb--results-files files
            my/pkb--results-selected selected-tags)
      (setq header-line-format
            (format "Tags: %s   Files: %d   (RET open,  q quit)"
                    (my/pkb--join selected-tags) (length files)))
      ;; compute rows *directly* from FILES we were passed
      (my/pkb--results-refresh)
      ;; ensure point is on the first row so RET finds an ID
      (goto-char (point-min))
      (when (not (eobp)) (forward-line 1)))
    (pop-to-buffer buf)))

(defun my/pkb--results-entries-from (files)
  "Build tabulated-list entries from FILES directly."
  (mapcar
   (lambda (f)
     (let ((title (my/pkb--title-for-display f))
           (tags  (my/pkb--tags-for-display f))
           (rel   (file-relative-name f my/pkb-dir)))
       (list f (vector title tags rel))))
   files))

;; --- main command: hotkey narrowing -> results buffer -----------------------
 (defun my/pkb-pick-by-tag ()
  "Tag-first PKB picker with hotkey narrowing. RET=Go, q=Quit -> show results buffer.
Formerly `my/pkb-pick-hotkeys' - renamed when a title-based picker
(`fiend/pkb-pick-by-title', in fiend_ews.org) took over SPC p p."
  (interactive)
  (let* ((index (my/pkb--index))
         (selected nil)
         files)
    ;; 1) first tag via completing-read
    (let ((t1 (my/pkb--pick-tag index "Tag: ")))
      (unless t1 (user-error "Cancelled"))
      (push t1 selected)
      (setq files (my/pkb--files-for-tags index selected)))

    ;; 2) hotkey loop over co-tags
    (catch 'done
      (while (and files (> (length files) 1))
        (let* ((co (my/pkb--co-tag-index files selected)))
          (unless co
            (throw 'done nil))
          (let* ((sorted (sort co (lambda (a b)
                                    (> (length (cdr a)) (length (cdr b))))))
                 (keys (delq ?q (string-to-list my/pkb-hotkeys))) ;; reserve q
                 (n (min (length keys) (length sorted)))
                 (pairs (cl-loop for i from 0 below n
                                 for key = (nth i keys)
                                 for tag = (car (nth i sorted))
                                 collect (cons key tag))))
            (with-current-buffer (get-buffer-create my/pkb--picker-buf)
              (my/pkb--hotkeys-render pairs selected files sorted))
            (let ((k (read-key "Pick tag, or RET=Go, q=Quit: ")))
              (cond
               ;; RET
               ((or (memq k '(13 10 ?\r ?\n)) (eq k 'return))
                (throw 'done t))
               ;; Quit
               ((or (eq k ?q) (eq k 'q))
                (setq files nil)
                (throw 'done nil))
               ;; Hotkey
               (t
                (let ((hit (assoc k pairs)))
                  (if hit
                      (progn
                        (push (cdr hit) selected)
                        (setq selected (cl-delete-duplicates selected :test #'string= :from-end t))
                        (setq files (my/pkb--files-for-tags index selected)))
                    (message "Key not bound"))))))))))

    ;; 3) always close the picker window if present (do this after the catch)
    (when (get-buffer my/pkb--picker-buf)
      (quit-windows-on my/pkb--picker-buf))

    ;; 4) show results (even with a single file)
    (if (null files)
        (message "No matches for %s" (my/pkb--join selected))
      (my/pkb--show-results files selected))))
 
(provide 'my-pkb-picker)
;;; my-pkb-picker.el ends here
