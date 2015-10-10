(defpackage #:gzip-system (:use :cl :asdf))

(in-package :gzip-system)

(defsystem gzip-stream
  :serial t
  :version "0.2.8"
  :components ((:file "package")
               (:file "ifstar")
               (:file "inflate")
               (:file "gzip-stream")
               (:file "gzip"))
  :depends-on (:salza2 :flexi-streams :trivial-gray-streams))


