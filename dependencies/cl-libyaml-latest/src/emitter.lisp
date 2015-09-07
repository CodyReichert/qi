(in-package :cl-user)
(defpackage libyaml.emitter
  (:use :cl :cffi)
  (:export :write-handler-t
           :state-t)
  (:documentation "The libyaml emitter. This package is incomplete."))
(in-package :libyaml.emitter)

(defctype write-handler-t :pointer)

(defcenum state-t
  "The emitter states."
  :emit-stream-start-state
  :emit-first-document-start-state
  :emit-document-start-state
  :emit-document-content-state
  :emit-document-end-state
  :emit-flow-sequence-first-item-state
  :emit-flow-sequence-item-state
  :emit-flow-mapping-first-key-state
  :emit-flow-mapping-key-state
  :emit-flow-mapping-simple-value-state
  :emit-flow-mapping-value-state
  :emit-block-sequence-first-item-state
  :emit-block-sequence-item-state
  :emit-block-mapping-first-key-state
  :emit-block-mapping-key-state
  :emit-block-mapping-simple-value-state
  :emit-block-mapping-value-state
  :emit-end-state)
