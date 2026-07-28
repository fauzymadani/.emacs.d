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
