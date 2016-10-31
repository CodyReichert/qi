(in-package :cl-user)
(defpackage qi.paths
  (:use :cl :qi.util)
  (:export :+dep-cache+
           :+project-name+
           :+qi-directory+
           :package-dir
           :project-dir))
(in-package :qi.paths)

;; Code:

;; Global paths

(defvar +qi-directory+ (asdf:system-source-directory "qi")
  "Pathname for the global Qi directory.")


(defun +dep-cache+ ()
  (fad:merge-pathnames-as-directory
   (or (uiop:getenv "TMPDIR")
       "/tmp/")
   #P"qi/archives/"))

;; Project local paths

(defvar +project-name+ nil
  "Name of the current, local project (from qi.yaml).  Returns NIL if
Qi is not running in the context of a project.")

(defun project-dir (proj)
  "Pathname/directory for <proj>."
  (asdf:system-relative-pathname proj (qi.util:sym->str proj)))

(defun package-dir ()
  (ensure-directories-exist
   (fad:merge-pathnames-as-directory
    (project-dir +project-name+)
    #P".dependencies/packages/")))
