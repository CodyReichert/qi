(in-package :cl-user)
(defpackage qi.manifest
  (:use :cl)
  (:export :manifest-entry
           :create-download-strategy
           :manifest-package-exists?
           :manifest-get-by-name))
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
  (locations 'cons))

(adt:defdata version-location
  "An algebraic data-type for storing a '(version . location) alist
inside of a manifest-package."
  (ver-loc cons))


(defun manifest-load ()
  "Load qi's manifest.lisp into memory."
  (with-open-file (s +manifest-file+)
    (let ((out))
      (loop
         for line = (read-line s nil 'eof)
         until (eq line 'eof)
         do (setf out (concatenate 'string out line)))
      (setf +manifest-packages+ (read-from-string out)))))


(defun create-download-strategy (pack &optional (version "latest"))
  "Takes a `manifest-package' data type, and returns download location
for the specific version, and the download-strategy. Location is already
wrapped in the ADT."
  (let ((vc (manifest-package-vc pack))
        (available (manifest-package-locations pack))
        (loc))
    (loop
       for v/l in available
       when (string= version (car v/l))
       do
         (setf loc (cdr v/l))
         (format t "~%---> Resolved verion ~S for ~S" (car v/l) (manifest-package-name pack)))
    (cond ((string= "http" vc)
           (values (qi.packages::http loc) "tarball"))
          ((string= "git" vc)
           (values (qi.packages::git loc) "git"))
          (t (values (qi.packages::git loc) "git")))))


(defun manifest-package-exists? (name)
  "Check if a package by the name of `name' is available in the manifest.
Returns the package if it exists - nil otherwise."
  (remove-if-not #'(lambda (x)
                     (string= name (manifest-package-name x))) +manifest-packages+))


(defun manifest-get-by-name (sys-name)
  "Return a `manifest-package' by the given name. Returns NIL if the package
does not exist."
  (let ((matches (remove-if-not #'(lambda (x)
                                    (string= sys-name (manifest-package-name x)))
                                +manifest-packages+)))
    (cond ((= 1 (length matches))
           (return-from manifest-get-by-name (first matches)))
          ((= 0 (length matches))
           (return-from manifest-get-by-name nil))
          (t
           (return-from manifest-get-by-name matches)))))


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
                                  (when words
                                    (setf *qi-packages*
                                          (pushnew
                                           (make-manifest-package
                                            :name (car name)
                                            :vc (svref words 0)
                                            :locations (pairlis (list "latest")
                                                                (list (svref words 1))))
                                           *qi-packages*))))))) t))
  (with-open-file (s +manifest-file+
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
    (format s "~S" *qi-packages*)))
