(in-package :cl-user)
(defpackage qi-test
  (:use :cl
        :qi
        :prove))
(in-package :qi-test)

;; NOTE: To run this test file, execute `(asdf:test-system :qi)' in your Lisp.

(plan 11)


;; -------------------
;; Utils tests

(ok (qi.util::is-tar-url? "https://github.com/CodyReichert/qi/master/master.tar.gz"))

(ok (qi.util::is-git-url? "https://github.com/CodyReichert/qi"))
(ok (qi.util::is-git-url? "https://github.com/CodyReichert/qi.git"))

(ok (qi.util::is-gh-url? "https://github.com/CodyReichert/qi"))

(ok (qi.util::is-hg-url? "https://bitbucket.org/tarballs_are_good/map-set.hg"))

;; -------------------
;; Dependencies tests

(let ((config
        (yaml:parse
         (merge-pathnames #p"qi.yaml" "t/resources/git/"))))
  (ok "qi-git-test" (gethash "name" config))
  (let* ((p (car (gethash "packages" config)))
         (dep (qi::extract-dependency p)))
    (is (qi.packages::dependency-download-strategy dep) "git")
    (is (qi.packages::dependency-location dep)
        "https://github.com/sharplispers/split-sequence.git")))

(let ((config
        (yaml:parse
         (merge-pathnames #p"qi.yaml" "t/resources/hg/"))))
  (ok "qi-hg-test" (gethash "name" config))
  (let* ((p (car (gethash "packages" config)))
         (dep (qi::extract-dependency p)))
    (is (qi.packages::dependency-download-strategy dep) "hg")
    (is (qi.packages::dependency-location dep)
        "https://bitbucket.org/tarballs_are_good/map-set")))


(finalize)
