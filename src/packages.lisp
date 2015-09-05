(in-package :cl-user)
(defpackage qi.packages
  (:use :cl :qi.paths)
  (:export :dependency
           :dependency-name
           :dependency-location
           :dependency-version
           :full-dep-location
           :make-dependency
           :dispatch-dependency
           :location
           :local
           :http
           :github))
(in-package :qi.packages)

;; code:

;; This package provides data types and generic functions for working with
;; qi 'dependencies'. Dependencies are specified by a user in their qi.yaml
;; file. Three types of dependencies are supported:
;;   - Local
;;     + Only takes a path to a directory on the local machine
;;   - HTTP
;;     + An http link to a tarball
;;   - Github
;;     + Git URL's are cloned, and can take a couple of extra parameters:
;;       - Location (http link to repo on github)
;;       - Version (version of the repo to check out)


;; `dependency' data type and methods

(defstruct dependency
  "The base data structure for a dependency."
  (location 'location))


(defstruct (local-dependency (:include dependency))
  "Local dependency data structure.")


(defstruct (tar-dependency (:include dependency))
  "Tarball dependency data structure.")


(defstruct (gh-dependency (:include dependency))
  "Github dependency data structure."
  (name nil)
  (version nil))


(adt:defdata location
  "The location of a dependency."
  (local t)
  (http t)
  (github t))


;; Generic functions
(defgeneric full-dep-location (location)
  (:documentation
   "Return the full location of a dependency."))


(defmethod full-dep-location ((loc location))
  (format t "~A is a dependency." loc)
  loc)


;(defmethod full-dep-location ((loc local))
;  (format t "~A is a local dependency." loc))
;
;(defmethod full-dep-location ((loc http))
;  (format t "~A is an http dependency." loc))
;
;(defmethod full-dep-location ((loc github))
;  loc)


(defgeneric dispatch-dependency (dependency)
  (:documentation "Process (download/cp/install/) dependency based off
of its location."))

(defmethod dispatch-dependency ((dep local-dependency))
  (format t "~%Preparing to copy local dependency.")
  (format t "~%---> ~A" (dependency-location dep))
  (install-dependency dep))
  
(defmethod dispatch-dependency ((dep tar-dependency))
  (format t "~%Preparing to download tarball dependency.")
  (format t "~%---> ~A" (dependency-location dep))
  (install-dependency dep))
  
(defmethod dispatch-dependency ((dep gh-dependency))
  (format t "~%Preparing to clone GitHub dependency.")
  (format t "~%---> ~A" (gh-dependency-name dep))
  (install-dependency dep))
  

(defgeneric install-dependency (dependency)
  (:documentation "Install a dependency to ./.qi/packages"))

(defmethod install-dependency ((dep local-dependency))
  (format t "~%---X Installing local dependencies is not yet supported."))

(defmethod install-dependency ((dep tar-dependency))
  (format t "~%---X Installing tarball dependencies is not yet supported."))

(defmethod install-dependency ((dep gh-dependency))
  (let* ((out-file (concatenate 'string
                                (gh-dependency-name dep) "-"
                                (gh-dependency-version dep) ".tar.gz"))
         (out-path (fad:merge-pathnames-as-file (tar-dir) (pathname out-file))))
    (adt:with-data (github loc) (gh-dependency-location dep)
      (format t "~%---> Installing package from ~A~%" loc)
      (with-open-file (f (ensure-directories-exist out-path)
                         :direction :output
                         :if-does-not-exist :create
                         :if-exists :supersede
                         :element-type '(unsigned-byte 8))
        (print (gh-tar-url loc))
        (let ((input (drakma:http-request (gh-tar-url loc)
                                        :want-stream t)))
        ;; TODO: handle some response from Github that might say
        ;; "error: not found".
        (arnesi:awhile (read-byte input nil nil)
          (write-byte arnesi:it f))
        (close input))))))


(defun gh-tar-url (url)
  (concatenate 'string url "/archive/master.tar.gz"))
