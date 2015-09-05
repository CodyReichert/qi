(in-package :cl-user)
(defpackage qi.paths
  (:use :cl :qi.util)
  (:export :project-dir
           :qi-dir
           :tar-dir
           :package-dir))
(in-package :qi.paths)

;; Code:

(defun project-dir (proj)
  (asdf:system-relative-pathname proj (qi.util:sym->str proj)))

(defun qi-dir ()
  (fad:merge-pathnames-as-directory
   (project-dir :qi)
   (ensure-directories-exist #P".dependencies/")))

(defun tar-dir ()
  (fad:merge-pathnames-as-directory
   (project-dir :qi)
   (ensure-directories-exist #P".dependencies/archives/")))

(defun package-dir ()
  (fad:merge-pathnames-as-directory
   (project-dir :qi)
   (ensure-directories-exist #P".dependencies/packages/")))

