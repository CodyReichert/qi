(in-package #:trivial-shell)

(defun %shell-command (command input)
  (error 'unsupported-function-error :function 'shell-command))

(defun %os-process-id ()
  (error 'unsupported-function-error :function 'os-process-id))

(defun %get-env-var (name)
  (cdr (assoc name ext:*environment-list* :test #'string=))

(defun %exit (code)
  (ext:quit :status code))
