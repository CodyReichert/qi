(in-package :cl-user)
(defpackage libyaml.style
  (:use :cl :cffi)
  (:import-from :libyaml.util
                :size-t)
  (:export :scalar-style-t
           :sequence-style-t
           :mapping-style-t)
  (:documentation "Style information for various libyaml structures."))
(in-package :libyaml.style)

(defcenum scalar-style-t
  "Scalar styles."
  :any-scalar-style
  :plain-scalar-style
  :single-quoted-scalar-style
  :double-quoted-scalar-style
  :literal-scalar-style
  :folded-scalar-style)

(defcenum sequence-style-t
  "Sequence styles."
  :any-sequence-style
  :block-sequence-style
  :flow-sequence-style)

(defcenum mapping-style-t
  "Mapping styles."
  :any-mapping-style
  :block-mapping-style
  :flow-mapping-style)
