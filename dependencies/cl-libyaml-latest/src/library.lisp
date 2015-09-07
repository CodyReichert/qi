(in-package :cl-user)
(defpackage libyaml.lib
  (:use :cl :cffi)
  (:documentation "Load the libyaml library."))
(in-package :libyaml.lib)

(define-foreign-library libyaml
  (:darwin (:or "libyaml.dylib" "libyaml-0.2.dylib"))
  (:unix  (:or "libyaml.so" "libyaml-0.so.2" "libyaml-0.so.2.0.4"))
  (:win32 "libyaml.dll")
  (t (:default "libyaml")))

(use-foreign-library libyaml)
