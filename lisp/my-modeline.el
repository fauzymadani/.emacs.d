;;; my-modeline.el --- Bespoke Refined Classic Emacs Mode-Line -*- lexical-binding: t; -*-

;;; Commentary:
;; A minimal, clean, and informative mode-line that preserves Emacs' iconic
;; identity (U:---, **-, %p, L%l:C%c) while utilizing modern Emacs 29+
;; right-alignment.  All colors are left to the active theme.

;;; Code:

(require 'subr-x)

(defun my-modeline--flags ()
  "Render Emacs flags: Mule info, client, modified status, remote."
  (concat
   (format-mode-line mode-line-mule-info)
   (format-mode-line mode-line-client)
   (format-mode-line mode-line-modified)
   (format-mode-line mode-line-remote)))

(defun my-modeline--buffer-id ()
  "Render buffer name."
  (propertize "%b"
              'face 'mode-line-buffer-id
              'help-echo (or (buffer-file-name) (buffer-name))))

(defun my-modeline--narrow ()
  "Display [Narrow] when buffer is narrowed."
  (when (buffer-narrowed-p)
    (propertize " [Narrow]" 'help-echo "Buffer is narrowed")))

(defun my-modeline--size ()
  "Display buffer/file size via %I (e.g. 12k, 1.4M)."
  (format-mode-line " %I"))

(defun my-modeline--major-mode ()
  "Display the major mode name, safely rendered via format-mode-line."
  (propertize (format "(%s)" (format-mode-line mode-name))
              'help-echo (format "Major mode: %s\nmouse-1: Major mode menu"
                                 (format-mode-line mode-name))
              'mouse-face 'mode-line-highlight
              'local-map mode-line-major-mode-keymap))

(defun my-modeline--vc ()
  "Display version control (Git) status if present."
  (when vc-mode
    (propertize (concat (string-trim vc-mode) "  ")
                'help-echo (format "Version Control: %s" (string-trim vc-mode)))))

(defun my/tmr-mode-line ()
  "The soonest active tmr timer as [tmr; end: HH:MM; re: LEFT], else empty.
Requires the `tmr' package.  Safely returns \"\" when tmr is not loaded."
  (if (and (bound-and-true-p tmr--timers)
           (fboundp 'tmr--timer-finishedp))
      (let ((active (seq-remove #'tmr--timer-finishedp tmr--timers)))
        (if active
            (let* ((soonest (car (seq-sort-by #'tmr--timer-end-date
                                              #'time-less-p active)))
                   (end (format-time-string "%H:%M" (tmr--timer-end-date soonest)))
                   (rem (tmr--format-remaining soonest)))
              (format " [tmr; end: %s; re: %s] " end rem))
          ""))
    ""))

(defun my-modeline--flymake ()
  "Display Flymake diagnostics if active."
  (when (and (bound-and-true-p flymake-mode)
             (fboundp 'flymake--mode-line-format))
    (concat (flymake--mode-line-format) "  ")))

(defun my-modeline--position ()
  "Display buffer position (scroll %, line, and column)."
  (format-mode-line " %p  L%l:C%c "))

(defun my-modeline-setup ()
  "Configure the default mode-line format."
  (setq-default mode-line-format
    (list
     ;; Left Side
     " "
     '(:eval (my-modeline--flags))
     "  "
     '(:eval (my-modeline--buffer-id))
     '(:eval (my-modeline--size))
     '(:eval (my-modeline--narrow))
     "  "
     '(:eval (my-modeline--major-mode))
     mode-line-process

     ;; Right Alignment Anchor (Emacs 29+) 
     'mode-line-format-right-align

     ;; Right Side
     '(:eval (my-modeline--vc))
     '(:eval (when (fboundp 'my/tmr-mode-line)
               (my/tmr-mode-line)))
     '(:eval (my-modeline--flymake))
     '(:eval (my-modeline--position))
     " ")))

;; Automatically activate on load
(my-modeline-setup)

(provide 'my-modeline)
;;; my-modeline.el ends here
