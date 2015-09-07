(in-package :cl-user)
(defpackage cl-yaml-test.scalar
  (:use :cl :fiveam)
  (:export :scalar)
  (:documentation "Scalar parsing tests."))
(in-package :cl-yaml-test.scalar)

;;; Macros

(defmacro scalar-equal (string value)
  `(is
    (equal (yaml.scalar:parse-scalar ,string)
           ,value)))

;;; Tests

(def-suite scalar
  :description "YAML scalar parsing tests.")
(in-suite scalar)

(test special-constants
  ;; Null
  (scalar-equal "null" nil)
  (scalar-equal "Null" nil)
  (scalar-equal "NULL" nil)
  (scalar-equal "~" nil)
  ;; Boolean
  (scalar-equal "true" t)
  (scalar-equal "True" t)
  (scalar-equal "TRUE" t)
  (scalar-equal "false" nil)
  (scalar-equal "False" nil)
  (scalar-equal "FALSE" nil))

(test integers
  (scalar-equal "123" 123)
  (scalar-equal "012345" 12345)
  (scalar-equal "-555" -555)
  (scalar-equal "0x25" 37))

(test floats
  (scalar-equal "1.234" 1.234)
  (scalar-equal "1e5" 1e5))

(test special-floats
  (scalar-equal ".nan" :NaN)
  (scalar-equal ".NaN" :NaN)
  (scalar-equal ".NAN" :NaN)
  (scalar-equal ".inf" :+Inf)
  (scalar-equal ".Inf" :+Inf)
  (scalar-equal ".INF" :+Inf)
  (scalar-equal "-.inf" :-Inf)
  (scalar-equal "-.Inf" :-Inf)
  (scalar-equal "-.INF" :-Inf))
