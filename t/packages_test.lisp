(in-package :qi-test)

(plan 6)

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

(finalize)
