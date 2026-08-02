;;; early-init.el -*- lexical-binding: t; -*-

;; No GC and no file-name-handler lookups during startup, restored after.
;; 16MB threshold afterwards: no constant GC churn, but not memory-hungry.
(setq gc-cons-threshold most-positive-fixnum)
(defvar my/file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024)
                  file-name-handler-alist my/file-name-handler-alist)))

;; Don't resize the frame when fonts/menu-bar change during init.
(setq frame-inhibit-implied-resize t)

;; Native-comp async warnings go to a log buffer silently instead of popping a
;; *Warnings* buffer. Emacs 30.2 can spin/balloon RAM re-rendering a package's
;; compiler warnings (e.g. dired-subtree's missing dired-filter fn). Log, don't display.
(setq native-comp-async-report-warnings-errors 'silent)
