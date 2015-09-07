# cl-libyaml

[![Build Status](https://travis-ci.org/eudoxia0/cl-libyaml.svg?branch=master)](https://travis-ci.org/eudoxia0/cl-libyaml)

A binding to the [libyaml][lyaml] library.

# Overview

This is a home-spun binding to the libyaml library. It's not meant as a full
library for YAML, just a bare binding with a couple of utility macros. For a
YAML parser and emitter using this, check out [cl-yaml][cl-yaml].

## Naming Convention

The naming convention is what you'd expect: Function and type names have dashes
instead of underscoes, the `yaml_` prefix on every symbol has been removed, and
instead you have package prefixes, but the trailing `_t` after every type
definition has been kept, to make it easier to tell symbols that denote types
from symbols that denote structure fields or functions.

For example, `yaml_event_t` is `libyaml.event:event-t`, and `yaml_parser_parse`
is `libyaml.parser:parser-parse`.

Enum values like `YAML_PARSE_FLOW_NODE_STATE` are keywords with the `YAML_`
prefix removed, as in `:parse-flow-node-state`.

# Usage

```lisp
(defpackage yaml-example
  (:use :cl)
  (:import-from :libyaml.macros
                :with-parser
                :with-event)
  (:import-from :libyaml.event
                :event-type))
(in-package :yaml-example)

(defun parse (string)
  (with-parser (parser string)
    (with-event (event)
      (loop do
        (when (libyaml.parser:parse parser event)
          (let ((type (event-type event)))
            (print type)
            (when (eql type :stream-end-event)
              (return-from parse nil))))))))
```

```lisp
YAML-EXAMPLE> (parse "[1,2,3]")

:STREAM-START-EVENT 
:DOCUMENT-START-EVENT 
:SEQUENCE-START-EVENT 
:SCALAR-EVENT 
:SCALAR-EVENT 
:SCALAR-EVENT 
:SEQUENCE-END-EVENT 
:DOCUMENT-END-EVENT 
:STREAM-END-EVENT 
NIL
```

[lyaml]: http://pyyaml.org/wiki/LibYAML
[cl-yaml]: https://github.com/eudoxia0/cl-yaml

# License

Copyright (c) 2015 Fernando Borretti

Licensed under the MIT License.
