(in-package :gzip-stream)

(defun gzip-string (sequence)
  (with-open-stream (out (make-string-output-stream))
    (let ((outs (make-gzip-output-stream out)))
      (setf outs (make-flexi-stream outs))
      (write-sequence sequence outs)
      (finish-output outs))
    (get-output-stream-string out)))

(defun gzip-byte-array (sequence)
  (with-open-stream (out (make-in-memory-output-stream))
    (let ((outs (make-gzip-output-stream out)))
      (write-sequence sequence outs)
      (finish-output outs))
    (get-output-stream-sequence out)))


(defun gunzip-string (string)
  (with-output-to-string (outs)
    (with-input-from-string (y string)
      (let ((stream (make-flexi-stream (make-gzip-input-stream (make-flexi-stream y))))
            (buffer (make-array 1024 :element-type (array-element-type string))))
        (loop :for bytes-read = (read-sequence buffer stream)
              :until (zerop bytes-read) :do
              (write-sequence buffer outs :end bytes-read))))))

(defun gunzip-byte-array (sequence)
  (let ((out (make-in-memory-output-stream))
        (buffer (make-array 1024 :element-type (array-element-type sequence))))
    (with-open-stream (in (make-gzip-input-stream (make-in-memory-input-stream sequence)))
      (loop :for bytes-read = (read-sequence buffer in)
            :until (zerop bytes-read) :do
            (write-sequence buffer out :end bytes-read)))
    (get-output-stream-sequence out)))

(defmethod gunzip-sequence ((sequence string))
  (gunzip-string sequence))

(defmethod gunzip-sequence ((sequence vector))
  (gunzip-byte-array sequence))

(defmethod gzip-sequence ((sequence string))
  (gzip-string sequence))

(defmethod gzip-sequence ((sequence vector))
  (gzip-byte-array sequence))






