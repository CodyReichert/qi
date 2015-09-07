(in-package :cl-user)
(defpackage libyaml.document
  (:use :cl :cffi)
  (:import-from :libyaml.basic
                :version-directive-t
                :tag-directive-t
                :mark-t)
  (:import-from :libyaml.node
                :node-t)
  (:export ;; Datatypes
           :nodes-t
           :tag-directives-t
           :document-t
           ;; Accessors
           :start
           :end
           :top
           :nodes
           :version-directive
           :tag-directives
           :start-implicit
           :end-implicit
           :start-mark
           :end-mark
           :token
           ;; Functions
           :allocate-document
           :document-delete)
  (:documentation "Bindings to the document data structure."))
(in-package :libyaml.document)

(defcstruct nodes-t
  "The document nodes."
  (start (:pointer (:struct node-t)))
  (end (:pointer (:struct node-t)))
  (top (:pointer (:struct node-t))))

(defcstruct tag-directives-t
  "The list of tag directives."
  (start (:pointer (:struct tag-directive-t)))
  (end (:pointer (:struct tag-directive-t))))

(defcstruct document-t
  "The document structure."
  (nodes (:struct nodes-t))

  (version-directive (:pointer (:struct version-directive-t)))

  (tag-directives (:struct tag-directives-t))

  (start-implicit :int)
  (end-implicit :int)

  (start-mark (:struct mark-t))
  (end-mark (:struct mark-t)))

;;; Functions

(defun allocate-document ()
  (foreign-alloc '(:struct document-t)))

(defcfun ("yaml_document_delete" document-delete) :void
  "Delete a YAML document and all its nodes."
  (token (:pointer (:struct document-t))))
