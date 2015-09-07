(defsystem cl-libyaml-test
  :author "Fernando Borretti <eudoxiahp@gmail.com>"
  :license "MIT"
  :description "Tests for cl-libyaml."
  :depends-on (:cl-libyaml
               :fiveam)
  :components ((:module "t"
                :serial t
                :components
                ((:file "cl-libyaml")))))
