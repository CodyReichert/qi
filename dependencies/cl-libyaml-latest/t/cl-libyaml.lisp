(in-package :cl-user)
(defpackage cl-libyaml-test
  (:use :cl :fiveam))
(in-package :cl-libyaml-test)

(defparameter +yaml-string+
"- 1
- 2
- 3")

(def-suite tests
  :description "cl-libyaml tests.")
(in-suite tests)

(test version
  (let ((version))
    (finishes
     (setf version (libyaml.version:get-version-string)))
    (is (stringp version))))

(test (memory :depends-on version)
  (let ((parser)
        (input +yaml-string+))
    (cffi:with-foreign-string (c-input input)
      (finishes
        (setf parser (libyaml.parser:allocate-parser)))
      (is-true
       (cffi:pointerp parser))
      (finishes
        (libyaml.parser:initialize parser))
      (finishes
        (libyaml.parser:set-input-string parser c-input (length input)))
      (finishes
        (libyaml.parser:parser-delete parser))))
  (let ((event))
    (finishes
      (setf event (libyaml.event:allocate-event)))
    (is-true
     (cffi:pointerp event))
    (finishes
      (libyaml.event:event-delete event))))

(test (with-parser :depends-on memory)
  (is-true
   (libyaml.macros:with-parser (parser +yaml-string+)
     t)))

(test (with-event :depends-on memory)
  (is-true
   (libyaml.macros:with-event (event)
     t)))

(test (token-parsing :depends-on with-parser)
  (libyaml.macros:with-parser (parser +yaml-string+)
    (let ((token (libyaml.token:allocate-token)))
      (is-true
       (libyaml.parser:scan parser token))
      (is
       (equal (libyaml.token:token-type token)
              :stream-start-token))
      (is
       (equal (libyaml.parser:parser-error parser)
              :no-error))
      (is-false
       (libyaml.parser:error-message parser))
      (finishes
        (libyaml.token:token-delete token)))))

(test (event-parsing :depends-on with-parser)
  (libyaml.macros:with-parser (parser +yaml-string+)
    (let ((event (libyaml.event:allocate-event)))
      (is-true
       (libyaml.parser:parse parser event))
      (is
       (equal (libyaml.event:event-type event)
              :stream-start-event))
      (is
       (equal (libyaml.parser:parser-error parser)
              :no-error))
      (finishes
       (libyaml.event:event-delete event)))))

(run! 'tests)
