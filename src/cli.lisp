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
     :description "Install packages, named on the command-line or specified in qi.yaml
                   If named on the command-line, packages will be
                   installed globally into the Qi shared packages
                   directory.

                   If specified in a qi.yaml file, packages will be
                   installed into the local project's .dependencies
                   directory."
     :short #\i
     :long "install"
     :meta-var "PACKAGES"))


(defun unknown-option (cond)
  (format t "[warning] dropping ~s option, it is unknown~%" (opts:option cond))
  (invoke-restart 'opts:skip-option))


(defmacro when-option ((options opt) &body body)
  `(let ((it (getf ,options ,opt)))
     (when it
       ,@body)))


;; Options parsing
(multiple-value-bind (options free-args)
    (handler-case
        (handler-bind ((opts:unknown-option #'unknown-option))
          (opts:get-opts))
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
               (if free-args
                   (loop for arg in free-args
                      ;; hacky test returns true if the arg ends in "qi.yaml"
                      do (if (eql 7 (string>= (reverse arg) (reverse "qi.yaml")))
                             (qi:install-from-qi-file arg)
                           (progn (format t "~%---> Installing ~s" arg)
                                  (qi:install-global arg)
                                  (format t "~%~3t✓ Successfully installed ~S" arg))))
                 ;; When run as `qi --install` without extra arguments,
                 ;; look for a qi.yaml in the current directory
                 (let ((qi-file (fad:merge-pathnames-as-file (uiop:getcwd) "qi.yaml")))
                   (qi:install-from-qi-file qi-file)))))
