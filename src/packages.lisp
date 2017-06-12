(in-package :cl-user)
(defpackage qi.packages
  (:use :cl :qi.paths)
  (:import-from :qi.manifest
                :manifest-get-by-name
                :manifest-package
                :manifest-package-name
                :manifest-package-url)
  (:import-from :qi.util
                :download-strategy
                :is-tar-url?
                :is-git-url?
                :is-hg-url?
                :is-gh-url?
                :run-git-command
                :update-repository)
  (:export :*qi-dependencies*
           :*yaml-packages*
           :dependency
           :dependency-name
           :dependency-url
           :dependency-version
           :extract-dependency
           :get-sys-path
           :install-dependency
           :installed?
           :make-dependency
           :make-manifest-dependency
           :make-http-dependency
           :make-local-dependency
           :make-git-dependency
           :make-hg-dependency
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

(defvar *yaml-packages* nil
  "A list of `dependencies' from the `+project-names+' qi.yaml")

;; `dependency' data type and methods

(defstruct dependency
  "The base data structure for a dependency."
  name
  ;; Don't use "master" as default; instead let upstream dictate
  (branch nil)
  (download-strategy nil)
  (url nil)
  (version nil))


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


;;
;; Generic functions on a `dependency'
;;

(defgeneric install-dependency (dependency)
  (:documentation "Install a dependency to share/qi/packages"))

(defmethod install-dependency :before ((dependency dependency))
  (setf *qi-dependencies* (cons dependency *qi-dependencies*)))

(defmethod install-dependency ((dep git-dependency))
  (clone-git-repo (dependency-url dep) dep)
  (make-dependency-available dep)
  (install-transitive-dependencies dep))

(defmethod install-dependency ((dep hg-dependency))
  (clone-hg-repo (dependency-url dep) dep)
  (make-dependency-available dep)
  (install-transitive-dependencies dep))

(defmethod install-dependency ((dep http-dependency))
  (remove-old-versions dep)
  (download-tarball (dependency-url dep) dep)

  (make-dependency-available dep)
  (install-transitive-dependencies dep))

(defmethod install-dependency ((dep manifest-dependency))
  (let ((strat (dependency-download-strategy dep))
        (url (dependency-url dep)))
    (cond ((eq :tarball strat)
           (remove-old-versions dep)
           (download-tarball url dep)

           ;; The dependency must be made available before it is
           ;; installed so ASDF can determine its dependencies in turn
           (make-dependency-available dep)
           (install-transitive-dependencies dep))

          ((eq :git strat)
           (clone-git-repo url dep)
           (make-dependency-available dep)
           (install-transitive-dependencies dep))

          (t ; unsupported strategy
           (error (format t "~%---X Download strategy \"~S\" is not yet supported" strat))))))

(defun extract-dependency (p)
  "Generate a dependency from package P."
  (cond ((eql nil (gethash "url" p))
         (let ((man (manifest-get-by-name (gethash "name" p))))
           (unless man
             (error "---X Package \"~S\" is not in the manifest; please provide a URL"
                    (gethash "name" p)))
           (make-manifest-dependency :name (gethash "name" p)
                                     :download-strategy (download-strategy (manifest-package-url man))
                                     :url (manifest-package-url man)
                                     :version (or (gethash "tag" p)
                                                  (gethash "revision" p)
                                                  (gethash "version" p)))))
        ;; Dependency has a tarball URL
        ((is-tar-url? (gethash "url" p))
         (make-http-dependency :name (gethash "name" p)
                               :download-strategy :tarball
                               :version (gethash "version" p)
                               :url (gethash "url" p)))
        ;; Dependency has a git URL
        ((or (is-git-url? (gethash "url" p))
             (is-gh-url? (gethash "url" p)))
         (make-git-dependency :name (gethash "name" p)
                              :branch (gethash "branch" p)
                              :download-strategy :git
                              :version (or (gethash "tag" p)
                                           (gethash "revision" p)
                                           (gethash "version" p))
                              :url (gethash "url" p)))
        ;; Dependency has a Mercurial URL
        ((is-hg-url? (gethash "url" p))
         (make-hg-dependency :name (gethash "name" p)
                             :download-strategy :hg
                             :version (gethash "version" p)
                             :url (car (cl-ppcre:split ".hg" (gethash "url" p)))))

        ;; Dependency is local path
        ((not (null (gethash "path" p)))
         (make-local-dependency :name (gethash "name" p)
                                :download-strategy :local
                                :version (gethash "version" p)
                                :url (or (gethash "url" p) nil)))
        (t (error (format t "~%---X Cannot resolve dependency type")))))


(defun remove-old-versions (dep)
  "Walk the dependencies directory and remove versions of DEP that aren't current."
  (let* ((dependency-prefix (concatenate 'string (dependency-name dep) "-"))
         (old-versions
          (remove-if
           ;; don't delete the latest version, or tarballs for other dependencies
           (lambda (x) (or
                        (and (pathname-match-p (get-sys-path dep) x)
                             ;; if the version is unsset, delete it
                             ;; since that means we weren't able to
                             ;; determine the real version; otherwise
                             ;; keep it
                             (not (dependency-version dep)))
                        ;; keep it if it doesn't start with `dependency-prefix'
                        (not (eql (length dependency-prefix)
                                  (string> (first (last (pathname-directory x)))
                                           dependency-prefix)))))
           (uiop/filesystem:subdirectories (qi.paths:package-dir)))))

    (loop for dir in old-versions
       do (progn
            (format t "~%.... Deleting outdated ~A" dir)
            (uiop:run-program (concatenate 'string "rm -r " (namestring dir))
                              :wait t
                              :output :lines)))))


(defun download-tarball (url dep)
  "Downloads and unpacks tarball from URL for DEP."
  (let ((out-path (tarball-path dep)))
    (format t "~%---> Downloading tarball from ~A" url)
    (with-open-file (f (ensure-directories-exist out-path)
                       :direction :output
                       :if-does-not-exist :create
                       :if-exists :supersede
                       :element-type '(unsigned-byte 8))
      (let ((tar (drakma:http-request url :want-stream t)))
        (arnesi:awhile (read-byte tar nil nil)
          (write-byte arnesi:it f))
        (close tar)))
    (unpack-tar dep)))


(defun clone-git-repo (url dep)
  "Clones Git repository from URL."
  (let ((clone-path (get-sys-path dep)))
    (format t "~%---> Cloning ~A" url)

    (if (probe-file clone-path)
        (progn
          (update-repository :name (dependency-name dep)
                             :branch (dependency-branch dep)
                             :directory (namestring clone-path)
                             :revision (dependency-version dep)
                             :upstream url))
      (progn
        (format t "~%....      to ~A~%" (namestring clone-path))
        (run-git-command
         (concatenate 'string "clone " url " " (namestring clone-path)))))))


(defun clone-hg-repo (url dep)
  "Clones Mercurial repository from URL."
  (let ((clone-path (get-sys-path dep)))
    (format t "~%---> Cloning ~A" url)
    (format t "~%--->      to ~A" (namestring clone-path))
    (run-hg-command
     (concatenate 'string "clone " url " " (namestring clone-path)))
    (if (probe-file (fad:merge-pathnames-as-file
                     clone-path
                     (concatenate 'string (dependency-name dep) ".asd")))
      (error (format t "~%~%---X Failed to clone repository for ~A~%" url)))))


(defun tarball-path (dep)
  (let ((out-file (concatenate 'string
                                (dependency-name dep) "-"
                                (dependency-version dep) ".tar.gz")))
    (fad:merge-pathnames-as-file (qi.paths:+dep-cache+) (pathname out-file))))

(defun unpack-tar (dep)
  "Unarchive the downloaded DEP into its sys-path."
  (let* ((tar-path (tarball-path dep))
         (unzipped-actual (extract-tarball* tar-path (qi.paths:+dep-cache+)))
         (unzipped-expected (get-sys-path dep)))
    (if (probe-file unzipped-expected)
        ;; Make sure it always returns non-nil on success, for testing
        unzipped-expected
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


(defun get-sys-path (dependency)
  "Construct the sys-path for a DEPENDENCY."
  (fad:merge-pathnames-as-directory
   (qi.paths:package-dir)
   (concatenate 'string
                (dependency-name dependency)
                ;; If it's a (versioned) tarball, add the version to
                ;; the sys-path.  If it's a VCS source, then instead
                ;; of the version use the download strategy as a
                ;; suffix (since we'll want to update the existing
                ;; repository when the version is changed, rather than
                ;; fetching the entire repo to a new directory)
                (if (eql (dependency-download-strategy dependency) :tarball)
                    (concatenate 'string "-" (or (dependency-version dependency) "latest"))
                  (concatenate 'string "--" (string-downcase (symbol-name (dependency-download-strategy dependency)))))
                ;; Trailing slash to keep fad from thinking the last
                ;; part is a filename and stripping it
                "/")))


(defun make-dependency-available (dep)
  (setf asdf:*central-registry*
        ;; add this path to the ASDF registry.
        (list* (get-sys-path dep) asdf:*central-registry*)))


(defun install-transitive-dependencies (dep)
  (when (system-is-available? (dependency-name dep))
    ;; Skip transitive dependencies that are already installed, as
    ;; well as those explicitly specified in qi.yaml
    (let ((uninstalled (remove-if
                        (lambda (x) (or
                                     (installed? x)
                                     (member x *yaml-packages* :test #'(lambda (y z) (string= y (dependency-name z))))))
                        (asdf:system-depends-on (asdf:find-system (dependency-name dep))))))
      (loop for d in uninstalled do
           (let* ((from-manifest (manifest-get-by-name d))
                  (tdep (or
                         (car (member-if (lambda (x) (string= d (dependency-name x)))
                                         *yaml-packages*))
                         ;; If it's not defined in qi.yaml, check the manifest
                         (and from-manifest
                              (make-manifest-dependency
                               :name d
                               :url (manifest-package-url from-manifest)
                               :download-strategy (download-strategy (manifest-package-url from-manifest)))))))

             (unless (or tdep (system-is-available? d))
               (error (format t "~%~%---X Without ~A, we cannot install ~A~%" d (dependency-name dep))))

             (when (and tdep (not (installed? d)))
               (install-dependency tdep)))))))


(defun system-is-available? (sys)
  (handler-case
      (asdf:find-system sys)
    (error () () nil)))

(defun installed? (name)
  "Checks if NAME is in the `*qi-dependencies*'."
  (member name
          *qi-dependencies*
          :test #'(lambda (y z) (string= y (dependency-name z)))))
