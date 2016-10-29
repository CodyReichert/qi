(in-package :cl-user)
(defpackage qi-test-integrations
  (:use :cl
        :qi
        :prove))
(in-package :qi-test-integrations)

(plan 2)

(defvar tar-dir (merge-pathnames "t/resources/tar/" qi.paths:+qi-directory+))

;; Tests that even if the tarball doesn't have the same name as what we expect, we still
;; sucessfully unpack it and load it.
(let ((dep (qi::make-dependency :name "anaphora"
                                :location (qi.packages::http "https://github.com/tokenrove/anaphora/tarball/master")
                                :src-path (merge-pathnames tar-dir "anaphora-master.tar.gz")
                                :sys-path (merge-pathnames tar-dir "anaphora-latest")
                                :version "latest"))
      (tmpfile (merge-pathnames "anaphora-latest.tar.gz" (qi.paths:+dep-cache+))))
  (qi::bootstrap (qi.packages::dependency-name dep))
  (ensure-directories-exist (qi.paths:+dep-cache+))

  ;; Copy the fixture to TMPDIR
  (unless (probe-file tmpfile)
    (with-open-file (source (merge-pathnames "anaphora-master.tar.gz" tar-dir)
                            :direction :input
                            :element-type '(unsigned-byte 8))
      (with-open-file (target tmpfile :direction :output :element-type '(unsigned-byte 8))
        (uiop:copy-stream-to-stream source target :element-type '(unsigned-byte 8)))))

  (let ((out (qi.packages::unpack-tar dep)))
    (ok (not (eql out (qi.packages:dependency-sys-path dep))) "Extracts tarball with different name.")
    (ok (probe-file (qi.packages:dependency-sys-path dep)) "Extracts tarball and exists")))

(finalize)
