#|
  This file is a part of qi project.
  Copyright (c) 2015 Cody Reichert (codyreichert@gmail.com)
|#

#|
  A simple, open, project manager for Common Lisp

  Author: Cody Reichert (codyreichert@gmail.com)
|#

(in-package :cl-user)
(defpackage qi-asd
  (:use :cl :asdf))
(in-package :qi-asd)

(defsystem qi
  :version "0.1"
  :author "Cody Reichert"
  :license "MIT"
  :depends-on (:arnesi
               :cl-fad
               :cl-ppcre
               :cl-yaml
               :drakma
               :unix-opts
               :archive

               ; experimenting
               :cl-algebraic-data-type
               :local-package-aliases
               :optima)
  :components ((:module "src"
                :components
                ((:file "qi" :depends-on ("packages" "util" "paths"))
                 (:file "packages" :depends-on ("paths" "manifest"))
                 (:file "paths" :depends-on ("util"))
                 (:file "manifest")
                 (:file "util"))))
  :description "A simple, open, package manager for Common Lisp"
  :long-description
  #.(with-open-file (stream (merge-pathnames
                             #p"README.markdown"
                             (or *load-pathname* *compile-file-pathname*))
                            :if-does-not-exist nil
                            :direction :input)
      (when stream
        (let ((seq (make-array (file-length stream)
                               :element-type 'character
                               :fill-pointer t)))
          (setf (fill-pointer seq) (read-sequence seq stream))
          seq)))
  :in-order-to ((test-op (test-op qi-test))))
