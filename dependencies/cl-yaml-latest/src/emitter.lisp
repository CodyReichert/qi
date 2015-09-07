(in-package :cl-user)
(defpackage yaml.emitter
  (:use :cl)
  (:export :encode
           :emit
           :emit-to-string)
  (:documentation "The YAML emitter."))
(in-package :yaml.emitter)

;;; Encoder functions

(defgeneric encode (value stream)
  (:documentation "Write the YAML corresponding to value to a stream."))

(defmethod encode ((true (eql 't)) stream)
  "Encode true."
  (write-string "true" stream))

(defmethod encode ((true (eql 'nil)) stream)
  "Encode false."
  (write-string "false" stream))

(defmethod encode ((integer integer) stream)
  "Encode an integer."
  (princ integer stream))

(defmethod encode ((float float) stream)
  "Encode a float."
  (princ float stream))

(defmethod encode ((string string) stream)
  "Encode a string."
  (write-string string stream))

(defmethod encode ((list list) stream)
  "Encode a list."
  (write-string "[" stream)
  (loop for sublist on list do
    (encode (first sublist) stream)
    (when (rest sublist)
      (write-string ", " stream)))
  (write-string "]" stream))

(defmethod encode ((vector vector) stream)
  "Encode a vector."
  (encode (loop for elem across vector collecting elem) stream))

(defmethod encode ((table hash-table) stream)
  "Encode a hash table."
  (write-string "{ " stream)
  (loop for sublist on (alexandria:hash-table-keys table) do
    (let ((key (first sublist)))
      (encode key stream)
      (write-string ": " stream)
      (encode (gethash key table) stream)
      (when (rest sublist)
        (write-string ", " stream))))
  (write-string " }" stream))

;;; Interface

(defun emit (value stream)
  "Emit a value to a stream."
  (encode value stream))

(defun emit-to-string (value)
  "Emit a value to string."
  (with-output-to-string (stream)
    (emit value stream)))
