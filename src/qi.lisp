(in-package :cl-user)
(defpackage qi
  (:use :cl))
(in-package :qi)

;; code:

(defstruct dependency
  name
  location
  version)


(defun sym->str (sym)
  (string-downcase (symbol-name sym)))

(defun project-dir (proj)
  (asdf:system-relative-pathname proj (sym->str proj)))

(defun qi-dir ()
  (fad:merge-pathnames-as-directory
   (project-dir :qi)
   (ensure-directories-exist #P".dependencies/")))

(defun tar-dir ()
  (fad:merge-pathnames-as-directory
   (project-dir :qi)
   (ensure-directories-exist #P".dependencies/tar/")))

;(defun tar-path


;; Read .qi file, download dependecies
(defun get-deps-file (proj)
  (let* ((base-dir (project-dir proj))
         (qi-file (merge-pathnames #p".qi" base-dir)))
    (unless (probe-file qi-file)
      (error "No .qi file!"))
    (with-open-file (s qi-file)
      (do ((line (read-line s nil)
                 (read-line s nil)))
          ((null line))
        (let ((dep (to-dependency line)))
          (process-dep dep))))))
    

(defun to-dependency (dep)
  (multiple-value-bind (_ parts)
      (ppcre:scan-to-strings "^(.*?): (git|https.*?) (.*?$)" dep)
    (declare (ignore _)) ; we don't need the original line
    (make-dependency
     :name (svref parts 0)
     :location (svref parts 1)
     :version (svref parts 2))))


;; Save archives
(defmethod process-dep (dep)
  (format t "~%Downloading...")
  (format t "~%---> ~A from ~A (~A)~%"
          (dependency-name dep)
          (dependency-location dep)
          (dependency-version dep)))


(defmethod download-dep ())

;QI> (with-open-file (f (ensure-directories-exist #p".dependencies/cl-disque_master.tar.gz")
;                       :direction :output
;                       :if-does-not-exist :create
;                       :if-exists :supersede
;                       :element-type '(unsigned-byte 8))
;      (format t "Saving tarball to ~A" f)
;      (let ((input (drakma:http-request "https://github.com/codyreichert/cl-disque/archive/master.tar.gz"
;                                        :want-stream t)))
;        (arnesi:awhile (read-byte input nil nil)
;          (write-byte arnesi:it f))
;        (close input)))
 
