#|
  This file is a part of qi project.
  Copyright (c) 2015 Cody Reichert (codyreichert@gmail.com)
|#

(in-package :cl-user)
(defpackage qi-test-asd
  (:use :cl :asdf))
(in-package :qi-test-asd)

(defsystem qi-test
  :author "Cody Reichert"
  :license ""
  :depends-on (:qi
               :uiop
               :prove)
  :components ((:module "t"
                        :components (
                                     (:test-file "integrations_test")
                                     (:test-file "manifest_test")
                                     (:test-file "packages_test")
                                     (:test-file "util_test")
                                     )))
  :description "Test system for qi"

  :defsystem-depends-on (:prove-asdf)
  :perform (test-op :after (op c)
                    (funcall (intern #.(string :run-test-system) :prove-asdf) c)
                    (asdf:clear-system c)))
