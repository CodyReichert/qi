(in-package :cl-user)
(defpackage qi-manifest-util
  (:use :cl
        :qi
        :prove))
(in-package :qi-manifest-util)

(plan 4)

(qi.manifest::manifest-load)

(let ((strat (multiple-value-list
              (qi.manifest:create-download-strategy
               (qi.manifest:manifest-get-by-name "alexandria")))))
  (is (first strat) "https://gitlab.common-lisp.net/alexandria/alexandria.git")
  (is (last strat) '("git")))

(is-type (qi.manifest:manifest-get-by-name "alexandria")
         'qi.manifest:manifest-package)
(ok (not (qi.manifest:manifest-get-by-name "l;akdsjfl;")))

(finalize)
