(in-package #:trivial-shell)

#+(or)
;; use to find sh
(defun find-rapper-binary ()
  (or 
   (excl.osi:find-in-path
    #+mswindows "rapper.exe"
    #-mswindows "rapper")
   (strip-whitespace (smu:shell-command "which rapper"))))


(defun %shell-command (command input)
  (multiple-value-bind (output error status)
      (excl.osi:command-output 
       command :whole t
       :input input)
    (values output error status)))

#+(or)
(defun %shell-command (command input)
  (multiple-value-bind (output error status)
      (excl:run-shell-command 
       command :wait t
       :input input)
    (values output error status)))


(defun %os-process-id ()
  (excl.osi:getpid))

(defun %get-env-var (name)
  (sys:getenv name))

(defun %exit (code)
  (excl:exit code))
