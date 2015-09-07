(in-package :cl-user)
(defpackage cl-yaml
  (:use :cl)
  (:nicknames :yaml)
  (:export :parse
           :emit
           :emit-to-string)
  (:documentation "The main YAML interface."))
(in-package :yaml)

(defgeneric parse (input &key multi-document-p)
  (:documentation "Parse a YAML string or a pathname to a YAML file into Lisp
 data."))

(defmethod parse ((input string) &key multi-document-p)
  (let ((parsed (yaml.parser:parse-string input)))
    (if multi-document-p
        parsed
        (second parsed))))

(defmethod parse ((input pathname) &key multi-document-p)
  (parse (uiop:read-file-string input)
         :multi-document-p multi-document-p))

(defun emit (value stream)
  (yaml.emitter:emit value stream))

(defun emit-to-string (value)
  (yaml.emitter:emit-to-string value))
