(in-package :cl-user)
(defpackage qi.paths
  (:use :cl :qi.util)
  (:export :project-dir
           :+project-name+
           :qi-dir
           :tar-dir
           :package-dir
           :+qi-directory+
           :+qi-dep-dir+
           :+global-package-dir+))
(in-package :qi.paths)

;; Code:

;; Global paths

(defvar +qi-directory+ (merge-pathnames ".qi/" (user-homedir-pathname))
  "Pathname for the global ~/.qi directory.")

(defvar +qi-dep-dir+ (merge-pathnames "dependencies/" +qi-directory+)
  "Pathname for the global ~/.qi/dependencies directory.")

(defvar +global-package-dir+
  (merge-pathnames "packages/" +qi-directory+)
  "Where globally installed user-packages live.")

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

(defun tar-dir ()
  (fad:merge-pathnames-as-directory
   (project-dir +project-name+)
   (ensure-directories-exist #P".dependencies/archives/")))

(defun package-dir ()
  (fad:merge-pathnames-as-directory
   (project-dir +project-name+)
   (ensure-directories-exist #P".dependencies/packages/")))
