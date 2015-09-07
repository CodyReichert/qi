(in-package :cl-user)
(defpackage yaml.float
  (:use :cl)
  (:export :*float-strategy*
           :not-a-number
           :positive-infinity
           :negative-infinity)
  (:documentation "Handle IEEE floating point values."))
(in-package :yaml.float)

(defparameter *float-strategy* :keyword)

#+sbcl
(defparameter *sbcl-nan-value*
  (sb-int:with-float-traps-masked (:overflow :invalid :divide-by-zero)
    (- sb-ext:double-float-positive-infinity
       sb-ext:double-float-positive-infinity)))

(defun not-a-number ()
  (case *float-strategy*
    (:error
     (error 'yaml.error:unsupported-float-value))
    (:keyword
     :NaN)
    (:best-effort
     #+sbcl *sbcl-nan-value*
     #+allegro #.excl:*nan-double*
     #-(or sbcl allegro) :NaN)))

(defun positive-infinity ()
  (case *float-strategy*
    (:error
     (error 'yaml.error:unsupported-float-value))
    (:keyword
     :+Inf)
    (:best-effort
     #+sbcl sb-ext:double-float-positive-infinity
     #+allegro #.excl:*infinity-double*
     #-(or sbcl allegro) :+Inf)))

(defun negative-infinity ()
  (case *float-strategy*
    (:error
     (error 'yaml.error:unsupported-float-value))
    (:keyword
     :-Inf)
    (:best-effort
     #+sbcl sb-ext:double-float-negative-infinity
     #+allegro #.excl:*negative-infinity-double*
     #-(or sbcl allegro) :-Inf)))
