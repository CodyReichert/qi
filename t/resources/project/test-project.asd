(require 'asdf)

(defpackage #:test-project
  (:use #:cl)
  (:export #:main))

(asdf:defsystem #:test-project
  :description "Test"
  :depends-on (#:yason
               #:cl-test-1)
  :components ((:file "main")))
