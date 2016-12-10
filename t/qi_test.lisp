(in-package :cl-user)
(defpackage qi-test-qi
  (:use :cl
        :qi
        :prove))
(in-package :qi-test-packages)

(plan 3)

(ok (qi:hello))

(load "t/resources/project/test-project.asd")
(ok (qi:install :test-project))

(ok (qi:install-global :yason))

(finalize)
