(in-package :cl-user)
(defpackage qi.paths
  (:use :cl :qi.util)
  (:export :+dep-cache+
           :+global-package-dir+
           :+project-name+
           :+qi-dep-dir+
           :+qi-directory+
           :package-dir
           :project-dir
           :qi-dir))
(in-package :qi.paths)

;; Code:

;; Global paths

(defvar +qi-directory+ (asdf:system-source-directory "qi")
  "Pathname for the global Qi directory.")

(defvar +qi-dep-dir+ (merge-pathnames "dependencies/" +qi-directory+)
  "Pathname for the global dependencies/ directory.")

(defvar +global-package-dir+
  (merge-pathnames "packages/" +qi-directory+)
  "Where globally installed user-packages live.")

(defun +dep-cache+ ()
  (fad:merge-pathnames-as-directory
   (or (uiop:getenv "TMPDIR")
       "/tmp")
   #P"qi/archives/"))

;; Project local paths

(defvar +project-name+ nil
  "Name of the current, local project (from qi.yaml).  Returns NIL if
Qi is not running in the context of a project.")

(defun project-dir (proj)
  "Pathname/directory for <proj>."
  (asdf:system-relative-pathname proj (qi.util:sym->str proj)))

(defun qi-dir ()
  (fad:merge-pathnames-as-directory
   (project-dir +project-name+)
   (ensure-directories-exist #P".dependencies/")))

(defun package-dir ()
  (fad:merge-pathnames-as-directory
   (project-dir +project-name+)
   (ensure-directories-exist #P".dependencies/packages/")))
