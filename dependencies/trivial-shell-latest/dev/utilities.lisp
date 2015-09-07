(in-package #:com.metabang.trivial-shell)

(defparameter *os-alist*
  '((:windows :windows :mswindows :win32)
    (:sun :solaris :sunos)
    (:osx :macosx :darwin :apple)
    (:linux :freebsd :netbsd :openbsd :bsd :linux :unix)))

(defun host-os ()
  (dolist (mapping *os-alist*)
    (destructuring-bind (os &rest features) mapping
      (dolist (f features)
	(when (find f *features*) (return-from host-os os))))))

#+(or)
(defun os-pathname (pathname &key (os (os)))
  (namestring pathname))

(defun directory-pathname-p (pathname)
  "Does `pathname` syntactically  represent a directory?

A directory-pathname is a pathname _without_ a filename. The three
ways that the filename components can be missing are for it to be `nil`, 
`:unspecific` or the empty string.
"
  (flet ((check-one (x)
	   (not (null (member x '(nil :unspecific "")
			      :test 'equal)))))
    (and (check-one (pathname-name pathname))
	 (check-one (pathname-type pathname)))))

#+(or)
;; from asdf-install
(defun tar-argument (arg)
  "Given a filename argument for tar, massage it into our guess of the
 correct form based on the feature list."
  #-(or :win32 :mswindows :scl)
  (namestring (truename arg))
  #+scl
  (ext:unix-namestring (truename arg))
  
  ;; Here we assume that if we're in Windows, we're running Cygwin,
  ;; and cygpath is available. We call out to cygpath here rather than
  ;; using shell backquoting. Relying on the shell can cause a host of
  ;; problems with argument quoting, so we won't assume that
  ;; RETURN-OUTPUT-FROM-PROGRAM will use a shell. [dwm]
  #+(or :win32 :mswindows)
  (with-input-from-string (s (return-output-from-program
                              (find-program "cygpath.exe")
                              (list (namestring (truename arg)))))
    (values (read-line s))))

