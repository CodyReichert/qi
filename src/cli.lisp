(in-package :cl-user)
(defpackage qi.cli
  (:use :cl :qi)
  (:import-from :trivial-shell
                :shell-command)
  (:import-from :qi.packages
                :make-dependency)
  (:import-from :qi.paths
                :+qi-directory+)
  (:import-from :qi.util
                :sym->str))
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


;;; Qi Upgrade ($ qi --upgrade / $ qi -u) internals

(defvar git-pull-qi
  (concatenate 'string "git -C " (namestring +qi-directory+) " pull")
  "The text of a git command that runs 'git pull' from the Qi
  installation directory.")

(defvar git-rev-parse-qi
  (concatenate 'string "git -C " (namestring +qi-directory+) " rev-parse HEAD")
  "The text of a git command that runs 'git rev-parse HEAD' from the Qi
  installation directory to get the hash of the current revision.")

(defun run-qi-upgrade ()
  "Upgrade Qi. Running `qi --upgrade' will pull the latest version from git."
  ;; We should allow upgrading to a specific version, which should
  ;; just be a matter of pulling, and checking out a tag (at least
  ;; while git is still the installation method.
  (cond ((probe-file +qi-directory+)
         (format t "~%---> Upgrading Qi")
         (multiple-value-bind (o) (shell-command git-pull-qi)
           (if (string= "Already up-to-date." (subseq o 0 19)) ;kind of a hack
               (format t "~%~3t✓ Qi is already up to date.~%")
               (multiple-value-bind (v) (shell-command git-rev-parse-qi)
                 (format t "~%~3t✓ Successful upgrade: ~A~%" v)))))
        (t
         (format t "~%---X Qi not installed, or not in expected directory.~%")
         (format t "~%~3tTry running 'cd /path/to/qi && git pull' instead."))))

;;;

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
               (run-qi-upgrade))
  (when-option (options :install)
               (opt-install (getf options :install)))
  (when-option (options :install-deps)
               (opt-install-deps (getf options :install-deps))))
