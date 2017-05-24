(in-package :cl-user)
(defpackage qi
  (:use :cl)
  (:import-from :qi.util
                :asdf-system-path
                :download-strategy
                :load-asdf-system)
  (:import-from :qi.paths
                :+project-name+)
  (:import-from :qi.packages
                :*qi-dependencies*
                :*yaml-packages*
                :dependency
                :dependency-name
                :dependency-url
                :dependency-version
                :dependency-sys-path
                :dispatch-dependency
                :extract-dependency
                :make-dependency
                :make-manifest-dependency
                :make-http-dependency
                :make-local-dependency
                :make-git-dependency
                :make-hg-dependency
                :http
                :location)
  (:import-from :qi.manifest
                :manifest-get-by-name
                :manifest-package
                :manifest-package-url)
  (:export :hello
           :install
           :install-from-qi-file
           :install-global
           :up))
(in-package :qi)

;; code:


(defun hello ()
  "Qi status message."
  (format t "~%Qi - A Common Lisp Package Manager")
  (format t "~%Version 0.1")
  (format t "~%Source: https://github.com/CodyReichert/qi")
  (format t "~%Issues: https://github.com/CodyReichert/qi/issues")
  t)


(defun install-global (system &optional (version "latest"))
  "Install <system> into the user global packages directory. system should be
from the Qi Manifest. Optionally specify <version> to specifically install
a specific version of <system>. <version> defaults to latest. The system will
be made available in the current lisp session. To make the system available from
another lisp session, use (qi:up <system>)."
  (bootstrap :qi)
  (dispatch-dependency
   (let* ((name-string (qi.util:sym->str system))
          (package (manifest-get-by-name name-string)))
     (make-manifest-dependency :name name-string
                               :url (manifest-package-url package)
                               :download-strategy (download-strategy
                                                   (manifest-package-url package))
                               :version version)))
  #+sbcl (sb-ext:without-package-locks (asdf:load-system system))
  #-sbcl (asdf:load-system system)
  (installed-dependency-report)
  t)

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
        #+sbcl (sb-ext:without-package-locks (install-from-qi-file qi-file))
        #-sbcl (install-from-qi-file qi-file)
      (error "No qi.yaml!"))))


(defun bootstrap (proj)
  "Sets up Qi variables and loads the manifest."
  (setf +project-name+ proj)
  (setf *qi-dependencies* nil)
  (qi.manifest::manifest-load))


(defun install-from-qi-file (qi-file)
  (unless (probe-file qi-file)
    (error (format t "~%No file exists at ~s" qi-file)))

  (format t "~%Reading dependencies...")
  (let* ((config (yaml:parse qi-file))
         (name (gethash "name" config))
         (package-list (gethash "packages" config)))

    (setf *yaml-packages* (mapcar #'extract-dependency package-list))

    ;; Then loop through again and install them
    (loop for package in *yaml-packages*
       do (dispatch-dependency package))
    (asdf:oos 'asdf:load-op name :verbose nil))
  (dependency-report)
  t)


(defun dependency-report ()
  (installed-dependency-report))


(defun installed-dependency-report ()
  "Print information about the *qi-dependencies* list."
   (if (= 0 (length *qi-dependencies*))
       (format t "~%~%No dependencies installed!")
     (let ((installed (remove-if-not #'dependency-sys-path *qi-dependencies*)))
       (format t "~%~%~S dependencies installed:" (length installed))
       (format t "~%~{   * ~A~%~}" (mapcar
                                    #'dependency-name
                                    (sort installed (lambda (x y)
                                                      (string-lessp (dependency-name x)
                                                                    (dependency-name y)))))))))
