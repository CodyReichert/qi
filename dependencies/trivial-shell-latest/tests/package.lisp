(in-package #:common-lisp-user)

(defpackage #:trivial-shell-test
  (:use #:common-lisp #:lift #:trivial-shell)
  (:shadowing-import-from #:trivial-shell 
			  #:with-timeout
			  #:timeout-error))

#|
(defpackage #:p1
  (:use #:common-lisp))

(defpackage #:p2
  (:use #:common-lisp))


(defun p1::f ()
  :p1)

(defun p2::f ()
  :p2)

(defpackage p3
  (:use #:common-lisp)
  (:shadowing-import-from #:p1 #:f))

(p3::f)

|#