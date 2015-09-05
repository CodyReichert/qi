(in-package :cl-user)
(defpackage qi
  (:use :cl
        :qi.util
        :qi.paths)
  (:import-from :qi.packages
                :dependency
                :dependency-name
                :dependency-location
                :dependency-version
                :dispatch-dependency
                :make-dependency
                :location)
  (:export :read-qi-file))
(in-package :qi)

;; code:

(defun read-qi-file (proj)
  "Reads a qi.yaml file and starts downloading dependencies."
  (let* ((base-dir (qi.paths:project-dir proj))
         (qi-file (merge-pathnames #p"qi.yaml" base-dir)))
    (if (probe-file qi-file)
        (parse-deps qi-file)
        (error "No qi.yaml!"))))


(defun parse-deps (deps)
  (format t "~%Reading dependencies...")
  (let* ((config (yaml:parse deps))
         (package-list (gethash "packages" config)))
    (loop for p in package-list do
       ;; figure out what type of dependency is on this line
         (cond ((eql (type-of p) 'hash-table)
                (dispatch-dependency
                 (qi.packages::make-gh-dependency :name (gethash "name" p)
                                                  :location (qi.packages::github (gethash "url" p))
                                                  :version (gethash "version" p))))

               ((is-url? p)
                (dispatch-dependency
                 (qi.packages::make-tar-dependency :location p)))

               (t
                (dispatch-dependency
                 (qi.packages::make-local-dependency :location p)))))))
    

(defun is-url? (str)
  (ppcre:scan "^https?" str))

