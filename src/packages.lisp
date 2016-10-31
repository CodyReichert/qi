(in-package :cl-user)
(defpackage qi.packages
  (:use :cl :qi.paths)
  (:import-from :qi.manifest
                :create-download-strategy
                :manifest-package
                :manifest-get-by-name)
  (:export :*qi-dependencies*
           :*qi-trans-dependencies*
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
           :make-hg-dependency
           :transitive-dependency
           :transitive-dependency-name
           :transitive-dependency-caller
           :dispatch-dependency
           :location
           :local
           :http
           :git
           :hg))
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
;;   - Mercurial
;;     + Mercurial URL's are cloned


(defvar *qi-dependencies* nil
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

(adt:defdata location
  "The location of a dependency."
  (manifest t)
  (local t)
  (http t)
  (git t)
  (hg t))


(defstruct (manifest-dependency (:include dependency))
  "Manifest dependency data structure.")

(defstruct (local-dependency (:include dependency))
  "Local dependency data structure.")

(defstruct (http-dependency (:include dependency))
  "Tarball dependency data structure.")

(defstruct (git-dependency (:include dependency))
  "Github dependency data structure.")

(defstruct (hg-dependency (:include dependency))
  "Mercurial dependency data structure.")

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
  (when (dependency-sys-path dependency)
    (setf *qi-dependencies* (pushnew dependency *qi-dependencies*))))

(defmethod dispatch-dependency ((dep local-dependency))
  (format t "~%-> Preparing to copy local dependency.")
  (format t "~%---> ~A" (dependency-location dep))
  (install-dependency dep))

(defmethod dispatch-dependency ((dep http-dependency))
  (format t "~%-> Preparing to download tarball dependency: ~S"
          (dependency-name dep))
  (install-dependency dep))

(defmethod dispatch-dependency ((dep git-dependency))
  (format t "~%-> Preparing to clone Git dependency: ~S" (dependency-name dep))
  (install-dependency dep))

(defmethod dispatch-dependency ((dep hg-dependency))
  (format t "~%-> Preparing to clone Mercurial dependency: ~S" (dependency-name dep))
  (install-dependency dep))

(defmethod dispatch-dependency ((dep manifest-dependency))
  (format t "~%-> Preparing to install manifest dependency: ~S"
          (dependency-name dep))
  (if (not (ensure-dependency dep))
      (format t "~%---X ~A not found in manifest" (dependency-name dep))
      (progn
        (let ((pack (manifest-get-by-name (dependency-name dep))))
          (multiple-value-bind (location* strategy)
              (create-download-strategy pack)
            (cond ((string= "tarball" strategy)
                   (setf (dependency-location dep) (http location*))
                   (setf (dependency-download-strategy dep) strategy))
                  ((string= "git" strategy)
                   (setf (dependency-location dep) (git location*))
                   (setf (dependency-download-strategy dep) strategy))
                  ((string= "hg" strategy)
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

;; (defmethod install-dependency ((dep local-dependency))
;;   (format t "~%---X Installing local dependencies is not yet supported."))

(defmethod install-dependency ((dep git-dependency))
  (format t "~%---> Resolving repository location.")
  (clone-git-repo (dependency-location dep) dep)
  (make-dependency-available dep)
  (install-transitive-dependencies dep))

(defmethod install-dependency ((dep hg-dependency))
  (format t "~%---> Resolving repository location.")
  (clone-hg-repo (dependency-location dep) dep)
  (make-dependency-available dep)
  (install-transitive-dependencies dep))

(defmethod install-dependency ((dep http-dependency))
  (let ((loc (dependency-location dep)))
    (format t "~%---> Resolving tarball dependency location.")
    (adt:match location loc
      ((http url) ; manifest holds an http url
       (download-tarball url dep)
       (make-dependency-available dep)
       (install-transitive-dependencies dep))
      (_ (error (format t "~%---> Unable able to resolve location of: ~S" loc))))))

(defmethod install-dependency ((dep manifest-dependency))
  (let ((loc (dependency-location dep)))
    (adt:match location loc

       ((http url) ; has an http url
        (download-tarball url dep)
        (make-dependency-available dep)
        (install-transitive-dependencies dep))

       ((local path) ; has a local path (should not happen)
        (error (format t "~%---X LOCAL PACKAGES NOT YET SUPPORTED: ~S~%" path)))

       ((git repo) ; has a git url
        (clone-git-repo repo dep)
        (make-dependency-available dep)
        (install-transitive-dependencies dep))

       (_ ; unsupported strategy
        (error (format t "~%---X Cannot resolve package type: ~S" (dependency-name dep)))))))

(defun download-tarball (url dep)
  "Downloads tarball from <url>, and updates <dep> with the local src-path
and sys-path."
  (let ((out-path (tarball-path dep)))
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
  "Clones Git repository from <url>, and updates <dep> with the local
src-path and sys-path."
  (let ((clone-path (fad:merge-pathnames-as-directory
                     (qi.paths:package-dir)
                     (concatenate 'string
                                  (dependency-name dep) "-"
                                  (dependency-version dep) "/"))))
    (format t "~%---> Cloning repo from ~S" url)
    (format t "~%---> Cloning repo to ~S" (namestring clone-path))
    (git-clone url (namestring clone-path))
    (if (probe-file (fad:merge-pathnames-as-file
                     clone-path
                     (concatenate 'string (dependency-name dep) ".asd")))
        (set-dependency-paths clone-path dep)
      (error (format t "~%~%---X Failed to clone ~A~%" url)))))


(defun git-clone (from to)
  (trivial-shell:shell-command
   (concatenate 'string "git clone " from " " to)))


(defun clone-hg-repo (url dep)
  "Clones Mercurial repository from <url>, and updates <dep> with the
local src-path and sys-path."
  (let ((clone-path (fad:merge-pathnames-as-directory
                     (qi.paths:package-dir)
                     (concatenate 'string
                                  (dependency-name dep) "-"
                                  (dependency-version dep) "/"))))
    (format t "~%---> Cloning repo from ~S" url)
    (format t "~%---> Cloning repo to ~S" (namestring clone-path))
    (hg-clone url (namestring clone-path))
    (if (probe-file (fad:merge-pathnames-as-file
                     clone-path
                     (concatenate 'string (dependency-name dep) ".asd")))
        (set-dependency-paths clone-path dep)
      (error (format t "~%~%---X Failed to clone repository for ~A~%" url)))))


(defun hg-clone (from to)
  (trivial-shell:shell-command
   (concatenate 'string "hg clone " from " " to)))


(defun tarball-path (dep)
  (let ((out-file (concatenate 'string
                                (dependency-name dep) "-"
                                (dependency-version dep) ".tar.gz")))
    (fad:merge-pathnames-as-file (qi.paths:+dep-cache+) (pathname out-file))))

(defun unpack-tar (dep)
  (let* ((tar-path (tarball-path dep))
         (unzipped-actual (extract-tarball* tar-path (qi.paths:package-dir)))
         (unzipped-expected (dependency-sys-path dep)))
    (unless (or (eql unzipped-actual unzipped-expected)
                (probe-file unzipped-expected))
      (rename-file unzipped-actual unzipped-expected))))

(defun extract-tarball* (tarball &optional (destination *default-pathname-defaults*))
  (let ((*default-pathname-defaults* (or destination (qi.paths:package-dir))))
    (gzip-stream:with-open-gzip-file (gzip tarball)
      (let ((archive (archive:open-archive 'archive:tar-archive gzip)))
        (prog1
            (merge-pathnames
             (archive:name (archive:read-entry-from-archive archive))
             *default-pathname-defaults*)
          (archive::extract-files-from-archive archive))))))


(defun set-dependency-paths (out-path dep)
  "Update an a dependency's src-path and sys-path."
  (let ((sys-path (fad:merge-pathnames-as-directory
                   (qi.paths:package-dir)
                   (concatenate 'string
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
      (let ((trans-deps
             (asdf:system-depends-on (asdf:find-system (dependency-name dep)))))
        (loop for d in trans-deps do
             (if (dependency-installed? d)
                 (let ((tdep (make-transitive-dependency
                              :name d
                              :caller (dependency-name dep))))
                   (install-transitive-dependencies tdep)
                   (set-trans-dep d (dependency-name dep)))
               (progn
                 (format t "~%.... Checking manifest for transitive dependency: ~S" d)
                 (let ((manifest-package (manifest-get-by-name d)))
                   (cond ((not manifest-package)
                          (if (not (system-is-available? d))
                              (error (format t "~%~%---X Without ~A, we cannot install ~A~%"
                                             (dependency-name d)
                                             (dependency-name dep)))
                            (set-trans-dep d (dependency-name dep))))
                         (t
                          (format t "~%---> Found package in manifest!")
                          (make-trans-dep-from-manifest d (dependency-name dep)))))))))))


(defun make-trans-dep-from-manifest (name caller)
  (dispatch-dependency
   (make-transitive-dependency :name name :caller caller)))


(defun set-trans-dep (name caller)
  "Creates and adds an available transitive dependecy to the
*qi-trans-dependencies* list."
  (setf *qi-trans-dependencies*
        (pushnew
         (make-transitive-dependency :name name :caller caller)
         *qi-trans-dependencies*)))


(defun system-is-available? (sys)
  (handler-case
      (asdf:find-system sys)
    (error () () nil)))


(defun dependency-installed? (name)
  (remove-if-not #'(lambda (x)
                     (string= (dependency-name x) name))
                 *qi-dependencies*))
