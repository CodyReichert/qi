(in-package :cl-user)
(defpackage libyaml.util
  (:use :cl :cffi)
  (:export :size-t)
  (:documentation "FFI utilities."))
(in-package :libyaml.util)

(defmacro define-size-t ()
  "Define size_t according to the architecture."
  (if (eql (foreign-type-size '(:pointer :int)) 8)
      ;; 64 bits
      `(defctype size-t :unsigned-long "The size_t type.")
      ;; 32 bits
      `(defctype size-t :unsigned-int "The size_t type.")))

(define-size-t)
