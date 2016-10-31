(in-package :cl-user)
(defpackage qi-manifest-util
  (:use :cl
        :qi
        :prove))
(in-package :qi-manifest-util)

(plan 3)

(qi.manifest::manifest-load)

(let ((manifest (qi.manifest:manifest-get-by-name "alexandria")))
  (is (qi.manifest::manifest-package-url manifest) "https://gitlab.common-lisp.net/alexandria/alexandria.git"))

(is-type (qi.manifest:manifest-get-by-name "alexandria")
         'qi.manifest:manifest-package)
(ok (not (qi.manifest:manifest-get-by-name "l;akdsjfl;")))

(finalize)
