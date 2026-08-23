;;; my-blog.el --- Fast blog post creator for ox-publish -*- lexical-binding: t; -*-

;;; Commentary:
;; Minimal post creation and publishing helper for Org-mode blogs.

;;; Code:

(defvar my/blog-dir "~/blog/"
  "Root directory of the ox-publish blog repository.")

(defun my/new-blog-post (title)
  "Create a new blog post in `my/blog-dir'/content/ with metadata pre-filled."
  (interactive "sPost Title: ")
  (let* ((content-dir (expand-file-name "content/" my/blog-dir))
         (date (format-time-string "%Y-%m-%d"))
         (slug (replace-regexp-in-string "[^a-z0-9]+" "-" (downcase title)))
         (filename (format "%s-%s.org" date slug))
         (filepath (expand-file-name filename content-dir)))
    (make-directory content-dir t)
    (find-file filepath)
    (when (zerop (buffer-size))
      (insert (format "#+TITLE: %s\n" title))
      (insert "#+AUTHOR: fauzy\n")
      (insert (format "#+DATE: %s\n" date))
      (insert "#+OPTIONS: toc:nil num:nil\n\n")
      (insert "* "))
    (goto-char (point-max))))

(defun my/blog-preview ()
  "Build the site and open public/index.html in the default web browser."
  (interactive)
  (let ((default-directory (expand-file-name my/blog-dir)))
    (message "Building blog...")
    (call-process "emacs" nil "*blog-build*" nil "--batch" "-Q" "-l" "build.el")
    (browse-url (expand-file-name "public/index.html" my/blog-dir))
    (message "Blog built and opened in browser.")))

(global-set-key (kbd "C-c b") #'my/new-blog-post)
(global-set-key (kbd "C-c B") #'my/blog-preview)

(provide 'my-blog)
;;; my-blog.el ends here
