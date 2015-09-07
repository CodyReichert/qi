(in-package :cl-user)
(defpackage cl-yaml-test.float
  (:use :cl :fiveam)
  (:export :float)
  (:documentation "Test floating-point number support."))
(in-package :cl-yaml-test.float)

(def-suite float
  :description "YAML IEEE float tests.")
(in-suite float)

(test not-a-number
  (is
   (equal (yaml.float:not-a-number)
          :NaN))
  (is
   (equal (yaml.float:positive-infinity)
          :+Inf))
  (is
   (equal (yaml.float:negative-infinity)
          :-Inf)))

#+sbcl
(test sbcl-nan
  (let ((yaml.float:*float-strategy* :best-effort))
    (is-true
     (sb-ext:float-nan-p (yaml.float:not-a-number)))
    (is-true
     (sb-ext:float-infinity-p (yaml.float:positive-infinity)))
    (is-true
     (sb-ext:float-infinity-p (yaml.float:negative-infinity)))))

(test error-strategy
  (let ((yaml.float:*float-strategy* :error))
    (signals yaml.error:unsupported-float-value
      (yaml.float:not-a-number))
    (signals yaml.error:unsupported-float-value
      (yaml.float:positive-infinity))
    (signals yaml.error:unsupported-float-value
      (yaml.float:negative-infinity))))
