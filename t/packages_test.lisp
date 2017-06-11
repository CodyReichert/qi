(in-package :cl-user)
(defpackage qi-test-packages
  (:use :cl
        :qi
        :prove))
(in-package :qi-test-packages)

(plan 9)

(defvar git-dir (merge-pathnames "t/resources/git-project/" qi.paths:+qi-directory+)
  "Directory of resources for testing git functionality.")

(defvar hg-dir (merge-pathnames "t/resources/hg-project/" qi.paths:+qi-directory+)
  "Directory of resources for testing mercurial functionality.")

(let ((config
        (yaml:parse
         (merge-pathnames #p"qi.yaml" git-dir))))
  (ok "qi-git-test" (gethash "name" config))
  (let* ((p (car (gethash "packages" config)))
         (dep (qi::extract-dependency p)))
    (is (qi.packages::dependency-download-strategy dep) :git)
    (is (qi.packages::dependency-url dep)
        "https://github.com/hanshuebner/yason.git")))

(let ((config
        (yaml:parse
         (merge-pathnames #p"qi.yaml" hg-dir))))
  (ok "qi-hg-test" (gethash "name" config))
  (let* ((p (car (gethash "packages" config)))
         (dep (qi::extract-dependency p)))
    (is (qi.packages::dependency-download-strategy dep) :hg)
    (is (qi.packages::dependency-url dep)
        "https://bitbucket.org/tarballs_are_good/map-set")))

(let* ((test-yaml (yaml:parse (merge-pathnames "t/resources/tarball-project/qi.yaml" qi.paths:+qi-directory+)))
       (test-package-hash (first (member-if
                                  (lambda (x) (string= "cl-test-1" (gethash "name" x)))
                                  (gethash "packages" test-yaml))))
       (dep (qi::extract-dependency test-package-hash)))
  (is (qi.packages::dependency-url dep)
      "https://gitlab.com/welp/cl-test-1/repository/archive.tar.gz?ref=0.0.1")
  (is (qi.packages::dependency-download-strategy dep) :tarball)
  (is (qi.packages::dependency-version dep) "0.0.1"))

(finalize)
