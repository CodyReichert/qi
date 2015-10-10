(in-package :cl-user)
(defpackage qi-test
  (:use :cl
        :qi
        :qi.packages
        :qi.paths
        :prove))
(in-package :qi-test)

;; NOTE: To run this test file, execute `(asdf:test-system :qi)' in your Lisp.


(plan 13)


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

(let ((config
        (yaml:parse
         (merge-pathnames #p"qi.yaml" "t/resources/hg/"))))
  (ok "qi-hg-test" (gethash "name" config))
  (let* ((p (car (gethash "packages" config)))
         (dep (qi::extract-dependency p)))
    (is (qi.packages::dependency-download-strategy dep) "hg")
    (is (qi.packages::dependency-location dep)
        "https://bitbucket.org/tarballs_are_good/map-set")))


;; -------------------
;; Function tests

(defvar tar-dir (merge-pathnames "t/resources/tar/" qi.paths:+qi-directory+))

;; Tests that even the the tarball doesn't have the same name as what we expect, we still
;; sucessfully unpack it and load it.
(let* ((dep (qi::make-dependency :name "anaphora"

                                 :location (qi.packages::http "git@github.com/tokenrove/anaphora")
                                 :src-path (merge-pathnames tar-dir "anaphora-master.tar.gz")
                                 :sys-path (merge-pathnames tar-dir "anaphora-latest")
                                 :version "latest"))
       (out (qi.packages::unpack-tar dep tar-dir)))
  (ok (not (eql out (dependency-sys-path dep))) "Extract tarball with different name.")
  (ok (probe-file (dependency-sys-path dep)) "Extracted tarball exists"))


;; -------------------
;; End tests

(finalize)
