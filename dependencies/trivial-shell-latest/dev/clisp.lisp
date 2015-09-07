(in-package #:metashell)

(defun %shell-command (command input)
  (when input
    (error "This version of trivial-shell does not support the input parameter."))
  ;; BUG: CLisp doesn't allow output to user-specified stream
  (values
   nil
   nil
   (ext:run-shell-command  command :output :terminal :wait t)))

(defun %os-process-id ()
  (error 'unsupported-function-error :function 'os-process-id))

(defun %get-env-var (name)
  (ext:getenv name))

(defun %exit (code)
  (ext:exit code))
