(in-package :cl-user)
(defpackage qi.util
  (:use :cl)
  (:export :sym->str
           :is-tar-url?
           :is-git-url?
           :is-gh-url?))
(in-package :qi.util)

;; Code:

(defun sym->str (sym)
  (string-downcase (symbol-name sym)))

(defun is-tar-url? (str)
  "Does <str> have a tarball extension."
  (or (ppcre:scan "^https?.*.tgz" str)
      (ppcre:scan "^https?.*tar.gz" str)))

(defun is-git-url? (str)
  "Is <str> a git:// or .git url."
  (or (ppcre:scan "^git://.*" str)
      (ppcre:scan ".*.git" str)))

(defun is-gh-url? (str)
  "Is <str> a github url."
  (ppcre:scan "^https?//github.*" str))
