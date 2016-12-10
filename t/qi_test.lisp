(in-package :cl-user)
(defpackage qi-test-qi
  (:use :cl
        :qi
        :prove))
(in-package :qi-test-packages)

(plan 1)

(ok (qi:install-global :yason))

(finalize)
