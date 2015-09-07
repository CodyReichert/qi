(in-package :cl-user)
(defpackage libyaml.version
  (:use :cl :cffi)
  (:export :get-version-string)
  (:documentation "Stuff for dealing with version information."))
(in-package :libyaml.version)

(defcfun ("yaml_get_version_string" get-version-string)
  :string
  "Get the library version as a string.")
