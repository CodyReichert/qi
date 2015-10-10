;; Copyright (c) 2008 Sean Ross
;; 
;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use,
;; copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the
;; Software is furnished to do so, subject to the following
;; conditions:
;; 
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;; 
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
;; OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
;; OTHER DEALINGS IN THE SOFTWARE.
;;
(in-package :gzip-stream)
(declaim (optimize speed (safety 1) (debug 1)))

(declaim (type fixnum +buffer-size+))
(defconstant +buffer-size+ (* 32 1024))

(defun make-buffer ()
  (make-array +buffer-size+ :element-type 'octet))

;; gzip stream
(defclass gzip-output-stream (trivial-gray-stream-mixin fundamental-binary-output-stream)
  ((underlying-file :initarg :understream :accessor under-file)
   (input-buffer :initform (make-buffer))
   (input-pos :initform 0 :accessor input-pos :type fixnum)
   (deflate-stream :accessor deflate-stream)
   (size :initform 0 :type fixnum)
   (crc-high :initform #xFFFF)
   (crc-low :initform #xFFFF)
   (compress-buffer :initarg :buffer :accessor compress-buffer)))

(defmethod initialize-instance :after ((stream gzip-output-stream) &rest initargs &key)
  (declare (ignore initargs))
  (let* ((callback (lambda (buffer end)
                     (write-sequence buffer
                                     (under-file stream)
                                     :start 0
                                     :end end))))
    (setf (deflate-stream stream)  (make-instance 'salza2:gzip-compressor :callback callback))))

(defmethod stream-write-byte ((stream gzip-output-stream) byte)
  (declare (type integer byte))
  (salza2:compress-octet byte (deflate-stream stream)))

(defmethod stream-write-sequence ((stream gzip-output-stream) sequence start end &key)
  (loop :for idx :from start :below end :do
        (write-byte (aref sequence idx) stream)))

(defmethod stream-force-output ((stream gzip-output-stream))
  (values))

(defmethod stream-finish-output ((stream gzip-output-stream))
  (salza2:finish-compression (deflate-stream stream))
  (finish-output (under-file stream))
  (values))
  
(defmethod stream-clear-output ((stream gzip-output-stream))
  (error "Cannot clear output of gzip output streams."))


;; for some reason lispworks needs this otherwise the gzip function doesn't work
;; will investigate at some stage.
#+lispworks
(defmethod stream:stream-write-sequence ((stream gzip-output-stream) sequence start end)
  (salza2:compress-octet-vector sequence (deflate-stream stream) :start start :end end))

(defmethod close ((stream gzip-output-stream) &key abort)
  (when (open-stream-p (under-file stream))
    (unless abort
      (finish-output stream))
    (close (under-file stream) :abort abort)))

(defmethod stream-element-type ((stream gzip-output-stream))
  (stream-element-type (under-file stream)))

(defmethod stream-line-column  ((stream gzip-output-stream))
  (declare (ignore stream))
  nil)

(defmethod stream-write-char ((stream gzip-output-stream) char)
  (stream-write-char (under-file stream) char))

(defmethod stream-write-string ((stream gzip-output-stream) string &optional start end)
  (stream-write-string (under-file stream) string start end))




;;; Input
(defclass gzip-input-stream (trivial-gray-stream-mixin fundamental-binary-input-stream)
  ((underfile :accessor underfile-of :initarg :understream)
   (read-buffer :accessor read-buffer-of :initform
                (make-in-memory-input-stream ""))
   (data-buffer :accessor data-buffer-of :initform (make-buffer))
   (bit-reader :accessor bit-reader-of :initform nil)
   (last-end :initform 0)))

(defmethod initialize-instance :after ((obj gzip-input-stream) &key (skip-gzip-header-p t))
  (when skip-gzip-header-p
    (skip-gzip-header (underfile-of obj)))
  (setf (bit-reader-of obj)
        (new-bit-reader (underfile-of obj))))

(defmethod stream-element-type ((stream gzip-input-stream))
  '(unsigned-byte 8))

(defmethod close ((stream gzip-input-stream) &key abort)
  (close (underfile-of stream) :abort abort))

(defun fill-buffer (stream)
  (with-slots (read-buffer bit-reader data-buffer last-end) stream
    (setf read-buffer
          (make-in-memory-input-stream 
           (with-output-to-sequence (tmp)
             (setf last-end
                   (process-deflate-block bit-reader tmp
                                          data-buffer last-end)))))))

(defmethod stream-read-byte ((stream gzip-input-stream)) 
  (with-slots (read-buffer last-end) stream
    (let ((next-byte (read-byte read-buffer nil nil)))
      (if (null next-byte)
          (if last-end
              (progn (fill-buffer stream) (stream-read-byte stream))
              :eof)
          next-byte))))

(defmethod stream-read-sequence ((stream gzip-input-stream) sequence start end &key)
  (let ((start (or start 0))
        (end (or end (length sequence))))
    (loop :for index :from start :below end :do
          (let ((byte (stream-read-byte stream)))
            (if (eql byte :eof)
                (return-from stream-read-sequence  index)
                (setf (aref sequence index) byte)))
          :finally (return end))))

(defmethod stream-read-char ((stream gzip-input-stream))
  "Reads the next character from the given STREAM.
Returns :eof when end of file is reached."
  (let ((in-byte (read-byte stream nil nil)))
    (if in-byte
	(code-char in-byte)
	:eof)))

(defmethod stream-read-line ((stream gzip-input-stream))
  "Reads the next line from the given gzip-input stream. The #\Newline
is used as a line separator.

Returns (STR . EOF-P). EOF-P is T when of end of file is reached."
  (let ((res (make-string 80))
	(len 80)
	(index 0))
    (loop
       (let ((ch (read-char stream nil nil)))
	 (cond
	   ;; there is some character
	   (ch
	    (when (char= ch #\newline)
	      (return (values (subseq res 0 index) nil)))
	    (when (= index len)
	      (setq len (* len 2))
	      (let ((new (make-string len)))
		(replace new res)
		(setq res new)))
	    (setf (schar res index) ch)
	    (incf index))
	   ;; index is zero, and character is zero
	   ((zerop index)
	    (return (values nil t)))
	   ;; end of file
	   (t
	    (return (values (subseq res 0 index) t))))))))

                      
(defmethod stream-listen ((stream gzip-input-stream))
  (listen (underfile-of stream)))

(defmethod stream-clear-input ((stream gzip-input-stream))
  (clear-input (underfile-of stream)))


;; Util Functions
(defmacro with-open-gzip-file ((var path &rest open-args &key (direction :input) &allow-other-keys)
                               &body body)
  (let ((abort (gensym "abort")))
    `(let ((,var (make-instance (ecase ,direction
                                  (:input 'gzip-input-stream)
                                  (:output 'gzip-output-stream))
                                :understream (open ,path ,@open-args :element-type 'octet)))
           (,abort t))
       (unwind-protect 
           (multiple-value-prog1 (progn ,@body)
             (setf ,abort nil))
         (close ,var :abort ,abort)))))

(defun gzip (in-file out-file)
  "GZIPS the contents of in-file and writes the output to outfile."
  (with-open-file (in-stream in-file :element-type 'octet)
    (with-open-gzip-file (out-stream out-file :direction :output 
                                     :element-type 'octet :if-exists :supersede)
      (let ((buffer (make-array +buffer-size+ :element-type 'octet)))
        (loop for x = (read-sequence buffer in-stream)
              until (zerop x) do
              (write-sequence buffer out-stream :start 0 :end x)))
      (truename out-file))))

(defun gunzip (in-file out-file)
  "Extracts the contents of GZIP file IN-FILE and writes the output to OUT-FILE."
  (with-open-gzip-file (ins in-file)
    (with-open-file (outs out-file :direction :output 
                          :element-type 'octet :if-exists :supersede)
      (let ((buffer (make-array +buffer-size+ :element-type 'octet)))
        (loop for x = (read-sequence buffer ins)
              until (zerop x) do
              (write-sequence buffer outs :start 0 :end x)))))
  (truename out-file))

(defun make-gzip-input-stream (stream &rest args &key skip-gzip-header-p)
  (declare (ignore skip-gzip-header-p))
  (apply #'make-instance 'gzip-input-stream :understream stream args))

(defun make-gzip-output-stream (stream)
  (make-instance 'gzip-output-stream :understream stream))


; EOF
