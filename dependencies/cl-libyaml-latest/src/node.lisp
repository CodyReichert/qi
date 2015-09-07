(in-package :cl-user)
(defpackage libyaml.node
  (:use :cl :cffi)
  (:import-from :libyaml.util
                :size-t)
  (:import-from :libyaml.basic
                :mark-t)
  (:import-from :libyaml.style
                :sequence-style-t
                :mapping-style-t)
  (:export ;; Data types
           :type-t
           :item-t
           :pair-t
           :scalar-t
           :item-stack-t
           :sequence-t
           :pair-stack-t
           :mapping-t
           :data-t
           :node-t
           ;; Accessors
           :key
           :value
           :length
           :style
           :start
           :end
           :top
           :items
           :style
           :sequence
           :scalar
           :mapping
           :type
           :tag
           :data
           :start-mark
           :end-mark)
  (:documentation "LibYAML nodes."))
(in-package :libyaml.node)

(defcenum type-t
  "Node types."
  :no-node
  :scalar-node
  :sequence-node
  :mapping-node)

(defctype item-t :int)

(defcstruct pair-t
  "An element of a mapping node."
  (key :int)
  (value :int))

(defcstruct scalar-t
  "The scalar parameters (for @c YAML_SCALAR_NODE)."
  (value :string)
  (length size-t)
  (style libyaml.style:scalar-style-t))

(defcstruct item-stack-t
  "The stack of sequence items."
  (start (:pointer item-t))
  (end (:pointer item-t))
  (top (:pointer item-t)))

(defcstruct sequence-t
  "The sequence parameters (for @c YAML_SEQUENCE_NODE)."
  (items (:struct item-stack-t))
  (style sequence-style-t))

(defcstruct pair-stack-t
  "The stack of mapping pairs (key, value)."
  (start (:pointer (:struct pair-t)))
  (end (:pointer (:struct pair-t)))
  (top (:pointer (:struct pair-t))))

(defcstruct mapping-t
  "The mapping parameters (for @c YAML_MAPPING_NODE)."
  (items (:struct pair-stack-t))
  (style mapping-style-t))

(defcunion data-t
  "The node data."
  (scalar (:struct scalar-t))
  (sequence (:struct sequence-t))
  (mapping (:struct mapping-t)))

(defcstruct node-t
  "The node structure."
  (type type-t)

  (tag :string)

  (data (:union data-t))

  (start-mark (:struct mark-t))
  (end-mark (:struct mark-t)))
