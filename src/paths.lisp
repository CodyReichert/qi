(in-package :cl-user)
(defpackage qi.paths
  (:use :cl :qi.util)
  (:export :project-dir
           :+project-name+
           :qi-dir
           :tar-dir
           :package-dir))
(in-package :qi.paths)

;; Code:

(defvar +project-name+ nil)

(defun project-dir (proj)
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
