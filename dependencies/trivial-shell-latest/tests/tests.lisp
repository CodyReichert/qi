#|

these tests are both very unixy

|#

(in-package #:trivial-shell-test)

(deftestsuite trivial-shell-test ()
  ())

(addtest (trivial-shell-test)
  test-1
  (ensure-same (parse-integer (shell-command "expr 1 + 1") :junk-allowed t) 2))

(addtest (trivial-shell-test)
  test-input
  (ensure-same (parse-integer 
		(shell-command "wc -c" :input "hello")
		:junk-allowed t) 
	       5 :test '=))


(deftestsuite spaces-in-command (trivial-shell-test)
  ()
  (:documentation "https://github.com/gwkkwg/trivial-shell/issues/1"))

(addtest (spaces-in-command)
  test-1
  (ensure-same (parse-integer (shell-command "tests/a\\ b\\ c.sh 56") :junk-allowed t) 56))
