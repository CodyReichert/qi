(in-package :cl-user)
(defpackage qi.manifest
  (:use :cl)
  (:export :manifest-entry
           :get-system-from-manifest))
(in-package :qi.manifest)

;; Code:

(defvar *qi-packages* ()
  "A stub list of importing the quicklisp dist.")
(defvar +manifest-packages+ ()
  "A list of known packages from manifest.lisp.")
(defvar +manifest-file+
  (fad:merge-pathnames-as-file (user-homedir-pathname)
                               ".qi/manifest.lisp")
  "PATHNAME to the qi manifest.lisp file.")

(defstruct manifest-package
  "A data type defining known packages that will be written to and from the
manifest. `locations' is an ADT that holds an alist to allow searching for
a specific version of a package."
  name
  vc
  (locations 'version-location))

(adt:defdata version-location
  "An algebraic data-type for storing a '(version . location) alist
inside of a manifest-package."
  (ver-loc cons))


(defun import-ql ()
  "Walk the quicklisp-projects directory and import all of those to qi format."
  (fad:walk-directory #p"/home/cody/workspace/projects/qi/manifest/projects/"
                      #'(lambda (x)
                          (let ((name (last
                                       (pathname-directory
                                        (fad:pathname-directory-pathname x)))))
                            (with-open-file (s x)
                              (do ((line (read-line s ())
                                         (read-line s ())))
                                  ((null line))
                                (let ((words (nth-value
                                              1 (ppcre:scan-to-strings "^(.*?) (.*)" line))))
                                  (print words)
                                  (when words
                                    (setf *qi-packages*
                                          (pushnew
                                           (make-manifest-package
                                            :name name
                                            :vc (svref words 0)
                                            :locations (ver-loc (pairlis (list "latest")
                                                                (list (svref words 1)))))
                                           *qi-packages*)))))))
                          t))
  (with-open-file (s +manifest-file+
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
    (format s "~S" *qi-packages*)))


(defun import-manifest ()
  "Load qi's manifest.lisp into memory."
  (with-open-file (s +manifest+)
    (let ((out))
      (loop
         for line = (read-line s nil 'eof)
         until (eq line 'eof)
         do (setf out (concatenate 'string out line)))
      (setf +manifest-packages+ (read-from-string out)))))


(defun manifest-package-exists? (name)
  "Check if a package by the name of `name' is available in the manifest.
Returns the package if it exists - nil otherwise."
  (print name))


(defun get-system-from-manifest (sys-name)
  "Return a `manifest-package' by the given name. Returns NIL if the package
does not exist."
      (format t "~%Getting ~A from the manifest%" sys-name))
