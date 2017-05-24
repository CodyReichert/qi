(in-package :cl-user)
(defpackage qi-test-qi
  (:use :cl
        :qi
        :prove))
(in-package :qi-test-packages)

(plan 4)

(ok (qi:hello))

(load "t/resources/project/test-project.asd")
(ok (qi:install :test-project))

(ok (qi:install-global :yason))

(is-error (qi:install-from-qi-file "/path/to/nonexistent/qi.yaml") 'error)

(finalize)
