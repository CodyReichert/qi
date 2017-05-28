(in-package :cl-user)
(defpackage qi-test-qi
  (:use :cl
        :qi
        :prove))
(in-package :qi-test-packages)

(defun reset-metadata ()
  "Unset the variables from `qi:bootstrap'.  We run this between
install tests to ensure a clean environment, simulating how they're
run from the command-line."
  (setf qi::+project-name+ nil)
  (setf qi.manifest::+manifest-packages+ nil))

(plan 5)

(ok (qi:hello))

(ok (qi:install-global :yason))
(reset-metadata)

(load "t/resources/project/test-project.asd")
(ok (qi:install :test-project))
(reset-metadata)

(ok (qi:install-from-qi-file "t/resources/project/qi.yaml"))
(is-error (qi:install-from-qi-file "/path/to/nonexistent/qi.yaml") 'error)
(reset-metadata)

(finalize)
