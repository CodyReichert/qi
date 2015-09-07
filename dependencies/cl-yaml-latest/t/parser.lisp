(in-package :cl-user)
(defpackage cl-yaml-test.parser
  (:use :cl :fiveam)
  (:import-from :alexandria
                :alist-hash-table)
  (:export :parser)
  (:documentation "Parser tests."))
(in-package :cl-yaml-test.parser)

(def-suite parser
  :description "YAML parser tests.")
(in-suite parser)

(defmacro define-test-cases ((name) &rest pairs)
  `(test ,name
     ,@(loop for (string form) in pairs collecting
         `(is (equal (second (yaml.parser:parse-string ,string))
                     ,form)))))

(define-test-cases (special-scalars)
  ("[true, True, TRUE]"
   (list t t t))
  ("[false, False, FALSE]"
   (list nil nil nil))
  ("[null, Null, NULL, ~]"
   (list nil nil nil nil)))

(define-test-cases (integers)
  ("1"
   1)
  ("123456"
   123456)
  ("0001"
   1)
  ("-2"
   -2)
  ("0o31" ;; The old OCT 31 = DEC 25 joke
   25))

(define-test-cases (floats)
  ("6.62606957e-34"
   6.62607e-34))

(define-test-cases (lists)
  ("[a, b, c]"
   (list "a" "b" "c"))
  ("[1, 2, 3]"
   (list 1 2 3)))

(define-test-cases (nested-lists)
  ;; Right-nested list
  ("[1, [2, [3]]]"
   (list 1 (list 2 (list 3))))
  ;; Left-nested list
  ("[[[1], 2], 3]"
   (list (list (list 1) 2) 3))
  ;; Mid-centered list
  ("[1, [2, [3], 4], 5]"
   (list 1 (list 2 (list 3) 4) 5)))

(test top-level-parsing
  (let ((data (yaml:parse "[1,2,3]")))
    (is
     (equal data
            (list 1 2 3)))))

(test hash-tables
  (let ((data (yaml:parse "{ a: 1, b: 2}")))
    (is
     (equal (hash-table-count data)
            2))
    (is-false
     (set-difference (alexandria:hash-table-keys data)
                     (list "a" "b")
                     :test #'equal))
    (is-false
     (set-difference (alexandria:hash-table-values data)
                     (list 1 2)))))

(test parsing-errors
  (signals yaml.error:parsing-error
    (yaml:parse "[1,2,3")))

(test parse-file
  (is
   (equal (yaml:parse (asdf:system-relative-pathname :cl-yaml #p"t/test.yaml"))
          (list 1 2 3))))
