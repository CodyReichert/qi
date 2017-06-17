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

(defvar qi-version
  "0.2.0"
  "The latest version of Qi.")

(defun hello ()
  "Qi status message."
  (format t "~%Qi - A Common Lisp Package Manager")
  (format t (concatenate 'string "~%Version " qi-version))
  (format t "~%Source: https://github.com/CodyReichert/qi")
  (format t "~%Issues: https://github.com/CodyReichert/qi/issues")
  t)


(defun install-global (system &optional version)
  "Install <system> into the user global packages directory. system should be
from the Qi Manifest. Optionally specify <version> to specifically install
a specific version of <system>. <version> defaults to latest. The system will
be made available in the current lisp session. To make the system available from
another lisp session, use (qi:up <system>)."
  (bootstrap :qi)
  (install-dependency
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
  (let* ((base-dir (qi.paths:project-dir project))
         (qi-file (merge-pathnames #p"qi.yaml" base-dir)))

    (install-from-qi-file qi-file)

    #+sbcl (sb-ext:without-package-locks (asdf:oos 'asdf:load-op project :verbose nil))
    #-sbcl (asdf:oos 'asdf:load-op project :verbose nil)
    ))

(defun bootstrap (proj)
  "Sets up Qi variables and loads the manifest."
  (setf +project-name+ proj)
  (setf *qi-dependencies* nil)
  (qi.manifest::manifest-load))


(defun install-from-qi-file (qi-file)
  (let ((fullpath (or (uiop/pathname:absolute-pathname-p qi-file)
                      (fad:merge-pathnames-as-file (uiop:getcwd) qi-file))))

    (unless (probe-file fullpath)
      (error (format t "~%No file exists at ~s" fullpath)))

    (format t "~%Reading dependencies...")
    (let* ((config (yaml:parse fullpath))
           (name (gethash "name" config))
           (package-list (gethash "packages" config)))

      (load (fad:merge-pathnames-as-file
             (directory-namestring fullpath)
             (concatenate 'string name ".asd")))
      (bootstrap name)

      (setf *yaml-packages* (mapcar #'extract-dependency package-list))

      (loop for package in *yaml-packages*
         do
           #+sbcl (sb-ext:without-package-locks (install-dependency package))
           #-sbcl (install-dependency package)
           ))

    (installed-dependency-report)
    t))


(defun installed-dependency-report ()
  "Print information about the *qi-dependencies* list."
   (if (= 0 (length *qi-dependencies*))
       (format t "~%~%No dependencies installed!")
     (progn
       (format t "~%~%~S dependencies installed:" (length *qi-dependencies*))
       (format t "~%~{   * ~A~%~}" (mapcar
                                    #'dependency-name
                                    (sort *qi-dependencies*
                                          (lambda (x y)
                                            (string-lessp (dependency-name x)
                                                          (dependency-name y)))))))))
