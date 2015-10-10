(in-package :cl-user)
(defpackage qi-test
  (:use :cl
        :qi
        :qi.packages
        :qi.paths
        :prove))
(in-package :qi-test)


;; NOTE: To run this test file, execute `(asdf:test-system :qi)' in your Lisp.


(defun test-suite-setup ()
  ;; install prove, if it's not around
  (handler-bind ((error
                  #'(lambda (x)
                      (declare (ignore x))
                      (qi:install-global :prove))))
    (qi:up :prove)))


(test-suite-setup)


(plan 13)


;; -------------------
;; Utils tests

(ok (qi.util::is-tar-url? "https://github.com/CodyReichert/qi/master/master.tar.gz") "Is a tar url.")

(ok (qi.util::is-git-url? "https://github.com/CodyReichert/qi") "Is a git url.")
(ok (qi.util::is-git-url? "https://github.com/CodyReichert/qi.git") "Is a git url.")

(ok (qi.util::is-gh-url? "https://github.com/CodyReichert/qi") "Is a github url.")

(ok (qi.util::is-hg-url? "https://bitbucket.org/tarballs_are_good/map-set.hg") "Is a mercurial url.")

;; -------------------
;; Dependencies tests

(defvar git-dir (merge-pathnames "t/resources/git/" qi.paths:+qi-directory+)
  "Directory of resources for testing git functionality.")

(defvar hg-dir (merge-pathnames "t/resources/hg/" qi.paths:+qi-directory+)
  "Directory of resources for testing mercurial functionality.")

(let ((config
        (yaml:parse
         (merge-pathnames #p"qi.yaml" git-dir))))
  (ok "qi-git-test" (gethash "name" config))
  (let* ((p (car (gethash "packages" config)))
         (dep (qi::extract-dependency p)))
    (is (qi.packages::dependency-download-strategy dep) "git")
    (is (qi.packages::dependency-location dep)
        "https://github.com/sharplispers/split-sequence.git")))

(let ((config
        (yaml:parse
         (merge-pathnames #p"qi.yaml" hg-dir))))
  (ok "qi-hg-test" (gethash "name" config))
  (let* ((p (car (gethash "packages" config)))
         (dep (qi::extract-dependency p)))
    (is (qi.packages::dependency-download-strategy dep) "hg")
    (is (qi.packages::dependency-location dep)
        "https://bitbucket.org/tarballs_are_good/map-set")))


;; -------------------
;; Function tests

(defvar tar-dir (merge-pathnames "t/resources/tar/" qi.paths:+qi-directory+))

;; Tests that even if the tarball doesn't have the same name as what we expect, we still
;; sucessfully unpack it and load it.
(let* ((dep (qi::make-dependency :name "anaphora"
                                 :location (qi.packages::http "git@github.com/tokenrove/anaphora")
                                 :src-path (merge-pathnames tar-dir "anaphora-master.tar.gz")
                                 :sys-path (merge-pathnames tar-dir "anaphora-latest")
                                 :version "latest"))
       (out (qi.packages::unpack-tar dep tar-dir)))
  (ok (not (eql out (dependency-sys-path dep))) "Extracts tarball with different name.")
  (ok (probe-file (dependency-sys-path dep)) "Extracts tarball and exists"))


;; -------------------
;; End tests

(finalize)
