(in-package :cl-user)
(defpackage cl-yaml-test.spec
  (:use :cl :fiveam)
  (:export :spec)
  (:documentation "Run tests from the specification."))
(in-package :cl-yaml-test.spec)

(def-suite spec
  :description "Test cases from the spec.")
(in-suite spec)

(defun parse-corresponding-file (yaml-file)
  (let ((json-file (make-pathname :defaults yaml-file
                                  :type "json")))
    (yason:parse json-file)))

(test spec-tests
  (let ((directories (fad:list-directory
                      (asdf:system-relative-pathname :cl-yaml-test
                                                     #p"t/data/"))))
    (loop for directory in directories do
      (loop for file in (uiop:directory-files directory) do
        (when (string= (pathname-type file) "yaml")
          (format t "~%Spec: ~A" (pathname-name file))
          (let ((data (yaml:parse file))
                (json-data (parse-corresponding-file file)))
            (is-true
             (generic-comparability:equals data json-data))))))))
