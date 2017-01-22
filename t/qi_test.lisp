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

(plan 7)

(ok (qi:hello))

(ok (qi:install-global :yason) "yason installed globally")
(reset-metadata)

(is-error (qi:install-from-qi-file "/path/to/nonexistent/qi.yaml") 'error)

(load "t/resources/project/test-project.asd")
(ok (qi:install :test-project) "test-project is installed")
(is (test-project:main) "0.0.1")
(reset-metadata)

;; For some reason `sed -i` isn't working
(uiop:run-program "sed 's/0\.0\.1/0.0.2/' qi.yaml >> qwop.yaml"
                  :directory #P"t/resources/project/"
                  :wait t)
(uiop:run-program "mv qwop.yaml qi.yaml"
                  :directory #P"t/resources/project/"
                  :wait t)

(ok (qi:install :test-project) "test-project is re-installed")
(is (test-project:main) "0.0.2" "qi should load the newer version of cl-test-1")
(reset-metadata)

;; Revert
(uiop:run-program "sed 's/0\.0\.2/0.0.1/' qi.yaml >> qwop.yaml"
                  :directory #P"t/resources/project/"
                  :wait t)
(uiop:run-program "mv qwop.yaml qi.yaml"
                  :directory #P"t/resources/project/"
                  :wait t)

(finalize)
