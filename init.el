;; -*- lexical-binding: t; -*-

;; === Caps Lock → Ctrl (only while Emacs is open) ===
(shell-command "setxkbmap -option ctrl:nocaps")
(add-hook 'kill-emacs-hook (lambda () (shell-command "setxkbmap -option")))

;; === Font ===
(set-face-attribute 'default nil :height 140)
(set-face-attribute 'variable-pitch nil :family "Merriweather" :height 1.10)
(setf (alist-get "Merriweather"      face-font-rescale-alist nil nil #'equal) 0.88)
(setf (alist-get "Latin Modern Math" face-font-rescale-alist nil nil #'equal) 1.25)

;; === UI cleanup ===
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(fringe-mode 0)

;; === Package management ===
;; Must be before package-initialize so org fork shadows built-in org
(add-to-list 'load-path "~/.emacs.d/elpa/org-mode/lisp/")
(require 'package)
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("gnu"   . "https://elpa.gnu.org/packages/")))
(package-initialize)

;; Bootstrap use-package if not installed
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;; === Org + LaTeX preview ===
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
        org-latex-preview-persist-expiry 30)
  (plist-put org-format-latex-options :background "Transparent")
  (plist-put org-latex-preview-appearance-options :scale 1.0)
  (plist-put org-latex-preview-appearance-options :zoom
             (+ (/ (face-attribute 'default :height) 100.0) 0.15)))

;; === Org appearance ===
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
        org-hide-leading-stars t
        org-ellipsis " ▾"
        org-startup-folded 'nofold)
  (add-hook 'org-mode-hook #'visual-line-mode)
  (add-hook 'org-mode-hook (lambda () (display-line-numbers-mode -1))))

;; === Packages ===
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
                            ("pmatrix"  "\\begin{pmatrix}\n?\n\\end{pmatrix}"  nil))
        ))

(use-package org-modern
  :hook (org-mode . org-modern-mode))

(use-package mixed-pitch
  :hook (org-mode . mixed-pitch-mode))

(use-package olivetti
  :hook (org-mode . olivetti-mode)
  :config
  (setq olivetti-body-width 80)
  (set-face-attribute 'olivetti-fringe nil :background (face-attribute 'default :background)))

(use-package dashboard
  :config
  (setq dashboard-startup-banner 'official)
  (dashboard-setup-startup-hook))

(use-package which-key
  :config (which-key-mode))

(use-package mood-line
  :config (mood-line-mode))

(use-package vertico
  :config (vertico-mode))

(use-package orderless
  :config
  (setq completion-styles '(orderless basic)))

(use-package marginalia
  :config (marginalia-mode))

(use-package consult
  :bind (("C-x b"   . consult-buffer)
         ("C-s"     . consult-line)
         ("M-g g"   . consult-goto-line)))

(use-package embark
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)))

(use-package embark-consult
  :after (embark consult))

(use-package yasnippet
  :config (yas-global-mode 1))

;; === Theme ===
(use-package modus-themes
  :config
  (load-theme 'modus-operandi t))

;; === Basic quality of life ===
(setq make-backup-files nil)
(setq auto-save-default nil)
(global-display-line-numbers-mode t)
(show-paren-mode t)
(electric-pair-mode t)
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil)
 '(package-vc-selected-packages
   '((org-mode :url "https://code.tecosaur.net/tec/org-mode" :branch
               "dev"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
