(in-package :cl-user)
(defpackage qi.util
  (:use :cl)
  (:export :asdf-system-path
           :load-asdf-system
           :is-tar-url?
           :is-git-url?
           :is-gh-url?
           :is-hg-url?
           :sym->str))
(in-package :qi.util)

;; Code:

(defun sym->str (sym)
  "Takes a symbol (:sym), and returns it as a string (\"sym\"), unless
<sym> is already a string. In both cases in downcases the string."
  (if (symbolp sym)
      (string-downcase (symbol-name sym))
      (string-downcase sym)))

(defun is-tar-url? (str)
  "Does <str> have a tarball extension."
  (or (ppcre:scan "^https?.*.tgz" str)
      (ppcre:scan "^https?.*tar.gz" str)))

(defun is-git-url? (str)
  "Is <str> a git:// or .git url."
  (or (ppcre:scan "^git://.*" str)
      (ppcre:scan ".*.git" str)))

(defun is-hg-url? (str)
  "Is <str> a hg:// or .hg url."
  (or (ppcre:scan "^hg://.*" str)
      (ppcre:scan ".*.hg" str)))

(defun is-gh-url? (str)
  "Is <str> a github url."
  (ppcre:scan "^https://github.*" str))


(defun asdf-system-path (sys)
  "Find the pathname for a system, return NIL if it's not available."
  (handler-case
      (asdf:component-pathname (asdf:find-system sys))
    (error () () nil)))


(defun load-asdf-system (sys)
  (handler-bind ((warning #'muffle-warning))
    (ignore-errors
      (setf *load-verbose* nil)
      (setf *load-print* nil)
      (setf *compile-verbose* nil)
      (setf *compile-print* nil)
      (asdf:load-system sys :verbose nil))))
