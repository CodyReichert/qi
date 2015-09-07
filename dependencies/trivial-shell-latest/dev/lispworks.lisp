(in-package #:trivial-shell)

(defun %shell-command (command input)
  (when input
    (error "This version of trivial-shell does not support the input parameter."))
  ;; BUG: Lispworks combines output and error streams
  (let ((output (make-string-output-stream)))
    (unwind-protect
      (let ((status
             (system:call-system-showing-output
              command
              :prefix ""
              :show-cmd nil
              :output-stream output)))
        (values (get-output-stream-string output) nil status))
      (close output))))

(defun %os-process-id ()
  (error 'unsupported-function-error :function 'os-process-id))

(defun %get-env-var (name)
  (lw:environment-variable name))

(defun %exit (code)
  (lw:quit :status code))
