(in-package :cl-user)
(defpackage libyaml.parser
  (:use :cl :cffi)
  (:import-from :libyaml.util
                :size-t)
  (:import-from :libyaml.basic
                :mark-t
                :error-type-t
                :encoding-t
                :tag-directive-t
                :mark-line
                :mark-column)
  (:import-from :libyaml.document
                :document-t)
  (:import-from :libyaml.event
                :event-t)
  (:import-from :libyaml.token
                :token-t)
  (:export ;; Datatypes
           :read-handler-t
           :simple-key-t
           :state-t
           :alias-data-t
           :aliases-t
           :parser-input-string-t
           :parser-input-t
           :parser-buffer-t
           :parser-raw-buffer-t
           :token-queue-t
           :indent-stack-t
           :simple-key-stack-t
           :parser-states-stack-t
           :parser-marks-stack-t
           :tag-directives-t
           :parser-t
           ;; Accessors
           :possible
           :required
           :token-number
           :mark
           :anchor
           :index
           :start
           :end
           :top
           :current
           :string
           :file
           :pointer
           :last
           :head
           :tail
           :error
           :problem
           :problem-offset
           :problem-value
           :problem-mark
           :context
           :context-mark
           :read-handler
           :read-handler-data
           :input
           :eof
           :buffer
           :unread
           :raw-buffer
           :encoding
           :offset
           :stream-start-produced
           :stream-end-produced
           :flow-level
           :tokens
           :tokens-parsed
           :tokens-available
           :indents
           :indent
           :simple-key-allowed
           :simple-keys
           :states
           :state
           :marks
           :tag-directives
           :aliases
           :document
           ;; Functions
           :allocate-parser
           :initialize
           :parser-delete
           :set-input-string
           :set-input-file
           :set-input
           :set-encoding
           :scan
           :parse
           :parser-load
           :parser-error
           :error-message
           :error-line
           :error-column)
  (:documentation "The libyaml parser."))
(in-package :libyaml.parser)

(defctype read-handler-t :pointer)

(defcstruct simple-key-t
  "This structure holds information about a potential simple key."
  (possible :boolean)
  (required :boolean)
  (token-number size-t)
  (mark (:struct mark-t)))

(defcenum state-t
  "The states of the parser."
  :parse-stream-start-state
  :parse-implicit-document-start-state
  :parse-document-start-state
  :parse-document-content-state
  :parse-document-end-state
  :parse-block-node-state
  :parse-block-node-or-indentless-sequence-state
  :parse-flow-node-state
  :parse-block-sequence-first-entry-state
  :parse-block-sequence-entry-state
  :parse-indentless-sequence-entry-state
  :parse-block-mapping-first-key-state
  :parse-block-mapping-key-state
  :parse-block-mapping-value-state
  :parse-flow-sequence-first-entry-state
  :parse-flow-sequence-entry-state
  :parse-flow-sequence-entry-mapping-key-state
  :parse-flow-sequence-entry-mapping-value-state
  :parse-flow-sequence-entry-mapping-end-state
  :parse-flow-mapping-first-key-state
  :parse-flow-mapping-key-state
  :parse-flow-mapping-value-state
  :parse-flow-mapping-empty-value-state
  :parse-end-state)

(defcstruct alias-data-t
  "This structure holds aliases data."
  (anchor :string)
  (index :int)
  (mark (:struct mark-t)))

(defcstruct aliases-t
  "The alias data."
  (start (:pointer (:struct alias-data-t)))
  (end (:pointer (:struct alias-data-t)))
  (top (:pointer (:struct alias-data-t))))

(defcstruct parser-input-string-t
  "String input data."
  (start :pointer)
  (end :pointer)
  (current :pointer))

(defcunion parser-input-t
  "Standard (string or file) input data."
  (string (:struct parser-input-string-t))
  (file :pointer))

(defcstruct parser-buffer-t
  "The working buffer."
  (start :pointer)
  (end :pointer)
  (pointer :pointer)
  (last :pointer))

(defcstruct parser-raw-buffer-t
  "The raw buffer."
  (start :pointer)
  (end :pointer)
  (pointer :pointer)
  (last :pointer))

(defcstruct token-queue-t
  "The tokens queue."
  (start (:pointer (:struct token-t)))
  (end (:pointer (:struct token-t)))
  (head (:pointer (:struct token-t)))
  (tail (:pointer (:struct token-t))))

(defcstruct indent-stack-t
  "The indentation levels stack."
  (start (:pointer :int))
  (end (:pointer :int))
  (top (:pointer :int)))

(defcstruct simple-key-stack-t
  "The stack of simple keys."
  (start (:pointer (:struct simple-key-t)))
  (end (:pointer (:struct simple-key-t)))
  (top (:pointer (:struct simple-key-t))))

(defcstruct parser-states-stack-t
  "The parser states stack."
  (start (:pointer state-t))
  (end (:pointer state-t))
  (top (:pointer state-t)))

(defcstruct parser-marks-stack-t
  "The stack of marks."
  (start (:pointer (:struct mark-t)))
  (end (:pointer (:struct mark-t)))
  (top (:pointer (:struct mark-t))))

(defcstruct tag-directives-t
  "The list of TAG directives."
  (start (:pointer (:struct tag-directive-t)))
  (end (:pointer (:struct tag-directive-t)))
  (top (:pointer (:struct tag-directive-t))))

(defcstruct parser-t
  "The parser structure."
  ;; Error handling
  (error error-type-t)
  (problem :string)
  (problem-offset size-t)
  (problem-value :int)
  (problem-mark (:struct mark-t))
  (context :string)
  (context-mark (:struct mark-t))
  ;; Reader
  (read-handler (:pointer read-handler-t))
  (read-handler-data :pointer)
  (input (:union parser-input-t))
  (eof :boolean)
  (buffer (:struct parser-buffer-t))
  (unread size-t)
  (raw-buffer (:struct parser-raw-buffer-t))
  (encoding encoding-t)
  (offset size-t)
  (mark (:struct mark-t))
  ;; Scanner
  (stream-start-produced :boolean)
  (stream-end-produced :boolean)
  (flow-level :int)
  (tokens (:struct token-queue-t))
  (tokens-parsed size-t)
  (tokens-available :int)
  (indents (:struct indent-stack-t))
  (indent :int)
  (simple-key-allowed :boolean)
  (simple-keys (:struct simple-key-stack-t))
  ;; Parser
  (states (:struct parser-states-stack-t))
  (state state-t)
  (marks (:struct parser-marks-stack-t))
  (tag-directives (:struct tag-directives-t))
  ;; Dumper
  (aliases (:struct aliases-t))
  (document (:pointer (:struct document-t))))

;; Parser functions

(defun allocate-parser ()
  (foreign-alloc '(:struct parser-t)))

(defcfun ("yaml_parser_initialize" initialize) :int
  "Initialize a parser."
  (parser (:pointer (:struct parser-t))))

(defcfun ("yaml_parser_delete" parser-delete) :void
  "Destroy a parser."
  (parser (:pointer (:struct parser-t))))

(defcfun ("yaml_parser_set_input_string" set-input-string)
    :void
  "Set a string input."
  (parser (:pointer (:struct parser-t)))
  (input :pointer)
  (size size-t))

(defcfun ("yaml_parser_set_input_file" set-input-file)
    :void
  "Set a file input."
  (parser (:pointer (:struct parser-t)))
  (file :pointer))

(defcfun ("yaml_parser_set_input" set-input)
    :void
  "Set a generic input handler."
  (parser (:pointer (:struct parser-t)))
  (handler read-handler-t)
  (data :pointer))

(defcfun ("yaml_parser_set_encoding" set-encoding)
    :void
  "Set the source encoding."
  (parser (:pointer (:struct parser-t)))
  (encoding encoding-t))

(defcfun ("yaml_parser_scan" scan)
    :boolean
  "Scan the input stream and produce the next token."
  (parser (:pointer (:struct parser-t)))
  (token (:pointer (:struct token-t))))

(defcfun ("yaml_parser_parse" parse)
    :boolean
  "Parse the input stream and produce the next parsing event."
  (parser (:pointer (:struct parser-t)))
  (event (:pointer (:struct event-t))))

(defcfun ("yaml_parser_load" parser-load)
    :boolean
  "Parse the input stream and produce the next YAML document."
  (parser (:pointer (:struct parser-t)))
  (document (:pointer (:struct document-t))))

(defun parser-error (parser)
  "Return the current error type."
  (foreign-slot-value parser '(:struct parser-t) 'error))

(defun error-message (parser)
  "Return the current error message."
  (foreign-slot-value parser '(:struct parser-t) 'problem))

(defun error-line (parser)
  "Return the line where the current error happened."
  (mark-line
   (foreign-slot-pointer parser '(:struct parser-t) 'mark)))

(defun error-column (parser)
  "Return the column where the error happened."
  (mark-column
   (foreign-slot-pointer parser '(:struct parser-t) 'mark)))
