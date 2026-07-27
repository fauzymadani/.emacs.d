;; -*- lexical-binding: t; -*-

;; Caps Lock → Ctrl, only while Emacs is open
(shell-command "setxkbmap -option ctrl:nocaps")
(add-hook 'kill-emacs-hook (lambda () (shell-command "setxkbmap -option")))

;; Font
(set-face-attribute 'default nil :family "Iosevka Nerd Font Mono" :height 115 :weight 'medium)
(set-face-attribute 'variable-pitch nil :family "STIX Two Text" :height 125)
(setf (alist-get "Latin Modern Math" face-font-rescale-alist nil nil #'equal) 1.25)

(defvar my/note-fonts '(("EB Garamond" . 135) ("STIX Two Text" . 125) ("Charis" . 125)))
(defun my/set-note-font (font)
  "Set the org prose (variable-pitch) FONT and refresh open mixed-pitch buffers."
  (interactive (list (completing-read "Note font: " (mapcar #'car my/note-fonts) nil t)))
  (set-face-attribute 'variable-pitch nil :family font
                      :height (or (cdr (assoc font my/note-fonts)) 125))
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (bound-and-true-p mixed-pitch-mode)
        (mixed-pitch-mode -1)
        (mixed-pitch-mode 1)))))
(global-set-key (kbd "C-c f") #'my/set-note-font)

;; UI cleanup
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(fringe-mode 0)

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

;; Org + LaTeX preview
(use-package org
  :load-path "~/.emacs.d/elpa/org-mode/lisp/")

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
  (add-hook 'org-mode-hook
            (lambda ()
              (run-with-idle-timer
               1 nil (lambda ()
                       (when (derived-mode-p 'org-mode)
                         (org-latex-preview '(16))))))))

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
        org-startup-folded 'nofold)
  (add-hook 'org-mode-hook #'visual-line-mode)
  (add-hook 'org-mode-hook (lambda () (display-line-numbers-mode -1))))

;; Quick capture
(setq org-capture-templates
      '(("t" "Task" entry (file "~/org/tasks.org")
         "* TODO %?\n  SCHEDULED: %t\n")))
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
(use-package auctex)

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
        org-crypt-key "fauzymadani3@gmail.com"
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
  (setq dashboard-startup-banner 'official
        dashboard-center-content t
        dashboard-items '((recents . 5)))
  (dashboard-setup-startup-hook))

(use-package which-key
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
         ("M-g g" . consult-goto-line)))

(use-package embark
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)))

(use-package embark-consult
  :after (embark consult))

(use-package yasnippet
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
  :config
  ;; left-to-right like a normal calculator: 12000/60000*100 = 20, not 2e-3
  (setq calc-multiplication-has-precedence nil))

(use-package casual
  :after calc
  :config
  (keymap-set calc-mode-map "C-o" #'casual-calc-tmenu)
  (with-eval-after-load 'calc-ext   ; calc-alg-map only exists once calc-ext is loaded
    (keymap-set calc-alg-map "C-o" #'casual-calc-tmenu)))

;; Theme: dark = Gruber Darker, light = whiteboard (built-in)
(use-package gruber-darker-theme :ensure t :defer t)

(defvar my/dark-theme 'gruber-darker)
(defvar my/light-theme 'whiteboard)

(defun my/load-theme (theme)
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme theme t))

(defun my/toggle-theme ()
  (interactive)
  (my/load-theme (if (memq my/dark-theme custom-enabled-themes)
                     my/light-theme my/dark-theme)))
(global-set-key (kbd "C-c t") #'my/toggle-theme)

(my/load-theme my/dark-theme)

;; Light theme: vanilla grey mode line. Dark theme: cool background + reset
;; mode-line-active (Gruber doesn't theme it) so no grey lingers from light.
(defvar my/dark-bg "#0d1014")

(defun my/theme-tweaks (&rest _)
  (if (memq my/light-theme custom-enabled-themes)
      (progn
        (dolist (f '(mode-line mode-line-active))
          (set-face-attribute f nil
                              :background "grey75" :foreground "black"
                              :box '(:line-width -1 :style released-button)
                              :overline nil :underline nil :inherit nil :height 1.0))
        (set-face-attribute 'mode-line-inactive nil
                            :background "grey90" :foreground "grey20" :weight 'light
                            :box '(:line-width -1 :color "grey75")
                            :overline nil :underline nil :inherit nil :height 1.0))
    (set-face-attribute 'default nil :background my/dark-bg)
    (set-face-attribute 'mode-line-active nil
                        :background 'unspecified :foreground 'unspecified :box 'unspecified
                        :overline 'unspecified :underline 'unspecified :weight 'unspecified
                        :height 'unspecified :inherit 'mode-line)))
(add-hook 'enable-theme-functions #'my/theme-tweaks)
(my/theme-tweaks)                     ; startup theme loaded before this hook existed

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
                corfu-auto-delay 0.2
                corfu-auto-prefix 2))

;; LSP
(use-package eglot
  :ensure nil
  :hook (c-mode . eglot-ensure))

;; Extra color in C buffers only; buffer-local so other modes stay minimal
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

;; A little color for Go, still minimal
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

(setq make-backup-files nil)
(setq auto-save-default nil)
(global-display-line-numbers-mode t)
(show-paren-mode t)
(electric-pair-mode t)
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;; Keep Customize's auto-writes out of init.el
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file t)
