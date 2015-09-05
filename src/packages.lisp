(in-package :cl-user)
(defpackage qi.packages
  (:use :cl :qi.paths :archive :chipz)
  (:export :*qi-dependencies*
           :dependency
           :dependency-name
           :dependency-location
           :dependency-version
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


(defvar *qi-dependencies* nil
  "A list of `dependencies' as required by the qi.yaml.")
(defvar *qi-trans-dependencies* nil
  "A list of `trans-dependencies' required by any *qi-dependencies.")

;; `dependency' data type and methods

(defstruct dependency
  "The base data structure for a dependency."
  (name nil)
  (location 'location)
  (tar-path nil)
  (sys-path nil))


(defstruct (local-dependency (:include dependency))
  "Local dependency data structure.")


(defstruct (tar-dependency (:include dependency))
  "Tarball dependency data structure.")


(defstruct (gh-dependency (:include dependency))
  "Github dependency data structure."
  (version nil))


(adt:defdata location
  "The location of a dependency."
  (local t)
  (http t)
  (github t))


(defstruct transitive-dependency
  "A transitive-dependency is a system required by a qi dependency."
  (name nil)
  (caller nil)
  (path nil))

(adt:defdata dep-status
  "The availability status of a transitive dependency."
  (dep-available t)
  dep-unknown)


;;
;; Generic functions on a `dependency'
;;

(defgeneric dispatch-dependency (dependency)
  (:documentation "Process (download/cp/install/) dependency based off
of its location."))

(defmethod dispatch-dependency :after ((dependency dependency))
  (setf *qi-dependencies* (pushnew dependency *qi-dependencies*)))

(defmethod dispatch-dependency ((dep local-dependency))
  (format t "~%Preparing to copy local dependency.")
  (format t "~%---> ~A" (dependency-location dep))
  (install-dependency dep))
  
(defmethod dispatch-dependency ((dep tar-dependency))
  (format t "~%Preparing to download tarball dependency.")
  (format t "~%---> ~A" (dependency-location dep))
  (install-dependency dep))
  
(defmethod dispatch-dependency ((dep gh-dependency))
  (format t "~%~%Preparing to clone GitHub dependency.")
  (format t "~%---> ~A" (dependency-name dep))
  (install-dependency dep)
  (make-dependency-available dep)
  (check-dependency-dependencies dep)
  ;(print *qi-dependencies*)
  )
  

(defgeneric install-dependency (dependency)
  (:documentation "Install a dependency to ./.qi/packages"))

(defmethod install-dependency ((dep local-dependency))
  (format t "~%---X Installing local dependencies is not yet supported."))

(defmethod install-dependency ((dep tar-dependency))
  (format t "~%---X Installing tarball dependencies is not yet supported."))

(defmethod install-dependency ((dep gh-dependency))
  (let* ((out-file (concatenate 'string
                                (dependency-name dep) "-"
                                (gh-dependency-version dep) ".tar.gz"))
         (out-path (fad:merge-pathnames-as-file (tar-dir) (pathname out-file))))
    (adt:with-data (github loc) (gh-dependency-location dep)
      (format t "~%---> Installing package from ~A" loc)
      (with-open-file (f (ensure-directories-exist out-path)
                         :direction :output
                         :if-does-not-exist :create
                         :if-exists :supersede
                         :element-type '(unsigned-byte 8))
        (let ((input (drakma:http-request (gh-tar-url loc)
                                        :want-stream t)))
        ;; TODO: handle some response from Github that might say
        ;; "error: not found".
        (arnesi:awhile (read-byte input nil nil)
          (write-byte arnesi:it f))
        (close input)
        (setf (dependency-tar-path dep) out-path)
        (setf (dependency-sys-path dep)
              (fad:merge-pathnames-as-directory
               (qi.paths:package-dir) (concatenate 'string (dependency-name dep) "-"
                                                   (gh-dependency-version dep) "/")))))))
  (unpack-tar dep))

(defun unpack-tar (dep)
  (format t "~%---> Unpackaging dependency")
  (extract-tarball (dependency-tar-path dep)))


(defun extract-tarball (pathname)
  "Extract a tarball (.tar.gz) file to a directory (*default-pathname-defaults*)."
  (let ((*default-pathname-defaults* (qi.paths:package-dir)))
    (with-open-file (tarball-stream pathname
                                    :direction :input
                                    :element-type '(unsigned-byte 8))
      (archive::extract-files-from-archive
       (archive:open-archive 'archive:tar-archive
                             (chipz:make-decompressing-stream 'chipz:gzip tarball-stream)
                             :direction :input)))))


(defun find-dep-asd (dep)
  (if dep () ()))


(defun make-dependency-available (dep)
  (setf asdf:*central-registry*
        (list* (dependency-sys-path dep) ;; add this dependencies path to the
               asdf:*central-registry*)) ;; ASDF registry.
  (format t "~%---> Making dependency available to ASDF"))


(defun check-dependency-dependencies (dep)
  (let ((sys-definition
         (fad:merge-pathnames-as-file
          (dependency-sys-path dep) (concatenate 'string (dependency-name dep) ".asd")))
        (sub-sys-deps))
    (if (system-is-available? (dependency-name dep))
        (progn
          (setf sub-sys-deps (asdf:system-depends-on (asdf:find-system (dependency-name dep))))
          (loop for dep in sub-sys-deps do
               (if (system-is-available? dep)
                   (format t "~%---> Sub-dependency is available: ~A" dep)
                   (format t "~%---X Sub-dependency is not available: ~A" dep))))
        (format t "~%---X System is not available: ~A" dep))))
    ;(format t "~%---> ~A depends on ~A~%" (dependency-name dep) sys-dependencies)))


(defun system-is-available? (sys)
  (handler-case
      (asdf:find-system sys)
    (error () () nil)))


(defun asdf-system-path (sys)
  (handler-case
      (asdf:component-pathname (asdf:find-system sys))
    (error () () nil)))


(defun gh-tar-url (url)
  (concatenate 'string url "/archive/master.tar.gz"))
