(in-package #:trivial-shell)

(defun %shell-command (command input)
  (let* ((process (create-shell-process command t input))
         (output (file-to-string-as-lines 
                  (ccl::external-process-output-stream process)))
         (error (file-to-string-as-lines
                 (ccl::external-process-error-stream process))))
    (close (ccl::external-process-output-stream process))
    (close (ccl::external-process-error-stream process))
    (values output
            error
            (process-exit-code process))))

(defun create-shell-process (command wait &optional input)
  (with-input (input-stream (or input :none))
   (ccl:run-program
    *bourne-compatible-shell*
    (list "-c" command)
    :input input-stream :output :stream :error :stream
    :wait wait)))

(defun process-alive-p (process)
  (eq (nth-value 0 (ccl:external-process-status process)) :running))

(defun process-exit-code (process)
  (nth-value 1 (ccl:external-process-status process)))

(defun %os-process-id ()
  (error 'unsupported-function-error :function 'os-process-id))

(defun %get-env-var (name)
  (ccl::getenv name))

(defun %exit (code)
  (ccl:quit code))
