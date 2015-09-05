(in-package :cl-user)
(defpackage qi.util
  (:use :cl)
  (:export :sym->str))
(in-package :qi.util)

;; Code:

(defun sym->str (sym)
  (string-downcase (symbol-name sym)))
