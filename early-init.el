;;; early-init.el -*- lexical-binding: t; -*-

;; No GC and no file-name-handler lookups during startup, restored after.
(setq gc-cons-threshold most-positive-fixnum)
(defvar my/file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

;; Restore on after-init-hook. This runs even if init.el errors, and BEFORE
;; emacs-startup-hook (where gcmh takes over GC). The 16MB here is a failsafe:
;; if gcmh is ever missing/broken, GC still re-enables instead of staying off
;; forever. gcmh then supersedes this value at runtime for smoother, idle-time GC.
(add-hook 'after-init-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024)
                  file-name-handler-alist my/file-name-handler-alist)))

;; Don't resize the frame when fonts/menu-bar change during init.
(setq frame-inhibit-implied-resize t)

;; Native-comp async warnings go to a log buffer silently instead of popping a
;; *Warnings* buffer. Emacs 30.2 can spin/balloon RAM re-rendering a package's
;; compiler warnings (e.g. dired-subtree's missing dired-filter fn). Log, don't display.
(setq native-comp-async-report-warnings-errors 'silent)
