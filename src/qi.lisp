(in-package :cl-user)
(defpackage qi
  (:use :cl :qi.util :qi.paths)
  (:import-from :qi.packages
                :*qi-dependencies*
                :*qi-broken-dependencies*
                :*qi-trans-dependencies*
                :*qi-broken-trans-dependencies*
                :dependency
                :dependency-name
                :dependency-location
                :dependency-version
                :dependency-sys-path
                :dispatch-dependency
                :transitive-dependency
                :transitive-dependency-name
                :transitive-dependency-caller
                :make-dependency
                :make-manifest-dependency
                :make-http-dependency
                :make-local-dependency
                :make-git-dependency
                :http
                :location)
  (:export :install))
(in-package :qi)

;; code:


(defun bootstrap ()
  (setf *qi-dependencies* nil)
  (setf *qi-broken-dependencies* nil)
  (setf *qi-trans-dependencies* nil)
  (setf *qi-broken-trans-dependencies* nil)
  (qi.manifest::manifest-load))


(defun install (proj)
  "Reads a qi.yaml file and starts downloading dependencies."
  (bootstrap)
  (let* ((base-dir (qi.paths:project-dir proj))
         (qi-file (merge-pathnames #p"qi.yaml" base-dir)))
    (if (probe-file qi-file)
        (parse-deps qi-file)
        (error "No qi.yaml!"))))


(defun parse-deps (deps)
  (format t "~%Reading dependencies...")
  (let* ((config (yaml:parse deps))
         (name (gethash "name" config))
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

               (t (format t "~%---X Cannot resolve dependency type"))))
    (asdf:oos 'asdf:load-op name))
  (installed-dependency-report)
  (broken-dependency-report))


(defun installed-dependency-report ()
  (cond ((= 0 (length *qi-dependencies*))
         (format t "~%~%No dependencies installed!"))
        (t
         (let ((installed (remove-if-not #'(lambda (x) (dependency-sys-path x)) *qi-dependencies*)))
           (format t "~%~%~S dependencies installed:" (length installed))
           (loop for d in *qi-dependencies*
              when (qi.packages::dependency-sys-path d) do
                (format t "~%   * ~A" (dependency-name d))))
         (format t "~%~A transitive dependencies installed" (length *qi-trans-dependencies*)))))

(defun broken-dependency-report ()
  (cond ((not (= 0 (length *qi-broken-dependencies*)))
         (let ((amt-broken (length *qi-broken-dependencies*)))
           (format t "~%~%~S required dependencies not installed:" amt-broken)
           (loop for d in *qi-broken-dependencies* do
                (format t "~%   * ~A" (dependency-name d))))))
  (cond ((not (= 0 (length *qi-broken-trans-dependencies*)))
         (let ((amt-broken (length *qi-broken-trans-dependencies*)))
           (format t "~%~S transitive dependencies not installed:" amt-broken)
           (loop for d in *qi-broken-trans-dependencies* do
                (format t "~%  ~A (required by ~S)"
                        (transitive-dependency-name d)
                        (transitive-dependency-caller d)))))))

(defun is-tar-url? (str)
  (or (ppcre:scan "^https?.*.tgz" str)
      (ppcre:scan "^https?.*tar.gz" str)))

(defun is-git-url? (str)
  (or (ppcre:scan "^git://.*" str)
      (ppcre:scan ".*.git" str)))

(defun is-gh-url? (str)
  (ppcre:scan "^https?//github.*" str))
