(in-package :arnesi)

;;;; * Logging slime integration

(defclass slime-repl-log-appender (appender)
  ()
  (:documentation "Logs to the slime repl when there's a valid swank::*emacs-connection* bound. Arguments are presented ready for inspection.

You may want to add this to your init.el to speed up cursor movement in the repl buffer with many presentations:

\(add-hook 'slime-repl-mode-hook
          (lambda ()
            (setf parse-sexp-lookup-properties nil)))
"))

(awhen (find-symbol (symbol-name '#:*inspector-dwim-lookup-hooks*) :swank)
  (pushnew 'arnesi-logger-inspector-lookup-hook (symbol-value it)))

(defun make-slime-repl-log-appender (&rest args &key (verbosity 2))
  (remf-keywords args :verbosity)
  (apply #'make-instance 'slime-repl-log-appender :verbosity verbosity args))

(export '(make-slime-repl-log-appender) :arnesi)

(defun swank::present-in-emacs (value-or-values &key (separated-by " "))
  "Present VALUE in the Emacs repl buffer of the current thread."
  (unless (consp value-or-values)
    (setf value-or-values (list value-or-values)))
  (flet ((present (value)
           (if (stringp value)
               (swank::send-to-emacs `(:write-string ,value))
               (let ((id (swank::save-presented-object value)))
                 (swank::send-to-emacs `(:write-string ,(prin1-to-string value) ,id))))))
    (map nil (let ((first-time-p t))
               (lambda (value)
                 (when (and (not first-time-p)
                            separated-by)
                   (present separated-by))
                 (present value)
                 (setf first-time-p nil)))
         value-or-values))
  (values))

(defmethod append-message ((category log-category) (appender slime-repl-log-appender)
                           message level)
  (when (swank::default-connection)
    (swank::with-connection ((swank::default-connection))
      (multiple-value-bind (second minute hour day month year)
          (decode-universal-time (get-universal-time))
        (declare (ignore second day month year))
        (swank::present-in-emacs (format nil
                                         "~2,'0D:~2,'0D ~A/~A: "
                                         hour minute
                                         (symbol-name (name category))
                                         (symbol-name level))))
      (if (consp message)
          (let ((format-control (when (stringp (first message))
                                  (first message)))
                (args (if (stringp (first message))
                          (rest message)
                          message)))
            (when format-control
              (setf message (apply #'format nil format-control args)))
            (swank::present-in-emacs message)
            (awhen (and format-control
                        (> (verbosity-of appender) 1)
                        (remove-if (lambda (el)
                                     (or (stringp el)
                                         (null el)))
                                   args))
              (swank::present-in-emacs " (")
              (swank::present-in-emacs it)
              (swank::present-in-emacs ")")))
          (swank::present-in-emacs message))
      (swank::present-in-emacs #.(string #\Newline)))))

(defun log-level-setter-inspector-action-for (prompt current-level setter)
  (lambda ()
    (with-simple-restart
        (abort "Abort setting log level")
      (let ((value-string (swank::eval-in-emacs
                           `(condition-case c
                             (let ((arnesi-log-levels '(,@(mapcar #'string-downcase (coerce *log-level-names* 'list)))))
                               (slime-read-object ,prompt :history (cons 'arnesi-log-levels ,(1+ current-level))
                                                  :initial-value ,(string-downcase (log-level-name-of current-level))))
                             (quit nil)))))
        (when (and value-string
                   (not (string= value-string "")))
          (funcall setter (eval (let ((*package* #.(find-package :arnesi)))
                                  (read-from-string value-string)))))))))

(defmethod swank:emacs-inspect ((category log-category))
  (let ((class (class-of category)))
    (values "A log-category."
            `("Class: " (:value ,class) (:newline)
              "Runtime level: " (:value ,(log.level category)
                                 ,(string (log-level-name-of (log.level category))))
              " "
              (:action "[set level]" ,(log-level-setter-inspector-action-for
                                       "Set runtime log level to (evaluated): "
                                       (log.level category)
                                       (lambda (value)
                                         (setf (log.level category) value))))
              (:newline)
              "Compile-time level: " (:value ,(log.compile-time-level category)
                                      ,(string (log-level-name-of (log.compile-time-level category))))
               " "
              (:action "[set level]" ,(log-level-setter-inspector-action-for
                                       "Set compile-time log level to (evaluated): "
                                       (log.compile-time-level category)
                                       (lambda (value)
                                         (setf (log.compile-time-level category) value))))
              (:newline)
              ,@(swank::all-slots-for-inspector category)))))
