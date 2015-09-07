# cl-yaml

[![Build Status](https://travis-ci.org/eudoxia0/cl-yaml.svg?branch=master)](https://travis-ci.org/eudoxia0/cl-yaml)
[![Coverage Status](https://coveralls.io/repos/eudoxia0/cl-yaml/badge.svg?branch=master)](https://coveralls.io/r/eudoxia0/cl-yaml?branch=master)

A YAML parser and emitter.

# Usage

The `yaml` package exports three functions:

* `(parse string-or-pathname)`: Parses a string or a pathname into Lisp values.
* `(emit value stream)`: Emit a Lisp value into a stream.
* `(emit-to-string value)`: Emit a Lisp value into a string.

## Parsing

```lisp
CL-USER> (yaml:parse "[1, 2, 3]")
(1 2 3)

CL-USER> (yaml:parse "{ a: 1, b: 2 }")
{"a" => 1, "b" => 2}

CL-USER> (yaml:parse "- Mercury
- Venus
- Earth
- Mars")
("Mercury" "Venus" "Earth" "Mars")

CL-USER> (yaml:parse "foo
---
bar" :multi-document-p t)
(:DOCUMENTS "foo" "bar")
```

## Emitting

```lisp
CL-USER> (yaml:emit-to-string (list 1 2 3))
"[1, 2, 3]"

CL-USER> (yaml:emit-to-string
           (alexandria:alist-hash-table '(("a" . 1)
                                          ("b" . 2))))
"{ b: 2, a: 1 }"

CL-USER> (yaml:emit (list t 123 3.14) *standard-output*)
[true, 123, 3.14]
```

# Documentation

## Type Mapping

cl-yaml uses YAML's [Core Schema][core-schema] to map YAML values to Lisp types
an vice versa. A table showing the correspondence of values and types is shown
below:

| YAML type  | Lisp type         |
| ---------- | ----------------- |
| Null       | `nil`             |
| Boolean    | `t` and `nil`     |
| Integer    | Integer           |
| Float      | Double float      |
| String     | String            |
| List       | List              |
| Map        | Hash table        |
| Document   | `(:document ...)` |

## IEEE Floating Point Support

Common Lisp doesn't natively support the IEEE special floating point values: NaN
(Not a number), positive infinity and negative infinity are unrepresentable in
portable Common Lisp. Since YAML allows documents to include these values, we
have to figure out what to do with them. cl-yaml supports multiple float
strategies.

The default strategy is `:keyword`, which uses keywords to represent these
values. The strategy can be customized by setting the value of
`yaml.float:*float-strategy*` to one of the following keywords:

1. `:error`: The simplest approach, simply signal the condition
   `yaml.error:unsupported-float-value` whenever a NaN or infinity value is
   encountered.

2. `:keyword`: Use keywords to represent the different values, i.e.: `:NaN` for
   NaN, `:+Inf` for positive infinity and `:-Inf` for negative infinity.

3. `:best-effort`: Use implementation-specific values whenever possible, fall
   back on `:keyword` in unsupported implementations. On SBCL and Allegro Common
   Lisp, NaN and infinity can be represented.

[core-schema]: http://www.yaml.org/spec/1.2/spec.html#id2804923

# License

Copyright (c) 2013-2015 Fernando Borretti

Licensed under the MIT License.
