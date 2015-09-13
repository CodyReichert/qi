(in-package :cl-user)
(defpackage qi.util
  (:use :cl)
  (:export :asdf-system
           :is-tar-url?
           :is-git-url?
           :is-gh-url?
           :sym->str))
(in-package :qi.util)

;; Code:

(defun sym->str (sym)
  ":<sym> -> \"sym\"."
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


(defun asdf-system-path (sys)
  "Find the pathname for a system, return NIL if it's not available."
  (handler-case
      (asdf:component-pathname (asdf:find-system sys))
    (error () () nil)))
