(in-package :cl-user)
(defpackage qi
  (:use :cl)
  (:import-from :qi.util
                :asdf-system-path
                :load-asdf-system
                :is-tar-url?
                :is-git-url?
                :is-hg-url?
                :is-gh-url?)
  (:import-from :qi.paths
                :+project-name+)
  (:import-from :qi.packages
                :*qi-dependencies*
                :*qi-trans-dependencies*
                :dependency
                :dependency-name
                :dependency-location
                :dependency-version
                :dependency-sys-path
                :dispatch-dependency
                :transitive-dependency
                :transitive-dependency-name
                :transitive-dependency-caller
                :make-dependency
                :make-manifest-dependency
                :make-http-dependency
                :make-local-dependency
                :make-git-dependency
                :make-hg-dependency
                :http
                :location)
  (:export :hello
           :install
           :install-global
           :up))
(in-package :qi)

;; code:


(defun hello ()
  "Qi status message."
  (format t "~%Qi - A Common Lisp Package Manager")
  (format t "~%Version 0.1")
  (format t "~%Source: https://github.com/CodyReichert/qi")
  (format t "~%Issues: https://github.com/CodyReichert/qi/issues"))


(defun install-global (system &optional (version "latest"))
  "Install <system> into the user global packages directory. system should be
from the Qi Manifest. Optionally specify <version> to specifically install
a specific version of <system>. <version> defaults to latest. The system will
be made available in the current lisp session. To make the system available from
another lisp session, use (qi:up <system>)."
  (bootstrap :qi)
  (dispatch-dependency
   (make-manifest-dependency
    :name (qi.util:sym->str system)
    :version version))
  (asdf:load-system system)
  (installed-dependency-report))

(defun up (system)
  "Load <system> and make it available in the current lisp session."
  (asdf:load-system system))


(defun install (project)
  "Install <project> and all of its dependencies, and make the
system available in the current lisp session. A qi.yaml file should
be in the CWD that specifies <project>'s dependencies."
  (bootstrap project)
  (let* ((base-dir (qi.paths:project-dir project))
         (qi-file (merge-pathnames #p"qi.yaml" base-dir)))
    (if (probe-file qi-file)
        (install-from-qi-file qi-file)
        (error "No qi.yaml!"))))


(defun bootstrap (proj)
  "Sets up Qi variables and loads the manifest."
  (setf +project-name+ proj)
  (setf *qi-dependencies* nil)
  (setf *qi-trans-dependencies* nil)
  (qi.manifest::manifest-load))


(defun extract-dependency (p)
  "Extract dependency from package."
  (cond ((eql nil (gethash "url" p))
         (make-manifest-dependency :name (gethash "name" p)
                                   :version (or (gethash "version" p)
                                                "latest")))
        ;; Dependency is a tarball url
        ((is-tar-url? (gethash "url" p))
         (make-http-dependency :name (gethash "name" p)
                               :download-strategy "tarball"
                               :version (or (gethash "version" p)
                                            "latest")
                               :location (http (gethash "url" p))))
        ;; Dependency is git url
        ((or (is-git-url? (gethash "url" p))
             (is-gh-url? (gethash "url" p)))
         (make-git-dependency :name (gethash "name" p)
                              :download-strategy "git"
                              :version (or (gethash "version" p)
                                           "latest")
                              :location (or (gethash "url" p)
                                            nil)))
        ;; Dependency is mercurial url
        ((is-hg-url? (gethash "url" p))
         (make-hg-dependency :name (gethash "name" p)
                             :download-strategy "hg"
                             :version (or (gethash "version" p)
                                          "latest")
                             :location (or (car (cl-ppcre:split ".hg" (gethash "url" p)))
                                           nil)))
        ;; Dependency is local path
        ((not (null (gethash "path" p)))
         (make-local-dependency :name (gethash "name" p)
                                :download-strategy "local"
                                :version (or (gethash "version" p)
                                             "latest")
                                :location (or (gethash "url" p) nil)))
        (t nil)))


(defun install-from-qi-file (qi-file)
  (format t "~%Reading dependencies...")
  (let* ((config (yaml:parse qi-file))
         (name (gethash "name" config))
         (package-list (gethash "packages" config)))
    (loop for p in package-list
       do (let ((dep (extract-dependency p)))
            (if dep
                (dispatch-dependency dep)
                (format t "~%---X Cannot resolve dependency type"))))
    (asdf:oos 'asdf:load-op name :verbose nil))
  (dependency-report))


(defun dependency-report ()
  (installed-dependency-report))


(defun installed-dependency-report ()
  "Print information about the *qi-dependencies* list."
  (cond ((= 0 (length *qi-dependencies*))
         (format t "~%~%No dependencies installed!"))
        (t (let ((installed (remove-if-not #'dependency-sys-path *qi-dependencies*))
                 (trans-amt (length *qi-trans-dependencies*)))
             (format t "~%~%~S dependencies installed:" (length installed))
             (loop for d in *qi-dependencies*
                when (qi.packages::dependency-sys-path d) do
                  (format t "~%   * ~A" (dependency-name d)))
             (unless (= 0 trans-amt)
               (format t "~%~A transitive dependencies installed~%" trans-amt))))))
