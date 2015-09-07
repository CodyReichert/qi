(in-package #:trivial-shell)

;; whatever...
(defmacro with-gensyms (syms &body body)
  `(let ,(mapcar #'(lambda (s)
                     `(,s (gensym)))
                 syms)
     ,@body))

(defmacro with-stream-from-specifier ((stream stream-specifier direction
					      &rest args)
				      &body body)
  (with-gensyms (s close? result)
    `(let ((,close? t)
           ,s
           ,result)
      (unwind-protect
           (setf ,result
                 (multiple-value-list
                     (let (,stream)
                       (setf (values ,s ,close?)
                             (make-stream-from-specifier
                              ,stream-specifier ,direction ,@args))
                       (setf ,stream ,s)
                       ,@body)))
        (when (and ,close? ,s)
          (let ((it (close-stream-specifier ,s)))
            (when it
              (setf (first ,result) it)))))
       (values-list ,result))))

(defmacro with-input ((var source &rest args) &body body)
  "Create an input stream from source and bind it to var within the body of the with-input form. The stream will be closed if necessary on exit." 
  `(with-stream-from-specifier (,var ,source :input ,@args)
     ,@body))

(defmacro with-output ((var destination &rest args) &body body)
  "Create an output stream from source and bind it to var within the body of the with-output form. The stream will be closed if necessary on exit." 
  `(with-stream-from-specifier (,var ,destination :output ,@args)
     ,@body))

(defgeneric make-stream-from-specifier (specifier direction &rest args)
  (:documentation "Create and return a stream from specifier, direction and any other argsuments"))

(defgeneric close-stream-specifier (steam)
  (:documentation "Close a stream and handle other bookkeeping as appropriate."))

(defmethod make-stream-from-specifier ((stream-specifier stream) 
				       (direction symbol) &rest args)
  (declare (ignore args))
  (values stream-specifier nil))

(defmethod make-stream-from-specifier ((stream-specifier (eql t)) 
				       (direction symbol) &rest args)
  (declare (ignore args))
  (values *standard-output* nil))

(defmethod make-stream-from-specifier ((stream-specifier (eql nil)) 
				       (direction symbol) &rest args)
  (declare (ignore args))
  (values (make-string-output-stream) t))

(defmethod make-stream-from-specifier ((stream-specifier (eql :none)) 
				       (direction symbol) &rest args)
  (declare (ignore args))
  (values nil nil))

(defmethod make-stream-from-specifier ((stream-specifier pathname) 
				       (direction symbol) &rest args)
  (values (apply #'open stream-specifier :direction direction args)
          t))

(defmethod make-stream-from-specifier ((stream-specifier string) 
				       (direction symbol) &rest args)
  (let ((start (getf args :start 0))
	(end (getf args :end)))
    (values (make-string-input-stream stream-specifier start end) nil)))

(defmethod make-stream-from-specifier ((stream-specifier string) 
				       (direction (eql :output)) &rest args)
  (let ((if-does-not-exist (getf args :if-does-not-exist :create)))
    (remf args :if-does-not-exist)
    (values (apply #'open stream-specifier 
		   :direction direction :if-does-not-exist if-does-not-exist args)
	    t)))

(defmethod close-stream-specifier (s)
  (close s)
  (values nil))

(defmethod close-stream-specifier ((s string-stream))
  (prog1 
    (values (get-output-stream-string s)) 
    (close s)))
