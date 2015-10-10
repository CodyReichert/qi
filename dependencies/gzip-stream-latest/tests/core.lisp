(eval-when (:compile-toplevel :load-toplevel :execute)
  (mb:load :tryil))

(defpackage gzip-stream-tests (:use :cl :gzip-stream :tryil))
(in-package :gzip-stream-tests)

(define-test gzipping-string ()
  "Ensure that gzipping and gunzipping string works correctly."
  (let ((string (map 'string 'code-char (loop repeat 1000 :collect (+ 70 (random 20))))))
    (assert-equal string (gunzip-sequence (gzip-sequence string)))))

(define-test gzipping-byte-array ()
  "Ensure that gzipping and gunzipping string works correctly."
  (let ((sequence (map 'vector 'identity (loop repeat 1000 :collect (+ 70 (random 20))))))
    (assert-true (every '= sequence sequence (gunzip-sequence (gzip-sequence sequence))))))


(princ (run-tests))

#|
  
(let ((string (map 'string 'code-char (gzip-byte-array (map 'vector 'char-code (slurp "/tmp/doc.xml"))))))
  (string= string (gzip-string (slurp "/tmp/doc.xml"))))

(let ((vec (gunzip-byte-array (gzip-byte-array (map 'vector 'char-code (slurp "/tmp/doc.xml"))))))
  (equalp vec (map 'vector 'char-code (slurp "/tmp/doc.xml"))))
      
(let ((string (gunzip-string (gzip-string (slurp "/tmp/doc.xml")))))
  (string= string (slurp "/tmp/doc.xml")))

|#