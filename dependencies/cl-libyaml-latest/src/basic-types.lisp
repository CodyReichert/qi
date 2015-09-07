(in-package :cl-user)
(defpackage libyaml.basic
  (:use :cl :cffi)
  (:import-from :libyaml.util
                :size-t)
  (:export :version-directive-t
           :tag-directive-t
           :encoding-t
           :break-t
           :error-type-t
           :mark-t
           :major
           :minor
           :handle
           :prefix
           :index
           :line
           :column
           :mark-line
           :mark-column)
  (:documentation "Basic data types used throughout libyaml."))
(in-package :libyaml.basic)

(defcstruct version-directive-t
  "The version directive data."
  (major :int)
  (minor :int))

(defcstruct tag-directive-t
  "The tag directive data."
  (handle :string)
  (prefix :string))

(defcenum encoding-t
  "The stream encoding."
  :any-encoding
  :utf8-encoding
  :utf16le-encoding
  :utf16be-encoding)

(defcenum break-t
  "Line break types."
  :any-break
  :cr-break
  :ln-break
  :crln-break)

(defcenum error-type-t
  "Many bad things could happen with the parser and emitter."
  :no-error
  :memory-error
  :reader-error
  :scanner-error
  :parser-error
  :composer-error
  :writer-error
  :emitter-error)

(defcstruct mark-t
  "The pointer position."
  (index size-t)
  (line size-t)
  (column size-t))

(defun mark-line (mark)
  "The line number of a mark."
  (foreign-slot-value mark '(:struct mark-t) 'line))

(defun mark-column (mark)
  "The column number of a mark."
  (foreign-slot-value mark '(:struct mark-t) 'column))
