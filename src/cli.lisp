(in-package :cl-user)
(defpackage qi.cli
  (:use :cl :qi)
  (:import-from :qi.manifest
                :+manifest-directory+
                :+manifest-upstream+)
  (:import-from :qi.packages
                :make-dependency)
  (:import-from :qi.paths
                :+qi-directory+)
  (:import-from :qi.util
                :sym->str
                :update-repository))
(in-package :qi.cli)

(asdf:load-system :unix-opts)

;; code:

(opts:define-opts
    (:name :help
     :description "Print this help menu."
     :short #\h
     :long "help")
    (:name :upgrade
     :description "Upgrade Qi (pull the latest from git)"
     :short #\u
     :long "upgrade")
    (:name :update-manifest
     :description "Update the Qi manifest"
     :short #\m
     :long "update-manifest")
    (:name :install
     :description "Install a package from Qi (global by default)"
     :short #\i
     :long "install"
     :arg-parser #'identity
     :meta-var "PACKAGE")
    (:name :install-deps
     :description "Install local dependencies for the specified system"
     :short #\d
     :long "install-deps"
     :arg-parser #'identity
     :meta-var "ASD-FILE"))


(defun unknown-option (cond)
  (format t "[warning] dropping ~s option, it is unknown~%" (opts:option cond))
  (invoke-restart 'opts:skip-option))


(defmacro when-option ((options opt) &body body)
  `(let ((it (getf ,options ,opt)))
     (when it
       ,@body)))


;;; Qi install-deps ($ qi --install-deps project.asd)
(defun opt-install-deps (input)
  "Install the dependencies locally for the system definition file provided as INPUT."
  (load input)
  (qi:install (pathname-name input)))

;;; Qi Install ($ qi --install [package] / $ qi -i [package]) internals
(defun opt-install (opt)
  "Install a package to Qi global package directory. The package will be available
in all future lisp sessions."
  (format t "~%---> Installing ~s" opt)
  (handler-bind ((error #'(lambda (x)
                           (format t "~%~3t× An error occured: ~A~%" x)
                           (return-from opt-install nil))))
    (qi:install-global opt)
    (format t "~%~3t✓ Successfully installed ~S" opt)))

;;;
;; Options parsing

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
     :suffix "Issues https://github.com/CodyReichert/qi"
     :usage-of "qi"
     :args "[Free-Args]"))
  (when-option (options :upgrade)
               (update-repository :name "Qi"
                                  :directory +qi-directory+
                                  :upstream "https://github.com/CodyReichert/qi.git"))
  (when-option (options :update-manifest)
               (update-repository :name "Qi manifest"
                                  :directory +manifest-directory+
                                  :upstream +manifest-upstream+))
  (when-option (options :install)
               (opt-install (getf options :install)))
  (when-option (options :install-deps)
               (opt-install-deps (getf options :install-deps))))
