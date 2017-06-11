(require 'asdf)

(defpackage #:test-git
  (:use #:cl)
  (:export #:main))

(asdf:defsystem #:test-git
  :description "Test"
  :depends-on (#:yason
               #:cl-test-1)
  :components ((:file "main")))
