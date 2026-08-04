;; -*- lexical-binding: t; -*-

;; gcmh: run GC when Emacs is idle, not mid-keystroke, so editing never pauses.
;; Takes over from the failsafe threshold set in early-init's after-init-hook.
(use-package gcmh
  :hook (emacs-startup . gcmh-mode)
  :config
  (setq gcmh-idle-delay 'auto                     ; GC after idle, auto-tuned
        gcmh-high-cons-threshold (* 128 1024 1024)))

;; Font
(set-face-attribute 'default nil :family "Martian Mono" :height 100 :weight 'regular)
;; :weight regular so prose doesn't inherit the default face's medium (looks bold)
(set-face-attribute 'variable-pitch nil :family "Crimson Pro" :height 135 :weight 'regular)
(setf (alist-get "Latin Modern Math" face-font-rescale-alist nil nil #'equal) 1.25)

(defvar my/note-fonts '(("EB Garamond" . 135) ("STIX Two Text" . 125) ("Charis" . 125)
                        ("Crimson Pro" . 135) ("ETBookOT" . 135) ("ETBembo" . 135)))
(defun my/set-note-font (font)
  "Set the org prose (variable-pitch) FONT and refresh open mixed-pitch buffers."
  (interactive (list (completing-read "Note font: " (mapcar #'car my/note-fonts) nil t)))
  (set-face-attribute 'variable-pitch nil :family font :weight 'regular
                      :height (or (cdr (assoc font my/note-fonts)) 125))
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (bound-and-true-p mixed-pitch-mode)
        (mixed-pitch-mode -1)
        (mixed-pitch-mode 1)))))
(global-set-key (kbd "C-c f") #'my/set-note-font)

;; UI cleanup
(setq inhibit-startup-screen t)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(fringe-mode 0)

;; Mode-line extras: column number + file size
(column-number-mode 1)
(size-indication-mode 1)

;; No line wrapping anywhere; long lines truncate and scroll sideways.
(setq-default truncate-lines t)

;; Perf: default GC (800KB) and process-read buffer (4KB) are tiny. Bigger =
;; fewer GC pauses while editing and snappier eglot/gopls (it streams a lot).
(setq gc-cons-threshold (* 100 1024 1024)
      read-process-output-max (* 1024 1024))

;; Packages: load-path first so the org fork shadows built-in org
(add-to-list 'load-path "~/.emacs.d/elpa/org-mode/lisp/")
(require 'package)
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("gnu"   . "https://elpa.gnu.org/packages/")))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;; Org + LaTeX preview. Deferred: org (the fork) is large; nothing at startup
;; needs it. It loads on the first .org file (org-mode autoload) or C-c c/C-x a.
(use-package org
  :load-path "~/.emacs.d/elpa/org-mode/lisp/"
  :defer t)

(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-c i") #'my/org-insert-inline-math)
  (define-key org-mode-map (kbd "C-c d") #'my/org-insert-display-math)
  (define-key org-mode-map (kbd "C-c a") #'my/org-insert-align))

(defun my/org-insert-inline-math ()
  (interactive)
  (insert "\\(\\)")
  (backward-char 2))

(defun my/org-insert-display-math ()
  (interactive)
  (insert "\\[\\]")
  (backward-char 2))

(defun my/org-insert-align ()
  (interactive)
  (insert "\\begin{align}\n\n\\end{align}")
  (forward-line -1))

(with-eval-after-load 'org
  (require 'org-latex-preview)
  (add-hook 'org-mode-hook #'org-latex-preview-mode)
  ;; After a short idle (window settled), refresh both latex and image
  ;; previews. Image :center needs the final window width, which isn't set
  ;; during org-mode setup, so re-preview here.
  (add-hook 'org-mode-hook
            (lambda ()
              (run-with-idle-timer
               1 nil (lambda (buf)
                       (when (buffer-live-p buf)
                         (with-current-buffer buf
                           (org-latex-preview '(16))
                           (org-link-preview '(16)))))
               (current-buffer)))))

(with-eval-after-load 'org-latex-preview
  (setq org-latex-preview-mode-display-live t
        org-latex-preview-mode-update-delay 0.3
        org-latex-preview-mode-track-inserts t
        org-latex-preview-persist-expiry 30
        org-latex-preview-process-precompile t
        org-latex-preview-process-active-indicator nil)
  (plist-put org-format-latex-options :background "Transparent")
  (plist-put org-latex-preview-appearance-options :scale 1.0)
  (plist-put org-latex-preview-appearance-options :zoom
             (+ (/ (face-attribute 'default :height) 100.0) 0.15)))

;; Org appearance
(with-eval-after-load 'org-src
  (require 'latex)
  (setf (alist-get "latex" org-src-lang-modes nil nil #'equal) 'LaTeX)
  (setq org-src-fontify-natively t))

(with-eval-after-load 'org
  (dolist (face '((org-level-1 . 1.25)
                  (org-level-2 . 1.15)
                  (org-level-3 . 1.08)
                  (org-level-4 . 1.0)))
    (set-face-attribute (car face) nil :weight 'bold :height (cdr face)))
  (setq org-highlight-latex-and-related '(native latex)
        org-pretty-entities t
        org-pretty-entities-include-sub-superscripts nil
        org-hide-emphasis-markers t
        org-hide-leading-stars t
        org-ellipsis " ▾"
        org-startup-folded 'nofold
        org-startup-with-inline-images t
        org-image-actual-width nil
        org-image-align 'center)
  (add-hook 'org-mode-hook (lambda () (display-line-numbers-mode -1))))

;; Quick capture
(setq org-capture-templates
      '(("t" "Task" entry (file "~/org/tasks.org")
         "* TODO %?\n  SCHEDULED: %t\n")
        ("w" "Work note" entry (file+olp+datetree "~/org/work.org")
         "* %?\n%U\n")
        ("l" "TIL" entry (file+olp+datetree "~/org/til.org")
         "* %?\n%U\n")))
(global-set-key (kbd "C-c c") #'org-capture)

;; Math exercise files
(defvar my/exercise-dir "~/Notes/Exercise/")

(defun my/exercise-template (title)
  (insert (format "#+TITLE: %s\n" title))
  (insert "#+AUTHOR: fauzy\n")
  (insert (format-time-string "#+DATE: %Y-%m-%d\n"))
  (insert "#+OPTIONS: toc:nil num:nil\n")
  (insert "#+LATEX_HEADER: \\usepackage{amsmath, amssymb, amsthm}\n")
  (insert "#+LATEX_HEADER: \\usepackage{mathtools}\n")
  (insert "#+LATEX_HEADER: \\newtheorem{theorem}{Theorem}\n")
  (insert "#+LATEX_HEADER: \\newtheorem{lemma}{Lemma}\n")
  (insert "#+LATEX_HEADER: \\newtheorem{definition}{Definition}\n")
  (insert "#+LATEX_HEADER: \\newtheorem{proposition}{Proposition}\n\n")
  (insert "* 1.\n\n** Solution\n\n** Answer\n\n"))

(defun my/new-exercise (&optional topic)
  "Open today's exercise file. With a prefix arg, prompt for TOPIC and use a
separate exercise-<date>-<topic>.org so two topics on one day don't collide."
  (interactive (list (when current-prefix-arg (read-string "Topic: "))))
  (make-directory my/exercise-dir t)
  (let* ((date (format-time-string "%Y-%m-%d"))
         (slug (and topic (not (string-empty-p topic))
                    (replace-regexp-in-string "[^a-z0-9]+" "-" (downcase topic))))
         (name (if slug (format "exercise-%s-%s.org" date slug)
                 (format "exercise-%s.org" date)))
         (title (if slug (format "Exercise %s — %s" date topic)
                  (format "Exercise %s" date))))
    (find-file (expand-file-name name my/exercise-dir))
    (when (zerop (buffer-size))
      (my/exercise-template title))
    (goto-char (point-max))))

(global-set-key (kbd "C-c x") #'my/new-exercise)

(setq org-agenda-files '("~/org/tasks.org" "~/Notes/Exercise/"))
(global-set-key (kbd "C-x a") #'org-agenda)

;; Packages
(use-package auctex :defer t)

(use-package cdlatex
  :hook (org-mode . org-cdlatex-mode)
  :config
  (setq cdlatex-math-symbol-prefix ?\;
        cdlatex-math-symbol-alist '((?F ("\\Phi"))
                                    (?o ("\\omega" "\\mho" "\\mathcal{O}"))
                                    (?. ("\\cdot" "\\circ"))
                                    (?6 ("\\partial"))
                                    (?v ("\\vee" "\\forall"))
                                    (?^ ("\\uparrow" "\\Updownarrow" "\\updownarrow")))
        cdlatex-math-modify-alist '((?b "\\mathbf" "\\textbf" t nil nil)
                                    (?B "\\mathbb" "\\textbf" t nil nil)
                                    (?t "\\text" nil t nil nil))
        cdlatex-env-alist '(("align"    "\\begin{align}\n?\n\\end{align}"    nil)
                            ("equation" "\\begin{equation}\n?\n\\end{equation}" nil)
                            ("pmatrix"  "\\begin{pmatrix}\n?\n\\end{pmatrix}"  nil))))

(use-package org-modern
  :hook (org-mode . org-modern-mode))

(use-package org-journal
  :vc (:url "https://github.com/bastibe/org-journal")
  :bind ("C-c n" . org-journal-new-entry)
  :config
  (setq org-journal-dir "~/org/journal/"
        org-journal-file-type 'weekly
        org-journal-file-format "%Y%m%d.org"
        org-journal-find-file #'find-file
        org-journal-enable-encryption t
        org-crypt-key "2CB9FE6B3550313D40F949535186C15EFF12F3E3"
        org-crypt-disable-auto-save t)
  (add-hook 'find-file-hook
            (lambda ()
              (when (string-prefix-p (expand-file-name org-journal-dir)
                                     (or buffer-file-name ""))
                (org-decrypt-entries))))
  (global-set-key (kbd "C-c e") #'org-decrypt-entries))

(use-package org-appear
  :vc (:url "https://github.com/awth13/org-appear")
  :hook (org-mode . org-appear-mode))

(use-package mixed-pitch
  :hook (org-mode . mixed-pitch-mode)
  :config (setq mixed-pitch-set-height t))

(use-package olivetti
  :hook (org-mode . olivetti-mode)
  :config
  (setq olivetti-body-width 68)
  (set-face-attribute 'olivetti-fringe nil :background (face-attribute 'default :background)))

(use-package dashboard
  :config
  ;; Pick a random png from banners/ each launch (drop more in to add variety).
  (setq dashboard-startup-banner
        (let ((pngs (directory-files
                     (expand-file-name "banners" user-emacs-directory) t "\\.png\\'")))
          (if pngs (seq-random-elt pngs)
            (expand-file-name "flamel.png" user-emacs-directory)))  ; fallback
        dashboard-image-banner-max-height 300
        dashboard-center-content t
        dashboard-items '((recents . 5) (agenda . 5))
        dashboard-match-agenda-entry "TODO=\"TODO\""   ; undone todos, any date
        dashboard-filter-agenda-entry 'dashboard-no-filter-agenda
        dashboard-agenda-release-buffers t             ; don't leave agenda files open
        ;; clickable widgets above recent files (navigator isn't in the
        ;; default layout, so add it to dashboard-startupify-list below)
        dashboard-navigator-buttons
        `((("" "IRC"     "Connect to Libera" (lambda (&rest _) (my/libera)) nil nil ,(propertize "]     " 'face 'dashboard-navigator))
           ("" "elfeed"  "Open RSS reader"   (lambda (&rest _) (elfeed))    nil nil ,(propertize "]     " 'face 'dashboard-navigator))
           ("" "notmuch" "Open mail"         (lambda (&rest _) (notmuch)))))
        dashboard-startupify-list
        '(dashboard-insert-banner
          dashboard-insert-newline
          dashboard-insert-banner-title
          dashboard-insert-newline
          dashboard-insert-init-info
          dashboard-insert-newline
          dashboard-insert-newline
          dashboard-insert-navigator
          dashboard-insert-items
          dashboard-insert-newline
          dashboard-insert-footer))
  (dashboard-setup-startup-hook))

;; Keybinding cheatsheet in a left side window at startup. Auto-closes the
;; first time you open a file; survives C-x b (side windows aren't reused for
;; ordinary buffer display). Add new binds to my/cheatsheet-content.
;; Colors come from theme faces (dashboard-heading / font-lock), so it adapts
;; on C-c t. No mode-line on purpose: reads as a clean sidebar panel.
(defvar my/cheatsheet-content
  '(("Editing"
     ("C-a"          . "line start")
     ("C-,"          . "dup line")
     ("M-p / M-n"    . "move line")
     ("C-> / C-<"    . "mark next")
     ("C-c m"        . "mark all")
     ("C-x u"        . "undo tree"))
    ("Search / Jump"
     ("C-s"          . "search buf")
     ("C-x p f"      . "find file")
     ("M-s r"        . "live grep")
     ("M-s f"        . "find by name")
     ("M-g g"        . "goto line")
     ("M-g i"        . "imenu")
     ("M-j"          . "jump char")
     ("M-g w"        . "jump word")
     ("C-."          . "embark act")
     ("C-;"          . "embark dwim")
     ("C-x b"        . "switch buf")
     ("C-x C-b"      . "buffer list"))
    ("Notes / Files"
     ("C-c c"        . "capture")
     ("C-c c t"      . "  task")
     ("C-c c w"      . "  work note")
     ("C-c c l"      . "  TIL")
     ("C-c n"        . "journal")
     ("C-c x"        . "exercise")
     ("C-x a"        . "agenda")
     ("C-c e"        . "decrypt")
     ("C-c N n"      . "denote new")
     ("C-c N o"      . "note find")
     ("C-c N l"      . "note link")
     ("C-c N b"      . "backlinks")
     ("C-c N r"      . "note rename"))
    ("Org edit"
     ("TAB"          . "fold")
     ("M-RET"        . "new item")
     ("M-S-RET"      . "new TODO")
     ("C-c C-l"      . "link")
     ("C-c C-o"      . "open link")
     ("C-c ."        . "timestamp")
     ("C-c i / d"    . "math")
     ("C-c a"        . "align env")
     ("C-c C-x C-v"  . "images"))
    ("Org TODO"
     ("C-c C-t"      . "TODO/DONE")
     ("S-left/right" . "cycle")
     ("C-c C-s"      . "schedule")
     ("C-c C-d"      . "deadline")
     ("C-c C-c"      . "tags")
     ("C-c / t"      . "todo tree"))
    ("View / Tools"
     ("C-c P"        . "slides")
     ("C-c L"        . "focus mode")
     ("C-c T"        . "timer")
     ("C-`"          . "popper")
     ("C-M-`"        . "popper cyc")
     ("C-c `"        . "popper type")
     ("C-o"          . "casual menu")
     ("C-c w"        . "RSS elfeed")
     ("C-c f"        . "prose font")
     ("C-c t"        . "theme")
     ("C-c r"        . "rename")
     ("C-c h"        . "this sheet")
     ("C-h f"        . "help fn")
     ("C-h v"        . "help var")
     ("C-h k"        . "help key")
     ("C-x g"        . "magit")
     ("<f5>"         . "recompile")
     ("C-<f5>"       . "compile"))
    ("Terminal (vterm)"
     ("C-c v"        . "open vterm")
     ("C-c C-t"      . "copy mode")
     ("C-c C-c"      . "send C-c")
     ("C-c C-l"      . "clear")
     ("C-<return>"   . "copy+exit"))
    ("Mail (notmuch)"
     ("C-c M"        . "open mail")
     ("j"            . "jump saved search")
     ("G"            . "fetch + index")
     ("RET"          . "open thread")
     ("a"            . "archive")
     ("r / R"        . "reply / all")
     ("C-x m"        . "new mail")
     ("C-c C-c"      . "send")
     ("C-c C-m s p"  . "pgp sign")
     ("C-c C-m c p"  . "pgp encrypt"))))

(defun my/cheatsheet-buffer ()
  (with-current-buffer (get-buffer-create "*Cheatsheet*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert (propertize "  Cheatsheet\n\n"
                          'face '(:inherit dashboard-heading :weight bold :height 1.2)))
      (dolist (section my/cheatsheet-content)
        (insert (propertize (concat " " (car section) "\n") 'face 'dashboard-heading))
        (dolist (row (cdr section))
          (insert "  "
                  (propertize (format "%-13s" (car row)) 'face 'font-lock-function-name-face)
                  (propertize (cdr row) 'face 'font-lock-comment-face)
                  "\n"))
        (insert "\n")))
    (goto-char (point-min))
    (special-mode)
    (setq-local cursor-type nil
                truncate-lines t
                display-line-numbers nil)
    (current-buffer)))

(defun my/show-cheatsheet ()
  (let ((w (display-buffer-in-side-window
            (my/cheatsheet-buffer)
            '((side . right) (window-width . 30)
              (window-parameters . ((no-delete-other-windows . t)))))))
    ;; Lock the width so a resize/re-eval can't grow it to a 50/50 split.
    (when (window-live-p w)
      (window-preserve-size w t t))
    w))

(defun my/close-cheatsheet (&rest _)
  (when-let ((w (get-buffer-window "*Cheatsheet*")))
    (delete-window w)))

;; Pop the cheatsheet open, or close it if already showing.
(defun my/toggle-cheatsheet ()
  (interactive)
  (if (get-buffer-window "*Cheatsheet*")
      (my/close-cheatsheet)
    (my/show-cheatsheet)))
(global-set-key (kbd "C-c h") #'my/toggle-cheatsheet)

;; Own the whole startup layout so no stray *scratch* window survives:
;; dashboard fills the frame, cheatsheet sits in the side window. Run on a
;; short idle timer so it fires after window-setup-hook (dashboard resizes
;; there and would otherwise clobber this).
(defun my/startup-layout ()
  ;; A stray splash/popup may sit in a side window; delete-other-windows
  ;; refuses to collapse into one, so drop side windows first.
  (when (window-with-parameter 'window-side)
    (window-toggle-side-windows))
  (delete-other-windows)
  (if (fboundp 'dashboard-open) (dashboard-open) (switch-to-buffer "*scratch*"))
  (my/show-cheatsheet))

;; Show the dashboard as the very first buffer so no *scratch*/file flashes
;; before the idle-timer layout (below) adds the cheatsheet side window.
(setq initial-buffer-choice #'dashboard-open)
(add-hook 'emacs-startup-hook
          (lambda () (run-with-idle-timer 0.1 nil #'my/startup-layout)))
(add-hook 'find-file-hook #'my/close-cheatsheet)

;; which-key is built into Emacs 30, no package to install/load.
(use-package which-key
  :ensure nil
  :config (which-key-mode))

(use-package vertico
  :config (vertico-mode))

(use-package orderless
  :config
  (setq completion-styles '(orderless basic)))

(use-package marginalia
  :config (marginalia-mode))

(use-package consult
  :bind (("C-x b" . consult-buffer)
         ("C-s"   . consult-line)
         ("M-g g" . consult-goto-line)
         ("M-g i" . consult-imenu)
         ("M-s r" . consult-ripgrep)     ; project-wide text search (needs rg)
         ("M-s f" . consult-find)))      ; recursive filename search

;; wgrep: make a grep/embark-export buffer editable, save edits back to files.
;; Flow: M-s r -> C-. (embark) export -> C-c C-p edit -> C-c C-c save all.
(use-package wgrep
  :config (setq wgrep-auto-save-buffer t))

(use-package embark
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)))

(use-package embark-consult
  :after (embark consult))

;; yasnippet scans snippet dirs on load; defer 1s so it's off the startup path.
(use-package yasnippet
  :defer 1
  :config (yas-global-mode 1))

;; Editing: duplicate line, move line, multiple cursors, smart C-a
(global-set-key (kbd "C-,") #'duplicate-dwim)
(with-eval-after-load 'org           ; org binds C-, itself, so override it there too
  (define-key org-mode-map (kbd "C-,") #'duplicate-dwim))
(use-package move-text
  :bind (("M-p" . move-text-up)
         ("M-n" . move-text-down)))

(use-package multiple-cursors
  :bind (("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-c m" . mc/mark-all-like-this)))

;; vterm: real terminal (libvterm). Compiles a C module on first load.
(use-package vterm
  :bind ("C-c v" . vterm))

;; pdf-tools: view/annotate PDFs in Emacs. Builds a C helper (epdfinfo) via
;; poppler on first run; `pdf-tools-install' does it and registers the mode.
(use-package pdf-tools
  :magic ("%PDF" . pdf-view-mode)   ; open PDFs in pdf-view-mode automatically
  :config
  (pdf-tools-install :no-query))

;; Personal identifiers (email, IRC nick/account) live in private.el
;; (gitignored) so they stay off GitHub. Loaded here, before notmuch/erc use
;; the vars; defvars give safe fallbacks if private.el is missing.
(defvar my/mail-address "you@example.com" "Primary email; set in private.el.")
(defvar my/irc-nick "guest" "IRC nick; override in private.el.")
(defvar my/irc-account nil "NickServ account for SASL; set in private.el.")
(load (expand-file-name "private.el" user-emacs-directory) t)

;; notmuch: tag-based mail. mbsync fetches Disroot into ~/Mail, notmuch indexes,
;; msmtp sends. `G' in notmuch runs ~/.local/bin/mailsync (fetch + index).
(use-package notmuch
  :bind ("C-c M" . notmuch)
  :custom
  (user-mail-address my/mail-address)
  (user-full-name "fauzymadani")
  (notmuch-address-command 'internal)       ; tab-complete recipients from past mail
  (notmuch-show-logo t)
  (notmuch-search-oldest-first nil)         ; newest mail on top
  (notmuch-poll-script "~/.local/bin/mailsync")
  (notmuch-fcc-dirs "disroot/Sent")         ; keep a copy of sent mail
  ;; saved searches, each with a `j' jump-key (press j then the letter)
  (notmuch-saved-searches
   '((:name "inbox"    :query "tag:inbox"            :key "i" :search-type tree)
     (:name "unread"   :query "tag:unread"           :key "u" :search-type tree)
     (:name "flagged"  :query "tag:flagged"          :key "f" :search-type tree)
     (:name "today"    :query "date:today.."         :key "t" :search-type tree)
     (:name "sent"     :query "folder:disroot/Sent"  :key "s" :search-type tree)
     (:name "emacs list" :query "tag:emacs"          :key "e" :search-type tree)
     (:name "all mail" :query "*"                     :key "a" :search-type tree)))
  ;; prettier tags: symbols/color instead of plain words
  (notmuch-tag-formats
   '(("unread"     (propertize tag 'face '(:foreground "#e5c07b" :weight bold)))
     ("flagged"    (propertize "*" 'face '(:foreground "#e06c75")))
     ("attachment" "@")
     ("replied"    "<-")
     ("sent"       "->")))
  ;; thread-list columns: date | count | authors | subject | tags
  (notmuch-search-result-format
   '(("date" . "%12s  ")
     ("count" . "%-7s ")
     ("authors" . "%-20s ")
     ("subject" . "%-54s ")
     ("tags" . "(%s)")))
  ;; pgp: verify/decrypt incoming, and sign outgoing with the From key
  (notmuch-crypto-process-mime t)
  (mml-secure-openpgp-sign-with-sender t)
  (notmuch-hello-recent-searches-max 0)     ; drop the full-width recent-search bars
  ;; send via msmtp
  (message-send-mail-function 'message-send-mail-with-sendmail)
  (sendmail-program "/usr/bin/msmtp")
  (message-sendmail-envelope-from 'header)
  :hook
  ;; auto-sign every message you compose (signing needs only your key)
  (message-setup . mml-secure-message-sign-pgpmime)
  :config
  ;; `d' marks a thread deleted (hidden via exclude_tags); run mail-purge to
  ;; actually remove files + expunge from the server. Reverse with `notmuch
  ;; tag -deleted'.
  (define-key notmuch-search-mode-map "d"
    (lambda () (interactive)
      (notmuch-search-tag '("+deleted" "-inbox" "-unread"))
      (notmuch-search-next-thread)))
  (define-key notmuch-show-mode-map "d"
    (lambda () (interactive)
      (notmuch-show-tag '("+deleted" "-inbox")))))

;; notmuch-indicator: unread count in the mode line (text, refreshed on a
;; timer). Reflects the last `G' sync, not live server state.
(use-package notmuch-indicator
  :after notmuch
  :custom
  (notmuch-indicator-args '((:terms "tag:unread" :label "@:")))
  (notmuch-indicator-refresh-count 60)
  (notmuch-indicator-hide-empty-counters t)
  :config
  (notmuch-indicator-mode 1))

;; avy: jump anywhere on screen. M-j, type a couple chars, pick the match.
(use-package avy
  :bind (("M-j"   . avy-goto-char-timer)
         ("M-g w" . avy-goto-word-1)))

;; expand-region: C-= grows the selection by semantic unit (word, sexp, line...).
(use-package expand-region
  :bind ("C-=" . er/expand-region))

;; rainbow-delimiters: color nested parens by depth, in code buffers only.
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(defun super-line-toggle ()
  "Move to indentation, or to line start if already there."
  (interactive)
  (let ((current-point (point)))
    (back-to-indentation)
    (when (= current-point (point))
      (move-beginning-of-line 1))))

(global-set-key (kbd "C-a") 'super-line-toggle)

;; Calc
(use-package calc
  :ensure nil
  :defer t
  :config
  ;; left-to-right like a normal calculator: 12000/60000*100 = 20, not 2e-3
  (setq calc-multiplication-has-precedence nil))

;; ibuffer replaces the plain buffer list: richer marking, filtering, casual menu.
(global-set-key (kbd "C-x C-b") #'ibuffer)

;; casual: transient menus (like magit's). C-o in each mode; loads on first use.
(use-package casual
  :defer t
  :init
  (with-eval-after-load 'calc
    (keymap-set calc-mode-map "C-o" #'casual-calc-tmenu))
  (with-eval-after-load 'calc-ext   ; calc-alg-map only exists once calc-ext is loaded
    (keymap-set calc-alg-map "C-o" #'casual-calc-tmenu))
  (with-eval-after-load 'dired
    (keymap-set dired-mode-map "C-o" #'casual-dired-tmenu))
  (with-eval-after-load 'ibuffer
    (keymap-set ibuffer-mode-map "C-o" #'casual-ibuffer-tmenu))
  (with-eval-after-load 'info
    (keymap-set Info-mode-map "C-o" #'casual-info-tmenu)))

;; Ledger: plain-text accounting. Loads only on ledger files, startup untouched.
(use-package ledger-mode
  :mode "\\.ledger\\'"
  :config
  (setq ledger-clear-whole-transactions t)
  (setq ledger-reports
        '(("budget"  "%(binary) -f %(ledger-file) --budget balance Expenses")
          ("bal"     "%(binary) -f %(ledger-file) balance")
          ("reg"     "%(binary) -f %(ledger-file) register")
          ("monthly" "%(binary) -f %(ledger-file) balance Expenses --monthly")
          ("account" "%(binary) -f %(ledger-file) register %(account)"))))

;; UI niceties: pulse current line on jumps, visual undo tree.
(use-package pulsar
  :defer 1
  :config (pulsar-global-mode 1))

(use-package vundo
  :bind ("C-x u" . vundo)
  :config (setq vundo-roll-back-on-quit nil))

;; helpful: richer C-h f/v/k/C help buffers. Loads on first help lookup.
(use-package helpful
  :bind (([remap describe-function] . helpful-callable)
         ([remap describe-variable] . helpful-variable)
         ([remap describe-key]      . helpful-key)
         ([remap describe-command]  . helpful-command)))

;; hl-todo: highlight TODO/FIXME/NOTE in code.
(use-package hl-todo
  :hook (prog-mode . hl-todo-mode))

;; tmr: timers for study/pomodoro. Loads on first use.
(use-package tmr
  :bind ("C-c T" . tmr)
  :config
  (defun my/tmr-mode-line ()
    "The soonest active tmr timer as [tmr; end: HH:MM; re: LEFT], else empty.
White text; the label \"end\" is gold and \"re\" is green."
    (let ((active (seq-remove #'tmr--timer-finishedp tmr--timers)))
      (if active
          (let* ((soonest (car (seq-sort-by #'tmr--timer-end-date
                                            #'time-less-p active)))
                 (end (format-time-string "%H:%M" (tmr--timer-end-date soonest)))
                 (rem (tmr--format-remaining soonest))
                 (w '(:foreground "white"))
                 (g '(:foreground "#e06c75"))   ; "end" label (red)
                 (r '(:foreground "#98c379")))  ; "re" label
            (concat (propertize " [tmr; " 'face w)
                    (propertize "end"     'face g)
                    (propertize ": "      'face w)
                    (propertize end       'face w)
                    (propertize "; "      'face w)
                    (propertize "re"      'face r)
                    (propertize ": "      'face w)
                    (propertize rem       'face w)
                    (propertize "] "      'face w)))
        "")))
  ;; Append a right-align marker + the TMR segment at the very END of the mode
  ;; line, so ONLY the timer floats to the right edge. misc-info (eglot status,
  ;; etc.) keeps its normal position. `member' guard keeps eval-buffer idempotent.
  (let ((seg '(:eval (my/tmr-mode-line))))
    (unless (member seg (default-value 'mode-line-format))
      (setq-default mode-line-format
                    (append (default-value 'mode-line-format)
                            (list 'mode-line-format-right-align seg)))))
  ;; 1s poll refreshes the countdown; no-op when no timer runs.
  (run-with-timer 1 1 (lambda () (when tmr--timers (force-mode-line-update t)))))

;; No close (x) / new (+) buttons on the tab bar.
(setq tab-bar-close-button-show nil
      tab-bar-new-button-show nil)

;; keycast: show the keys/command you just pressed at the far right of the
;; tab bar (default location right-aligns it).
(use-package keycast
  :config
  (keycast-tab-bar-mode 1))

;; elfeed: RSS reader. C-c w opens it; G refreshes, RET reads in eww.
(use-package elfeed
  :bind (("C-c w" . elfeed)
         :map elfeed-search-mode-map
         ("D" . my/elfeed-delete)      ; purge selected entries from the db
         :map elfeed-show-mode-map
         ("e" . my/elfeed-show-eww))   ; open full page/image in eww
  :hook (elfeed-show-mode . my/elfeed-reading-setup)
  :config
  (defun my/elfeed-delete ()
    "Delete the selected entries from the elfeed database.
Permanent, but reappears on next `G' if the feed still lists it."
    (interactive)
    (elfeed-db-delete (elfeed-search-selected))
    (elfeed-search-update :force))
  (defun my/elfeed-reading-setup ()
    "Center the article, wider column, no line numbers."
    (display-line-numbers-mode -1)
    (setq-local shr-width 90)          ; shr fills the text to ~90 chars, not narrow
    (setq-local olivetti-body-width 95)
    (olivetti-mode 1))
  (defun my/elfeed-show-eww ()
    "Open the current entry's link in eww: full page and full-size image."
    (interactive)
    (eww (elfeed-entry-link elfeed-show-entry)))
  (setq elfeed-feeds
        ;; First tag is the category (filter with s +news / +science / +fun),
        ;; second is the specific source.
        '(("https://archlinux.org/feeds/news/"   news arch)
          ("https://planet.gnu.org/rss20.xml"    news gnu)
          ("https://protesilaos.com/master.xml"  blog prot)
          ("https://api.quantamagazine.org/feed/" science quanta)
          ("https://xkcd.com/rss.xml"            fun xkcd)
          ("https://www.atlasobscura.com/feeds/latest" fun atlas)
          ;; daily: newspaper-cadence, Atlas-style curiosity
          ("https://feeds.kottke.org/main"       daily kottke)
          ("https://apod.nasa.gov/apod.rss"      daily apod)
          ("https://aeon.co/feed.rss"            daily aeon)
          ("https://longreads.com/feed/"         daily longreads)
          ("https://daily.jstor.org/feed/"       daily jstor)
          ("https://www.themarginalian.org/feed/" daily marginalian)
          ;; esoteric: religion, mysticism, esotericism (Filip Holm, full text)
          ("https://itsfilipholm.substack.com/feed" esoteric ltr))))

;; Present a browser User-Agent for url.el fetches. Some CDNs (e.g. Substack's
;; image proxy) refuse Emacs's default "URL/Emacs" UA, leaving gray placeholder
;; boxes in shr where images should load.
(setq url-user-agent
      "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0")

;; erc: built-in IRC. SASL logs into NickServ before joining, so restricted
;; channels (#archlinux) admit you. Password lives in ~/.authinfo, not here.
;; IRC nick/account come from private.el (loaded earlier, near notmuch).

(use-package erc
  :ensure nil
  :commands (erc erc-tls)
  :config
  (dolist (m '(sasl match notifications log nicks)) ; login, highlight, popup, logging, nick colors
    (add-to-list 'erc-modules m))
  (erc-update-modules)
  :custom
  (erc-nick my/irc-nick)
  (erc-sasl-mechanism 'plain)
  (erc-sasl-user my/irc-account)
  (erc-sasl-auth-source-function #'erc-auth-source-search) ; read pass from ~/.authinfo

  (erc-autojoin-channels-alist '(("libera.chat" "#emacs" "#archlinux")))
  (erc-hide-list '("JOIN" "PART" "QUIT"))
  (erc-timestamp-format "[%H:%M] ")
  (erc-fill-function 'erc-fill-static)      ; align nicks in a column
  (erc-fill-static-center 18)
  (erc-track-exclude-types '("JOIN" "PART" "QUIT" "NICK" "MODE"))
  (erc-log-channels-directory "~/.emacs.d/erc-logs/")
  (erc-save-buffer-on-part t)               ; flush log when you leave/quit
  (erc-fill-column 90))

(defun my/libera ()
  "Connect to Libera.Chat with no prompts."
  (interactive)
  (erc-tls :server "irc.libera.chat" :port 6697
           :nick my/irc-nick :user my/irc-account))

;; magit: the git UI. Deferred; only loads on C-x g.
(use-package magit
  :bind ("C-x g" . magit-status))

;; denote: simple linked notes (Prot's). Deferred via :bind. Files live in
;; their own dir so they don't mix with org tasks/exercises.
(use-package denote
  :bind (("C-c N n" . denote)
         ("C-c N o" . denote-open-or-create)
         ("C-c N l" . denote-link)
         ("C-c N b" . denote-backlinks)
         ("C-c N r" . denote-rename-file))
  :config
  (setq denote-directory (expand-file-name "~/Notes/denote/")
        denote-known-keywords '("emacs" "math" "go" "writing"))
  (denote-rename-buffer-mode 1))

;; popper: tame popup buffers (help, compilation, shell) into a toggleable stack.
(use-package popper
  :bind (("C-`"   . popper-toggle)
         ("C-M-`" . popper-cycle)
         ("C-c `" . popper-toggle-type))
  :init
  (setq popper-reference-buffers
        '("\\*Messages\\*" "\\*Warnings\\*" "Output\\*$"
          "\\*Async Shell Command\\*" "\\*compilation\\*"
          help-mode compilation-mode eshell-mode))
  (popper-mode 1)
  (popper-echo-mode 1))

;; logos: distraction-free reading; org headings become slides. Loads on key.
(use-package logos
  :bind (("C-c L" . logos-focus-mode)
         ([remap narrow-to-region] . logos-narrow-dwim)
         ([remap forward-page]     . logos-forward-page-dwim)
         ([remap backward-page]    . logos-backward-page-dwim))
  :config
  (setq logos-outlines-are-pages t
        logos-hide-mode-line t
        logos-hide-fringe t
        logos-scroll-lock t
        logos-variable-pitch t
        logos-olivetti t)
  ;; Shift+down/up = next/prev slide, snapping full-screen. First press narrows
  ;; the current heading (slide 1); after that each press flips to the next.
  (defun my/slide-next ()
    (interactive)
    (if (buffer-narrowed-p) (logos-forward-page-dwim) (logos-narrow-dwim)))
  (defun my/slide-prev ()
    (interactive)
    (when (buffer-narrowed-p) (logos-backward-page-dwim)))
  (define-key logos-focus-mode-map (kbd "<S-down>") #'my/slide-next)
  (define-key logos-focus-mode-map (kbd "<S-up>")   #'my/slide-prev)
  (add-hook 'logos-page-motion-hook #'logos--reveal-entry))

;; org-tree-slide: real slideshow (karthink-style). One heading = one slide,
;; instant snap, big centered text. C-c P starts, S-down/S-up flip slides.
(use-package org-tree-slide
  :after org
  :bind (("C-c P" . org-tree-slide-mode)
         :map org-tree-slide-mode-map
         ("<S-down>" . org-tree-slide-move-next-tree)
         ("<S-up>"   . org-tree-slide-move-previous-tree))
  :config
  (setq org-tree-slide-slide-in-effect nil       ; no animation, instant snap
        org-tree-slide-skip-outline-level 8)
  (add-hook 'org-tree-slide-play-hook (lambda () (text-scale-increase 4)))
  (add-hook 'org-tree-slide-stop-hook (lambda () (text-scale-set 0))))

(add-to-list 'custom-theme-load-path "~/.emacs.d/themes/")

;; Any load-theme disables the current theme first, so themes never stack
;; (raw M-x load-theme otherwise layers the new one over the old = mixed look).
(advice-add 'load-theme :before
            (lambda (&rest _) (mapc #'disable-theme custom-enabled-themes)))

;; Theme: dark = modus-vivendi, light = modus-operandi-tritanopia.
;; Softer black main background (modus default is pure #000000, too sharp).
(defvar my/dark-theme 'ef-trio-dark)
(defvar my/light-theme 'ef-trio-light)

;; Each theme styles its own mode-line. We clear the mode-line faces before
;; every load so no stale override survives a toggle (the old leak bug).
(defun my/load-theme (theme)
  (mapc #'disable-theme custom-enabled-themes)
  (dolist (f '(mode-line mode-line-active mode-line-inactive))
    (set-face-attribute f nil
                        :background 'unspecified :foreground 'unspecified
                        :box 'unspecified :overline 'unspecified
                        :underline 'unspecified :inherit 'unspecified
                        :weight 'unspecified :height 'unspecified))
  (load-theme theme t)
  ;; keycast keys blend into the mode line (themes color them loud otherwise).
  (set-face-attribute 'keycast-key nil
                      :inherit 'mode-line :background 'unspecified
                      :foreground 'unspecified :box nil))

(defun my/toggle-theme ()
  (interactive)
  (my/load-theme (if (memq my/dark-theme custom-enabled-themes)
                     my/light-theme my/dark-theme)))
(global-set-key (kbd "C-c t") #'my/toggle-theme)

(my/load-theme my/dark-theme)

;; Compile
(global-set-key (kbd "<f5>") #'recompile)
(global-set-key (kbd "C-<f5>") #'compile)
(setq compilation-scroll-output 'first-error)
(add-hook 'compilation-filter-hook #'ansi-color-compilation-filter)
(add-to-list 'display-buffer-alist
             '("\\*compilation\\*"
               (display-buffer-reuse-window display-buffer-at-bottom)
               (window-height . 0.3)))

;; Completion popup
(use-package corfu
  :init (global-corfu-mode)
  :config (setq corfu-auto t
                corfu-auto-delay 0.3    ; wait a bit longer so fast typing cancels
                corfu-auto-prefix 3))   ; 3 chars: avoids filtering huge 2-char sets

;; No auto-completion popup in prose: it's the costly case (orderless filtering
;; huge word sets on every keystroke) and distracting while writing. Code keeps
;; auto; in prose, TAB still completes on demand.
(dolist (hook '(text-mode-hook org-mode-hook))
  (add-hook hook (lambda () (setq-local corfu-auto nil))))

;; Emacs 30 adds ispell word-completion in text/org buffers; it errors when no
;; system word-list is installed. Off (we don't want dictionary-guess in corfu).
(setq text-mode-ispell-word-completion nil)

;; LSP
(use-package eglot
  :ensure nil
  :hook (c-mode . eglot-ensure)
  :bind (:map eglot-mode-map ("C-c r" . eglot-rename)))

;; Extra color in C buffers only; 
(defun my/c-extra-colors ()
  (dolist (pair '((font-lock-type-face          . "#2ac3de")
                  (font-lock-function-name-face . "#7aa2f7")
                  (font-lock-preprocessor-face  . "#9ece6a")
                  (font-lock-constant-face      . "#bb9af7")
                  (font-lock-variable-name-face . "#c0caf5")
                  (font-lock-number-face        . "#89ddff")
                  (font-lock-comment-face       . "#565f89")))
    (when (facep (car pair))
      (face-remap-add-relative (car pair) `(:foreground ,(cdr pair))))))
(add-hook 'c-mode-hook    #'my/c-extra-colors)
(add-hook 'c-ts-mode-hook #'my/c-extra-colors)

;; Go: built-in go-ts-mode + gopls via eglot
(add-to-list 'exec-path (expand-file-name "~/go/bin"))   ; so eglot finds gopls
(setq treesit-language-source-alist
      '((go   "https://github.com/tree-sitter/tree-sitter-go")
        (gomod "https://github.com/camdencheek/tree-sitter-go-mod")))
(add-to-list 'auto-mode-alist '("\\.go\\'" . go-ts-mode))
(add-to-list 'auto-mode-alist '("/go\\.mod\\'" . go-mod-ts-mode))

(defun my/go-format-on-save ()
  (when (eglot-managed-p)
    (ignore-errors (eglot-code-actions nil nil "source.organizeImports" t))
    (eglot-format-buffer)))

(add-hook 'go-ts-mode-hook #'eglot-ensure)
(add-hook 'go-ts-mode-hook
          (lambda () (add-hook 'before-save-hook #'my/go-format-on-save nil t)))

;; a little more color
(defun my/go-extra-colors ()
  (dolist (pair '((font-lock-type-face          . "#2ac3de")
                  (font-lock-function-name-face . "#7aa2f7")
                  (font-lock-number-face        . "#89ddff")))
    (when (facep (car pair))
      (face-remap-add-relative (car pair) `(:foreground ,(cdr pair))))))
(add-hook 'go-ts-mode-hook #'my/go-extra-colors)

;; Editing quality of life
(setq confirm-kill-emacs 'y-or-n-p)
(windmove-default-keybindings)
(setq dired-dwim-target t)            ; copy/move defaults to the other dired pane
(setq dired-listing-switches "-alh")

;; dired-preview: preview the file under cursor in a side window while browsing.
(use-package dired-preview
  :hook (dired-mode . dired-preview-mode)
  :config
  (setq dired-preview-delay 0.7          ; wait until you pause before previewing
        dired-preview-max-size (* 2 1024 1024)  ; skip files over 2MB
        ;; don't try to preview heavy/binary types; they're what makes it lag
        dired-preview-ignored-extensions-regexp
        "\\.\\(gz\\|zst\\|zip\\|tar\\|xz\\|rar\\|7z\\|mp4\\|mkv\\|webm\\|mp3\\|iso\\|pdf\\|dvi\\|png\\|jpe?g\\|gif\\)\\'")
  ;; never preview directories (annoying, and dired-subtree covers browsing them)
  (advice-add 'dired-preview--preview-p :before-while
              (lambda (file) (not (file-directory-p file)))))

;; dired-subtree: expand a directory inline (like a file tree) instead of
;; replacing the buffer. TAB toggles the subtree under point.
(use-package dired-subtree
  :after dired
  :bind (:map dired-mode-map
              ("TAB" . dired-subtree-toggle)))

;; dired-narrow: live-filter the listing to matching files. Press / then type.
(use-package dired-narrow
  :after dired
  :bind (:map dired-mode-map
              ("/" . dired-narrow)))

;; dired-collapse: squash single-child dir chains (src/main/java) onto one line.
(use-package dired-collapse
  :hook (dired-mode . dired-collapse-mode))

;; dired-ranger: copy/move files across dired buffers via a paste stack.
;; W copy, X move, Y paste (into the current dir).
(use-package dired-ranger
  :after dired
  :bind (:map dired-mode-map
              ("W" . dired-ranger-copy)
              ("X" . dired-ranger-move)
              ("Y" . dired-ranger-paste)))

(setq make-backup-files nil)
(setq auto-save-default nil)
(global-display-line-numbers-mode t)
(show-paren-mode t)
(electric-pair-mode t)

;; winner-mode: undo/redo window layouts. C-c left = undo, C-c right = redo.
;; Built in. Restores your windows after a popup/help buffer rearranges them.
(winner-mode 1)

;; so-long: auto-detect files with very long lines (minified JS, logs) and strip
;; the expensive modes so they don't freeze redisplay. Built in.
(global-so-long-mode 1)

;; Smoother typing: skip re-fontifying while there's pending keyboard input, so
;; font-lock never stalls a keystroke. Redisplay catches up once you pause.
(setq redisplay-skip-fontification-on-input t)

;; Don't recompact font caches during redisplay; helps with several complex
;; fonts loaded (Martian Mono + variable-pitch prose + Latin Modern Math).
(setq inhibit-compacting-font-caches t)

;; No blinking cursor: drops its timer and the repeated cursor redraws.
(blink-cursor-mode -1)
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;; Session state + editing niceties (all built-in)
(save-place-mode 1)                   ; reopen files at last cursor position
(savehist-mode 1)                     ; persist minibuffer history across restarts
(recentf-mode 1)                      ; track recent files (dashboard uses this)
(setq recentf-max-saved-items 50)
(repeat-mode 1)                       ; after C-x o, press o o o; same for other repeats
(delete-selection-mode 1)             ; typing replaces the active region

;; Keep Customize's auto-writes out of init.el
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file t)
