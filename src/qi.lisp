(in-package :cl-user)
(defpackage qi
  (:use :cl)
  (:import-from :qi.util
                :asdf-system-path
                :is-tar-url?
                :is-git-url?
                :is-gh-url?)
  (:import-from :qi.paths
                :+project-name+
                :+global-package-dir+)
  (:import-from :qi.packages
                :*qi-dependencies*
                :*qi-broken-dependencies*
                :*qi-trans-dependencies*
                :*qi-broken-trans-dependencies*
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
  (installed-dependency-report)
  (broken-dependency-report))

(defun up (system)
  "Load <system> with system to it's available in the current lisp session."
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
  (setf *qi-broken-dependencies* nil)
  (setf *qi-trans-dependencies* nil)
  (setf *qi-broken-trans-dependencies* nil)
  (qi.manifest::manifest-load))


(defun install-from-qi-file (qi-file)
  (format t "~%Reading dependencies...")
  (let* ((config (yaml:parse qi-file))
         (name (gethash "name" config))
         (package-list (gethash "packages" config)))
    (loop for p in package-list do
         (cond ((eql nil (gethash "url" p))
                (dispatch-dependency
                 (make-manifest-dependency :name name
                                           :version (or (gethash "version" p)
                                                        "latest"))))
               ;; Dependency is a tarball url
               ((is-tar-url? (gethash "url" p))
                (dispatch-dependency
                 (make-http-dependency :name name
                                       :download-strategy "tarball"
                                       :version (or (gethash "version" p)
                                                    "latest")
                                       :location (http (gethash "url" p)))))
               ;; Dependency is git url
               ((or (is-git-url? (gethash "url" p))
                    (is-gh-url? (gethash "url" p)))
                (dispatch-dependency
                 (make-git-dependency :name name
                                      :download-strategy "git"
                                      :version (or (gethash "version" p)
                                                   "latest")
                                      :location (or (gethash "url" p)
                                                    nil))))
               ;; Dependency is local path
               ((not (null (gethash "path" p)))
                (dispatch-dependency
                 (make-local-dependency :name name
                                        :download-strategy "local"
                                        :version (or (gethash "version" p)
                                                     "latest")
                                        :location (or (gethash "url" p) nil))))

               (t (format t "~%---X Cannot resolve dependency type"))))
    (asdf:oos 'asdf:load-op name :verbose nil))
  (installed-dependency-report)
  (broken-dependency-report))


(defun installed-dependency-report ()
  (cond ((= 0 (length *qi-dependencies*))
         (format t "~%~%No dependencies installed!"))
        (t (let ((installed (remove-if-not #'(lambda (x)
                                               (dependency-sys-path x))
                                           *qi-dependencies*)))
             (format t "~%~%~S dependencies installed:" (length installed))
             (loop for d in *qi-dependencies*
                when (qi.packages::dependency-sys-path d) do
                  (format t "~%   * ~A" (dependency-name d))))
           (format t "~%~A transitive dependencies installed"
                   (length *qi-trans-dependencies*)))))

(defun broken-dependency-report ()
  (cond ((not (= 0 (length *qi-broken-dependencies*)))
         (let ((amt-broken (length *qi-broken-dependencies*)))
           (format t "~%~%~S required dependencies not installed:" amt-broken)
           (loop for d in *qi-broken-dependencies* do
                (format t "~%   * ~A" (dependency-name d))))))
  (cond ((not (= 0 (length *qi-broken-trans-dependencies*)))
         (let ((amt-broken (length *qi-broken-trans-dependencies*)))
           (format t "~%~S transitive dependencies not installed:" amt-broken)
           (loop for d in *qi-broken-trans-dependencies* do
                (format t "~%  ~A (required by ~S)"
                        (transitive-dependency-name d)
                        (transitive-dependency-caller d)))))))
