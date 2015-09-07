(in-package #:common-lisp-user)

(unless (and (find-package '#:com.metabang.trivial-timeout)
	     (find-symbol (symbol-name '#:with-timeout)
			  '#:com.metabang.trivial-timeout)
	     (fboundp (find-symbol (symbol-name '#:with-timeout)
			  '#:com.metabang.trivial-timeout)))	     
(defpackage #:com.metabang.trivial-timeout
  (:use #:common-lisp)
  (:nicknames #:trivial-timeout)
  (:export 
   #:with-timeout
   #:timeout-error)))
