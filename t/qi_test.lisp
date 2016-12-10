(in-package :cl-user)
(defpackage qi-test-qi
  (:use :cl
        :qi
        :prove))
(in-package :qi-test-packages)

(plan 2)

(ok (qi:hello))

(ok (qi:install-global :yason))

(finalize)
