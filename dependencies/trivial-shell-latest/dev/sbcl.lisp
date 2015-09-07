(in-package #:trivial-shell)

#-(or win32 (not sb-thread))
(defun %shell-command (command input #+(or) output)
  (with-input (input-stream (or input :none))
    (let* ((process (sb-ext:run-program
                     *bourne-compatible-shell*
                     (list "-c" command)
		     :wait nil :input input-stream 
		     :output :stream
		     :error :stream))
	   (output-thread (sb-thread:make-thread
                           #'(lambda ()
                               (file-to-string-as-lines
                                (sb-impl::process-output process)))))
	   (error-thread (sb-thread:make-thread
                          #'(lambda ()
                              (file-to-string-as-lines
                               (sb-impl::process-error process))))))
      (let ((error-code
	     (sb-impl::process-exit-code (sb-impl::process-wait process)))
            (output-string (sb-thread:join-thread output-thread))
            (error-string (sb-thread:join-thread error-thread)))
        (close (sb-impl::process-output process))
        (close (sb-impl::process-error process))
        (values output-string error-string error-code)))))

#+(or win32 (not sb-thread))
(defun %shell-command (command input #+(or) output)
  (%shell-command-using-temporary-file command input))

(defun %shell-command-using-temporary-file (command input)
  (when input
    (error "This version of trivial-shell does not support the input parameter."))
  (let ((output (open-temporary-file))
	(error (open-temporary-file)))
    (unwind-protect
	 (let ((process
		(sb-ext:run-program
		 *bourne-compatible-shell*
		 (list "-c" (format nil "~a > ~a 2> ~a"
				    command 
				    (namestring output)
				    (namestring error)))
		 :wait t
		 :input nil
		 :output nil
		 :error nil)))
	   (let ((error-code (sb-impl::process-exit-code
			      (sb-impl::process-wait process)))
		 (output-string (read-temporary-file output))
		 (error-string (read-temporary-file error)))
	     (values output-string error-string error-code)))
      ;; cleanup
      (delete-file output)
      (delete-file error))))

(defun open-temporary-file ()
  (pathname
   (loop thereis (open (format nil "TEMP-~D" (random 100000))
		       :direction :probe :if-exists nil
		       :if-does-not-exist :create))))

(defun read-temporary-file (file-stream)
  (with-open-file (stream file-stream)
    (let ((buffer (make-array (file-length stream)
			      :element-type 'character)))
      (subseq buffer 0 (read-sequence buffer stream)))))


(defun create-shell-process (command wait)
  (sb-ext:run-program
   *bourne-compatible-shell*
   (list "-c" command)
   :input nil :output :stream :error :stream :wait wait))

(defun process-alive-p (process)
  (sb-ext:process-alive-p process))

(defun process-exit-code (process)
  (sb-ext:process-exit-code process))

(defun %os-process-id ()
  (error 'unsupported-function-error :function 'os-process-id))

(defun %get-env-var (name)
  (sb-ext:posix-getenv name))

(defun symbol-if-external (name package)
  (multiple-value-bind (symbol s) (find-symbol name package)
    (when (eq s :external)
      symbol)))

(defun %exit (code)
  (let ((exit-sym (symbol-if-external "EXIT" "SB-EXT")))
    (if exit-sym
        (funcall exit-sym :code code)
        (let ((quit-sym (symbol-if-external "QUIT" "SB-EXT")))
          (if quit-sym
              (funcall quit-sym :unix-status code :recklessly-p t)
              (error "SBCL version without EXIT or QUIT."))))))
