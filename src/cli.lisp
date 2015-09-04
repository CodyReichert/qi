(in-package :cl-user)
(defpackage qi.cli
  (:use :cl))
(in-package :qi.cli)

(asdf:load-system :unix-opts)

;; code:

(opts:define-opts
    (:name :help
     :description "Print this help menu."
     :short #\h
     :long "help")
    (:name :install
     :description "Install a package from Qi (local by default)"
     :short #\i
     :long "install"
     :arg-parser #'identity
     :command "install"
     :meta-var "PACKAGE"))


(defun unknown-option (cond)
  (format t "[warning] dropping ~s option, it is unknown~%" (opts:option cond))
  (invoke-restart 'opts:skip-option))


(defmacro when-option ((options opt) &body body)
  `(let ((it (getf ,options ,opt)))
     (when it
       ,@body)))

(defun opt-install (opt)
  (format t "~%---> Installing ~a~%" opt))


(multiple-value-bind (options); free-args)
    (handler-case
        (handler-bind ((opts:unknown-option #'unknown-option))
          (opts:get-opts))
      (opts:missing-arg (condition)
        (format t "[fatal] ~s requires an argument~%" (opts:option condition)))
      (opts:arg-parser-failed (condition)
        (format t "[fatal] ~s not an argument of ~s~%"
                (opts:raw-arg condition)
                (opts:option condition))))
  (when-option (options :help)
    (opts:describe
     :prefix "Qi - A simple, open, free package manager for Common Lisp."
     :suffix "Issues https://github.com/cl-qi/qi"
     :usage-of "qi"
     :args "[Free-Args]"))
  (when-option (options :install)
    (opt-install (getf options :install))))
