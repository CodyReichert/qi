(in-package :cl-user)
(defpackage qi.packages
  (:use :cl :qi.paths :chipz)
  (:import-from :qi.manifest
                :create-download-strategy
                :manifest-package
                :manifest-package-exists?
                :manifest-get-by-name)
  (:export :*qi-dependencies*
           :*qi-broken-dependencies*
           :dependency
           :dependency-name
           :dependency-location
           :dependency-version
           :make-dependency
           :make-manifest-dependency
           :make-http-dependency
           :make-local-dependency
           :make-git-dependency
           :dispatch-dependency
           :location
           :local
           :http
           :git))
(in-package :qi.packages)

;; code:

;; This package provides data types and generic functions for working with
;; qi 'dependencies'. Dependencies are specified by a user in their qi.yaml
;; file. Three types of dependencies are supported:
;;   - Local
;;     + Only takes a path to a directory on the local machine
;;   - HTTP
;;     + An http link to a tarball
;;   - Git
;;     + Git URL's are cloned, and can take a couple of extra parameters:
;;       - Location (http link to repo on github)
;;       - Version (version of the repo to check out)


(defvar *qi-dependencies* nil
  "A list of `dependencies' as required by the qi.yaml.")
(defvar *qi-broken-dependencies* nil
  "A list of `dependencies' as required by the qi.yaml.")
(defvar *qi-trans-dependencies* nil
  "A list of `trans-dependencies' required by any *qi-dependencies.")

;; `dependency' data type and methods

(defstruct dependency
  "The base data structure for a dependency."
  name
  (download-strategy nil)
  (location 'location)
  (src-path nil)
  (sys-path nil)
  (version "latest"))


(defstruct (manifest-dependency (:include dependency))
  "Manifest dependency data structure.")

(defstruct (local-dependency (:include dependency))
  "Local dependency data structure.")

(defstruct (http-dependency (:include dependency))
  "Tarball dependency data structure.")

(defstruct (git-dependency (:include dependency))
  "Github dependency data structure.")


(adt:defdata location
  "The location of a dependency."
  (manifest t)
  (local t)
  (http t)
  (git t))


(defstruct transitive-dependency
  "A transitive-dependency is another system required by a qi package."
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

(defmethod dispatch-dependency ((dep http-dependency))
  (format t "~%Preparing to download tarball dependency: ~S" (dependency-name dep))
  (install-dependency dep))

(defmethod dispatch-dependency ((dep git-dependency))
  (format t "~%Preparing to clone Git dependency: ~S" (dependency-name dep))
  (format t "~%---X Install git dependencies is not yet supported.")
  (setf *qi-broken-dependencies* (pushnew dep *qi-broken-dependencies*))
  ;(install-dependency dep)
  ;(make-dependency-available dep)
  ;(check-dependency-dependencies dep)
  ;(print *qi-dependencies*)
  )

(defmethod dispatch-dependency ((dep manifest-dependency))
  (format t "~%Preparing to install manifest dependency: ~S" (dependency-name dep))
  (if (not (ensure-dependency dep))
      (format t "~%---X Can not install ~A" dep)
      (progn
        (let ((pack (manifest-get-by-name (dependency-name dep))))
          (multiple-value-bind (location* strategy)
              (create-download-strategy pack)
            (setf (dependency-location dep) location*)
            (setf (dependency-download-strategy dep) strategy)
            (install-dependency dep))))))


(defgeneric ensure-dependency (dependency)
  (:documentation "Ensure that a dependency exists. That we have all
of the information we need to get it."))

(defmethod ensure-dependency ((dep manifest-dependency))
  "Check the manifest to ensure a dependency exists."
  (let ((manifest-package (manifest-get-by-name (dependency-name dep))))
    (cond ((eql nil manifest-package)
           (format t "~%---X Can not install ~A~%" dep)
           nil)
          (t
           (format t "~%---> Found package in manifest!")
           dep))))


(defgeneric install-dependency (dependency)
  (:documentation "Install a dependency to ./.qi/packages"))

(defmethod install-dependency ((dep local-dependency))
  (format t "~%---X Installing local dependencies is not yet supported.")
  (setf *qi-broken-dependencies* (pushnew dep *qi-broken-dependencies*)))

(defmethod install-dependency ((dep git-dependency))
  (format t "~%---X Installing git dependencies is not yet supported.")
  (setf *qi-broken-dependencies* (pushnew dep *qi-broken-dependencies*)))


(defmethod install-dependency ((dep manifest-dependency))
  (let ((loc (dependency-location dep)))
    (adt:match location loc
       ((http url) ; has an http url
        (download-tarball url dep)
        (make-dependency-available dep))
       ((local path) ; has a local path (should not happen)
        (format t "~%---X LOCAL PACKAGES NOT YET SUPPORTED: ~S~%" path)
        (setf *qi-broken-dependencies* (pushnew dep *qi-broken-dependencies*)))
       ((git repo) ; has a git url
        (format t "~%---> GIT PACKAGES NOT YET SUPPORTED: ~S~%" repo)
        (setf *qi-broken-dependencies* (pushnew dep *qi-broken-dependencies*)))
       (_
        (format t "~%---> Cannot resolve package type: ~S~%" (dependency-name dep))
        (setf *qi-broken-dependencies* (pushnew dep *qi-broken-dependencies*))))))


(defmethod install-dependency ((dep http-dependency))
  (let ((loc (dependency-location dep)))
    (format t "~%---> Resolving tarball dependency location.")
    (adt:match location loc
      ((http url) ; manifest holds an http url
       (download-tarball url dep)
       (make-dependency-available dep))
      (_ (format t "~%---> Unable able to resolve location of: ~S" loc)
         (setf *qi-broken-dependencies* (pushnew dep *qi-broken-dependencies*))))))


(defun download-tarball (url dep)
  "Downloads tarball from <url>, and updates <dep> with the local src-path
and sys-path."
  (let* ((out-file (concatenate 'string
                                (dependency-name dep) "-"
                                (dependency-version dep) ".tar.gz"))
         (out-path (fad:merge-pathnames-as-file (tar-dir) (pathname out-file))))
    (format t "~%---> Downloading tarball from ~S" url)
    (with-open-file (f (ensure-directories-exist out-path)
                       :direction :output
                       :if-does-not-exist :create
                       :if-exists :supersede
                       :element-type '(unsigned-byte 8))
      (let ((tar (drakma:http-request url :want-stream t)))
        (arnesi:awhile (read-byte tar nil nil)
          (write-byte arnesi:it f))
        (close tar)
        (set-dependency-paths out-path dep)))
    (unpack-tar dep)))
        

(defun unpack-tar (dep)
  (extract-tarball (dependency-src-path dep)))


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


(defun set-dependency-paths (out-path dep)
  "Update an a dependency's src-path and sys-path."
  (let ((sys-path (fad:merge-pathnames-as-directory
                   (qi.paths:package-dir) (concatenate 'string
                                                       (dependency-name dep) "-"
                                                       (dependency-version dep) "/"))))
    (setf (dependency-src-path dep) out-path)
    (setf (dependency-sys-path dep) sys-path)))


(defun find-dep-asd (dep)
  (if dep () ()))


(defun make-dependency-available (dep)
  (setf asdf:*central-registry*
        (list* (dependency-sys-path dep) ;; add this dependencies path to the
               asdf:*central-registry*)) ;; ASDF registry.
  (format t "~%---> Making dependency available to ASDF~%"))


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
                   (format t "~%---> Sub-dependency is available: ~A" (asdf-system-path dep))
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
