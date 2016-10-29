(in-package :qi-test)

(plan 2)

(defvar tar-dir (merge-pathnames "t/resources/tar/" qi.paths:+qi-directory+))

;; Tests that even if the tarball doesn't have the same name as what we expect, we still
;; sucessfully unpack it and load it.
(let ((dep (qi::make-dependency :name "anaphora"
                                :location (qi.packages::http "https://github.com/tokenrove/anaphora/tarball/master")
                                :src-path (merge-pathnames tar-dir "anaphora-master.tar.gz")
                                :sys-path (merge-pathnames tar-dir "anaphora-latest")
                                :version "latest")))
  (qi::bootstrap (qi.packages::dependency-name dep))
  (ensure-directories-exist (qi.paths:+dep-cache+))
  (rename-file (merge-pathnames "anaphora-master.tar.gz" tar-dir)
               (merge-pathnames "anaphora-latest.tar.gz" (qi.paths:+dep-cache+)))
  (let ((out (qi.packages::unpack-tar dep)))
    (ok (not (eql out (dependency-sys-path dep))) "Extracts tarball with different name.")
    (ok (probe-file (dependency-sys-path dep)) "Extracts tarball and exists")))

(finalize)
