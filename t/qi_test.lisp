(in-package :cl-user)
(defpackage qi-test-qi
  (:use :cl
        :qi
        :prove))
(in-package :qi-test-packages)

(plan 5)

(ok (qi:hello))

(ok (qi:install-global :yason))

(load "t/resources/project/test-project.asd")
(ok (qi:install :test-project))

(ok (qi:install-from-qi-file "t/resources/project/qi.yaml"))
(is-error (qi:install-from-qi-file "/path/to/nonexistent/qi.yaml") 'error)

(finalize)
