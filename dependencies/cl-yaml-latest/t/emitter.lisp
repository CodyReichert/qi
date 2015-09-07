(in-package :cl-user)
(defpackage cl-yaml-test.emitter
  (:use :cl :fiveam)
  (:import-from :alexandria
                :alist-hash-table)
  (:export :emitter)
  (:documentation "Emitter tests."))
(in-package :cl-yaml-test.emitter)

;;; Macros

(defmacro define-test-cases ((name) &rest pairs)
  `(test ,name
     ,@(loop for (form string) in pairs collecting
         `(is (equal (yaml.emitter:emit-to-string ,form)
                     ,string)))))

;;; Tests

(def-suite emitter
  :description "YAML emitter tests.")
(in-suite emitter)

(define-test-cases (boolean)
  (t
   "true")
  (nil
   "false"))

(define-test-cases (integers)
  (1
   "1")
  (123
   "123")
  (+123
   "123")
  (-123
   "-123"))

(define-test-cases (floats)
  (1.23
   "1.23")
  (6.62607e-34
   "6.62607e-34"))

(define-test-cases (lists)
  ((list 1 2 3)
   "[1, 2, 3]")
  ((vector 1 2 3)
   "[1, 2, 3]"))

(test hash-tables
  (let ((table (alexandria:alist-hash-table
                (list (cons "a" 1)
                      (cons "b" 2)))))
    (is
     (equal (yaml:emit-to-string table)
            "{ b: 2, a: 1 }"))))

(test toplevel-function
  (is
    (equal (yaml:emit-to-string 1)
           "1"))
  (is
    (equal (with-output-to-string (stream)
             (yaml:emit 1 stream))
           "1")))

