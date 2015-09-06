(in-package :cl-user)
(defpackage qi
  (:use :cl
        :qi.util
        :qi.paths)
  (:import-from :qi.packages
                :*qi-dependencies*
                :dependency
                :dependency-name
                :dependency-location
                :dependency-version
                :dispatch-dependency
                :make-dependency
                :make-manifest-dependency
                :make-http-dependency
                :make-local-dependency
                :make-git-dependency
                :http
                :location)
  (:export :read-qi-file))
(in-package :qi)

;; code:

(defun read-qi-file (proj)
  "Reads a qi.yaml file and starts downloading dependencies."
  (setf *qi-dependencies* nil)
  (let* ((base-dir (qi.paths:project-dir proj))
         (qi-file (merge-pathnames #p"qi.yaml" base-dir)))
    (if (probe-file qi-file)
        (parse-deps qi-file)
        (error "No qi.yaml!"))))


(defun parse-deps (deps)
  (format t "~%Reading dependencies...")
  (setf asdf:*central-registry* nil)
  (let* ((config (yaml:parse deps))
         (package-list (gethash "packages" config)))
    (loop for p in package-list do
         (cond ((eql nil (gethash "url" p))
                (dispatch-dependency
                 (make-manifest-dependency :name (gethash "name" p)
                                           :version (or (gethash "version" p) "latest")
                                           :location (or (gethash "url" p) nil))))
               ;; Dependency is a tarball url
               ((is-tar-url? (gethash "url" p))
                (dispatch-dependency
                 (make-http-dependency :name (gethash "name" p)
                                       :download-strategy "tarball"
                                       :version (or (gethash "version" p) "latest")
                                       :location (or (http (gethash "url" p)) nil))))
               ;; Dependency is git url
               ((or (is-git-url? (gethash "url" p))
                    (is-gh-url? (gethash "url" p)))
                (dispatch-dependency
                 (make-git-dependency :name (gethash "name" p)
                                      :download-strategy "git"
                                      :version (or (gethash "version" p) "latest")
                                      :location (or (gethash "url" p) nil))))
               ;; Dependency is local path
               ((not (null (gethash "path" p)))
                (dispatch-dependency
                 (make-local-dependency :name (gethash "name" p)
                                        :download-strategy "local"
                                        :version (or (gethash "version" p) "latest")
                                        :location (or (gethash "url" p) nil))))

               (t (format t "~%---X Cannot resolve dependency type"))))))
    

(defun is-tar-url? (str)
  (ppcre:scan "^https?.*tar.gz" str))

(defun is-git-url? (str)
  (or
   (ppcre:scan "^git://.*" str)
   (ppcre:scan ".*.git" str)))

(defun is-gh-url? (str)
  (ppcre:scan "^https?//github.*" str))
