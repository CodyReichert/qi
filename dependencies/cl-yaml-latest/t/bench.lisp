(in-package :cl-user)
(defpackage cl-yaml-test.bench
  (:use :cl :fiveam)
  (:export :bench)
  (:documentation "Benchmarks."))
(in-package :cl-yaml-test.bench)

;;; Utilities

(defmacro bench (string)
  `(finishes
     (format t "~%Benchmarking: ~S" ,string)
     (time
      (benchmark:with-timing (1000)
        (yaml:parse ,string)))))


;;; Tests

(def-suite bench
  :description "Benchmarking.")
(in-suite bench)

(test scalar
  (bench "123")
  (bench "1.234")
  (bench "test")
  (bench "null")
  (bench "[1, 2, 3]")
  (bench "{ a: 1, b: 2}"))
