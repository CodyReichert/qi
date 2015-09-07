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
           :*qi-trans-dependencies*
           :*qi-broken-trans-dependencies*
           :dependency
           :dependency-name
           :dependency-location
           :dependency-version
           :dependency-sys-path
           :make-dependency
           :make-manifest-dependency
           :make-http-dependency
           :make-local-dependency
           :make-git-dependency
           :transitive-dependency
           :transitive-dependency-name
           :transitive-dependency-caller
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
  "A list of uninstalled `dependencies'.")
(defvar *qi-trans-dependencies* nil
  "A list of `trans-dependencies' required by any *qi-dependencies.")
(defvar *qi-broken-trans-dependencies* nil
  "A list of broken transitive dependencies.")

;; `dependency' data type and methods

(defstruct dependency
  "The base data structure for a dependency."
  name
  (download-strategy nil)
  (location 'location)
  (src-path nil)
  (sys-path nil)
  (version "latest"))

(adt:defdata location
  "The location of a dependency."
  (manifest t)
  (local t)
  (http t)
  (git t))


(defstruct (manifest-dependency (:include dependency))
  "Manifest dependency data structure.")

(defstruct (local-dependency (:include dependency))
  "Local dependency data structure.")

(defstruct (http-dependency (:include dependency))
  "Tarball dependency data structure.")

(defstruct (git-dependency (:include dependency))
  "Github dependency data structure.")

(defstruct (transitive-dependency (:include manifest-dependency))
  "Transitive dependency data structure."
  (caller nil))


;;
;; Generic functions on a `dependency'
;;

(defgeneric dispatch-dependency (dependency)
  (:documentation "Process (download/cp/install/) dependency based off
of its location."))

(defmethod dispatch-dependency :after ((dependency dependency))
  (setf *qi-dependencies* (pushnew dependency *qi-dependencies*)))

(defmethod dispatch-dependency ((dep local-dependency))
  (format t "~%-> Preparing to copy local dependency.")
  (format t "~%---> ~A" (dependency-location dep))
  (install-dependency dep))

(defmethod dispatch-dependency ((dep http-dependency))
  (format t "~%-> Preparing to download tarball dependency: ~S" (dependency-name dep))
  (install-dependency dep))

(defmethod dispatch-dependency ((dep git-dependency))
  (format t "~%-> Preparing to clone Git dependency: ~S" (dependency-name dep))
  (install-dependency dep))
  ;(setf *qi-broken-dependencies* (pushnew dep *qi-broken-dependencies*)))

(defmethod dispatch-dependency ((dep manifest-dependency))
  (format t "~%-> Preparing to install manifest dependency: ~S" (dependency-name dep))
  (if (not (ensure-dependency dep))
      (progn
        (setf *qi-broken-dependencies* (pushnew dep *qi-broken-dependencies*))
        (format t "~%---X ~A not found in manifest" (dependency-name dep)))
      (progn
        (let ((pack (manifest-get-by-name (dependency-name dep))))
          (multiple-value-bind (location* strategy)
              (create-download-strategy pack)

            (cond ((string= "tarball" strategy)
                   (setf (dependency-location dep) (http location*))
                   (setf (dependency-download-strategy dep) strategy))
                  ((string= "git" strategy)
                   (setf (dependency-location dep) (git location*))
                   (setf (dependency-download-strategy dep) strategy)))
            (install-dependency dep))))))


(defgeneric ensure-dependency (dependency)
  (:documentation "Ensure that a dependency exists. That we have all
of the information we need to get it."))

(defmethod ensure-dependency ((dep manifest-dependency))
  "Check the manifest to ensure a dependency exists."
  (let ((manifest-package (manifest-get-by-name (dependency-name dep))))
    (cond ((eql nil manifest-package) nil)
          (t
           (format t "~%---> Found package in manifest!")
           dep))))


(defgeneric install-dependency (dependency)
  (:documentation "Install a dependency to ./.qi/packages"))

(defmethod install-dependency ((dep local-dependency))
  (format t "~%---X Installing local dependencies is not yet supported.")
  (setf *qi-broken-dependencies* (pushnew dep *qi-broken-dependencies*)))

(defmethod install-dependency ((dep git-dependency))
  (format t "~%---> Resolving repository location.")
  (clone-git-repo (dependency-location dep) dep)
  (make-dependency-available dep)
  (install-transitive-dependencies dep))
  ;(setf *qi-broken-dependencies* (pushnew dep *qi-broken-dependencies*)))

(defmethod install-dependency ((dep http-dependency))
  (let ((loc (dependency-location dep)))
    (format t "~%---> Resolving tarball dependency location.")
    (adt:match location loc
      ((http url) ; manifest holds an http url
       (download-tarball url dep)
       (make-dependency-available dep)
       (install-transitive-dependencies dep))
      (_ (format t "~%---> Unable able to resolve location of: ~S" loc)
         (setf *qi-broken-dependencies* (pushnew dep *qi-broken-dependencies*))))))

(defmethod install-dependency ((dep manifest-dependency))
  (let ((loc (dependency-location dep)))
    (adt:match location loc

       ((http url) ; has an http url
        (download-tarball url dep)
        (install-transitive-dependencies dep)
        (make-dependency-available dep))

       ((local path) ; has a local path (should not happen)
        (format t "~%---X LOCAL PACKAGES NOT YET SUPPORTED: ~S~%" path)
        (setf *qi-broken-dependencies* (pushnew dep *qi-broken-dependencies*)))

       ((git repo) ; has a git url
        (clone-git-repo repo dep)
        (make-dependency-available dep)
        (install-transitive-dependencies dep))

       (_
        (format t "~%---X Cannot resolve package type: ~S" (dependency-name dep))
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


(defun clone-git-repo (url dep)
  "Downloads tarball from <url>, and updates <dep> with the local src-path
and sys-path."
  (let ((clone-path (fad:merge-pathnames-as-directory
                     (qi.paths:package-dir) (concatenate 'string
                                                         (dependency-name dep) "-"
                                                         (dependency-version dep) "/"))))
    (format t "~%---> Cloning repo from ~S" url)
    (format t "~%---> Cloning repo to ~S" (namestring clone-path))
    (git-clone url (namestring clone-path))
    (if (probe-file (fad:merge-pathnames-as-file clone-path
                                                 (concatenate 'string (dependency-name dep) ".asd")))
        (set-dependency-paths clone-path dep)
        (progn
          (format t "~%---X Failure to clone repository!")
          (setf *qi-broken-dependencies* (pushnew dep *qi-broken-dependencies*))))))


(defun git-clone (from to)
  (trivial-shell:shell-command
   (concatenate 'string "git clone " from " " to)))


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


(defun make-dependency-available (dep)
  (setf asdf:*central-registry*
        (list* (dependency-sys-path dep)  ;; add this dependencies path to the
               asdf:*central-registry*))) ;; ASDF registry.


(defun install-transitive-dependencies (dep)
  (if (system-is-available? (dependency-name dep))
      (let ((trans-deps (asdf:system-depends-on (asdf:find-system (dependency-name dep)))))
        (loop for d in trans-deps do
             (if (or (system-is-available? d)
                     (dependency-installed? d))
                 (set-trans-dep d (dependency-name dep))
                 (progn
                   (format t "~%---X Checking manifest for transitive dependency: ~S" d)
                   (let ((manifest-package (manifest-get-by-name (dependency-name dep))))
                     (cond ((eql nil manifest-package)
                            (format t "~%---X Can not install ~A~%" dep)
                            (set-broken-trans-dep d (dependency-name dep)))
                           (t
                            (format t "~%---> Found package in manifest!")
                            (make-trans-dep-from-manifest d (dependency-name dep)))))))))))



(defun make-trans-dep-from-manifest (name caller)
  (dispatch-dependency (make-transitive-dependency :name name
                                                   :caller caller)))


(defun set-trans-dep (name caller)
  "Creates and adds an available transitive dependecy to the
*qi-trans-dependencies* list."
  (setf *qi-trans-dependencies*
        (pushnew
         (make-transitive-dependency :name name
                                     :caller caller)
         *qi-trans-dependencies*)))


(defun set-broken-trans-dep (name caller)
  "Creates and adds an unavailable transitive dependecy to the
*qi-broken-trans-dependencies* list."
  (setf *qi-broken-trans-dependencies*
        (pushnew
         (make-transitive-dependency :name name
                                     :caller caller)
         *qi-broken-trans-dependencies*)))


(defun system-is-available? (sys)
  (handler-case
      (asdf:find-system sys)
    (error () () nil)))


(defun dependency-installed? (name)
  (remove-if-not #'(lambda (x)
                     (string=
                      (dependency-name x)
                      name))
                 *qi-dependencies*))


(defun asdf-system-path (sys)
  (handler-case
      (asdf:component-pathname (asdf:find-system sys))
    (error () () nil)))


(defun gh-tar-url (url)
  (concatenate 'string url "/archive/master.tar.gz"))
