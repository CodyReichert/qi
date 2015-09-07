;;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Base: 10 -*-

(in-package #:metashell)

(defgeneric file-to-string-as-lines (pathname)
  (:documentation ""))

(defmethod file-to-string-as-lines ((pathname pathname))
  (with-open-file (stream pathname :direction :input)
    (file-to-string-as-lines stream)))

(defmethod file-to-string-as-lines ((stream stream))
  (with-output-to-string (s)
    (loop for line = (read-line stream nil :eof nil) 
	 until (eq line :eof) do
	 (princ line s)
	 (terpri s))))

(defmethod shell-command ((command pathname) &key input)
  (shell-command (namestring command) :input input))

(defmethod shell-command ((command t) &key input)
  "Synchronously execute `command` using a Bourne-compatible shell,
returns (values output error-output exit-status).

The `command` can be a full path to a shell executable binary
or just its name. In the later case, the variable `*shell-search-paths*`
will be used to find the executable.

Depending on the implementation, the variable `*bourne-compatible-shell*`
may be used to find a shell to use in executing `command`."
  (let* ((pos-/ (position #\/ command))
	 (pos-space (find-command-ending-in-string command))
	 (binary (subseq command 0 (or pos-space)))
	 (args (and pos-space (subseq command pos-space))))
    (when (or (not pos-/)
	      (and pos-/ pos-space)
	      (and pos-space
		   (< pos-/ pos-space)))
      ;; no slash in the command portion, try to find the command with
      ;; our path
      (setf binary
	    (or (loop for path in *shell-search-paths* do
		     (let ((full-binary (make-pathname :name binary
						       :defaults path))) 
		       (when (and (probe-file full-binary)
				  (directory-pathname-p full-binary))
			 (return full-binary))))
		binary)))
    (multiple-value-bind (output error status)
	(%shell-command (format nil "~a~@[ ~a~]" binary args) input)
      (values output error status))))

(defun find-command-ending-in-string (command)
  (let ((checking? t))
    (loop for ch across command 
       for i from 0 do
	 (cond ((and checking? (char= ch #\Space))
		(return i))
	       ((char= ch #\\)
		(setf checking? nil))
	       (t
		(setf checking? t))))))

(defun os-process-id ()
  "Return the process-id of the currently executing OS process."
  (%os-process-id))

(defun get-env-var (name)
  "Return the value of the environment variable `name`."
  (%get-env-var name))

(defun exit (&optional (code :success))
  "Exit the process. CODE is either a numeric exit code, or the special values :SUCCESS
or :FAILURE, which maps to the appropriate exit codes for the operating system."
  ;; Currently, :SUCCESS always maps to 0 and :FAILURE maps to 1
  (%exit (cond ((eq code :success) 0)
               ((eq code :failure) 1)
               ((integerp code) code)
               (t (error "Illegal exit code: ~s (should be an integer or the values :SUCCESS or :FAILURE)" code)))))
