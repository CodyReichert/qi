(in-package :cl-user)
(defpackage qi-test-integrations
  (:use :cl
        :qi
        :prove))
(in-package :qi-test-integrations)

(defun gsub (file regexp)
  "In FILE, do a global search/replace for REGEXP"
  (uiop:run-program (concatenate
                     'string
                     "sed '" regexp "' " (namestring file) " >> tmp.sed")
                    :wait t)
  ;; For some reason `sed -i` isn't working
  (uiop:run-program (concatenate
                     'string
                     "mv tmp.sed " (namestring file))
                    :wait t))

(defun reset-metadata ()
  "Unset the variables from `qi:bootstrap'.  We run this between
install tests to ensure a clean environment, simulating how they're
run from the command-line."
  (setf qi::+project-name+ nil)
  (setf qi.manifest::+manifest-packages+ nil))

(plan 6)

;;
;; Test that the VERSION key works for tarball dependencies
;;
(load "t/resources/tarball-project/test-tarball.asd")
(ok (qi:install :test-tarball) "test-tarball is installed")
(is (test-tarball:main) "0.0.1")
(reset-metadata)

(gsub "t/resources/tarball-project/qi.yaml" "s/0\.0\.1/0.0.2/g")
(ok (qi:install :test-tarball) "test-tarball is re-installed")
(is (test-tarball:main) "0.0.2" "qi should load the newer version of cl-test-1")
(reset-metadata)

;; Revert
(gsub "t/resources/tarball-project/qi.yaml" "s/0\.0\.2/0.0.1/g")

;;
;; Test that the TAG key works for git dependencies
;;
(load "t/resources/git-project/test-git.asd")
(ok (qi:install :test-git) "test-git is installed")
(is (test-git:main) "0.0.1")
(reset-metadata)

(gsub "t/resources/git-project/qi.yaml" "s/0\.0\.1/0.0.2/g")
(ok (qi:install :test-git) "test-git is re-installed")
(is (test-git:main) "0.0.2" "qi should load the newer version of cl-test-1")
(reset-metadata)

;; Revert
(gsub "t/resources/git-project/qi.yaml" "s/0\.0\.2/0.0.1/g")

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
