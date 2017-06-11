(in-package :cl-user)
(defpackage qi-test-qi
  (:use :cl
        :qi
        :prove))
(in-package :qi-test-packages)

(plan 3)

(ok (qi:hello))

(ok (qi:install-global :yason) "yason installed globally")

(is-error (qi:install-from-qi-file "/path/to/nonexistent/qi.yaml") 'error)

(finalize)
