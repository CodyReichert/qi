(in-package :cl-user)
(defpackage qi-test-integrations
  (:use :cl
        :qi
        :prove))
(in-package :qi-test-integrations)

(defun reset-metadata ()
  "Unset the variables from `qi:bootstrap'.  We run this between
install tests to ensure a clean environment, simulating how they're
run from the command-line."
  (setf qi::+project-name+ nil)
  (setf qi.manifest::+manifest-packages+ nil))

(plan 6)

(load "t/resources/project/test-project.asd")
(ok (qi:install :test-project) "test-project is installed")
(is (test-project:main) "0.0.1")
(reset-metadata)

;; For some reason `sed -i` isn't working
(uiop:run-program "sed 's/0\.0\.1/0.0.2/g' qi.yaml >> qwop.yaml"
                  :directory #P"t/resources/project/"
                  :wait t)
(uiop:run-program "mv qwop.yaml qi.yaml"
                  :directory #P"t/resources/project/"
                  :wait t)

(ok (qi:install :test-project) "test-project is re-installed")
(is (test-project:main) "0.0.2" "qi should load the newer version of cl-test-1")
(reset-metadata)

;; Revert
(uiop:run-program "sed 's/0\.0\.2/0.0.1/g' qi.yaml >> qwop.yaml"
                  :directory #P"t/resources/project/"
                  :wait t)
(uiop:run-program "mv qwop.yaml qi.yaml"
                  :directory #P"t/resources/project/"
                  :wait t)

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
    (with-open-file (source (merge-pathnames "t/resources/tar/anaphora-master.tar.gz" qi.paths:+qi-directory+)
                            :direction :input
                            :element-type '(unsigned-byte 8))
      (with-open-file (target tmpfile :direction :output :element-type '(unsigned-byte 8))
        (uiop:copy-stream-to-stream source target :element-type '(unsigned-byte 8)))))

  (ok (qi.packages::unpack-tar dep))
  (ok (probe-file (qi.packages:get-sys-path dep)) "Extracts tarball and exists"))

(finalize)
