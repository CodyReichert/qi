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
                                :version "latest"
                                :download-strategy :tarball
                                :url "https://github.com/tokenrove/anaphora/tarball/master"))
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

  (ok (qi.packages::unpack-tar dep))
  (ok (probe-file (qi.packages:get-sys-path dep)) "Extracts tarball and exists"))

(finalize)
