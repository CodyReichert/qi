(require 'asdf)

(defpackage #:test-tarball
  (:use #:cl)
  (:export #:main))

(asdf:defsystem #:test-tarball
  :description "Test"
  :depends-on (#:yason
               #:cl-test-1)
  :components ((:file "main")))
