(defpackage #:qi-setup
  (:use #:cl))
(in-package #:qi-setup)

;; Code:

(defvar +qi-directory+ (make-pathname :defaults *load-truename* :name nil :type nil))
(defvar +qi-dependencies+ (merge-pathnames "dependencies/" +qi-directory+))
(defvar +qi-user-packages+ (merge-pathnames ".dependencies/packages/" +qi-directory+))

(defun qi-dir (path)
  "Make a pathname rooted at +qi-directory+."
  (merge-pathnames path +qi-directory+))

(defun find-asdf-fasl ()
  (let* ((og-fasl (compile-file-pathname (qi-dir "asdf/asdf.lisp")))
         (asdf-fasl (qi-dir (make-pathname :defaults og-fasl
                                           :directory
                                           (list :relative "cache"
                                                 "asdf-fasls")))))
    (ensure-directories-exist asdf-fasl)
    asdf-fasl))

(defun ensure-asdf-loaded () ;; taken from quicklisp's resolver here
  "Try several methods to make sure that a sufficiently-new ASDF is
loaded: first try (require 'asdf), then loading the ASDF FASL, then
compiling asdf.lisp to a FASL and then loading it."
  (let* ((source (qi-dir "asdf/asdf.lisp"))
         (asdf-fasl (find-asdf-fasl)))
    (labels ((asdf-symbol (name)
               (let ((asdf-package (find-package '#:asdf)))
                 (when asdf-package
                   (find-symbol (string name) asdf-package))))
             (version-satisfies (version)
               (let ((vs-fun (asdf-symbol '#:version-satisfies))
                     (vfun (asdf-symbol '#:asdf-version)))
                 (when (and vs-fun vfun
                            (fboundp vs-fun)
                            (fboundp vfun))
                   (funcall vs-fun (funcall vfun) version)))))
      (block nil
        (macrolet ((try (&body asdf-loading-forms)
                     `(progn
                        (handler-bind ((warning #'muffle-warning))
                          (ignore-errors
                            ,@asdf-loading-forms))
                        (when (version-satisfies "3.0")
                          (return t)))))
          (try)
          (try (require 'asdf))
          (try (load asdf-fasl :verbose nil))
          (try (load (compile-file source :verbose nil :output-file asdf-fasl)))
          (error "Could not load ASDF ~S or newer" "3.0"))))))


(ensure-asdf-loaded)
(setf asdf:*asdf-verbose* nil)


(defun push-new-to-registry (dep)
  "Add a directory to the ASDF registry."
  (setf asdf:*central-registry* (pushnew dep asdf:*central-registry*)))


(defun load-user-packages ()
  "Make user-global-packages available to ASDF. They're not immediately
available like qi, but can be make so by (qi:qiload :<system>)."
  (loop for dir in (directory (qi-dir ".dependencies/packages/**"))
     do (push-new-to-registry dir)))


;; Walk ./dependencies and make all of qi's dependencies
;; available. Also walk ./.dependencies/packages to load in user
;; globally-installed packages.
(let ((qi-deps-to-load (directory (concatenate 'string (namestring +qi-dependencies+) "**"))))
  (setf asdf:*central-registry* nil)
  (push-new-to-registry +qi-directory+)
  (loop for d in qi-deps-to-load
     do
       (push-new-to-registry d))
  (load-user-packages))


;; Load Qi
(let ((*compile-print* nil)
      (*compile-verbose* nil)
      (*load-verbose* nil)
      (*load-print* nil))
  (handler-bind ((warning #'muffle-warning))
    (ignore-errors
      (asdf:oos 'asdf:load-op 'qi :verbose nil))))
