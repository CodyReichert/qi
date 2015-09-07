(in-package #:trivial-shell)

(defun shell-command (command input)
  (error 'unsupported-function-error :function 'shell-command))

(defun %os-process-id ()
  (error 'unsupported-function-error :function 'os-process-id))

(defun %get-env-var (name)
  (ext:getenv name))

(defun %exit (code)
  (ext:exit code))
