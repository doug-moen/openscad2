# Ease Of Use

Two perspectives on ease of use:
 1. OpenSCAD is meant to be easy to use.
    It has proven to have a low barrier of entry for beginners,
    and we want to preserve this.

    OpenSCAD2 helps by making the language simpler and more consistent.

 2. There are pain points in the language, where some common tasks involved
    in geometric modelling require convoluted workarounds or complex code.

    OpenSCAD2 helps by making the language more expressive and powerful.

OpenSCAD is a powerful 3D modelling tool, not a programming language,
and it is designed to meet the needs of people who want to do 3D modelling
(and who may not be experienced programmers). It is not designed to meet the
needs of computer programmers. Therefore, ease of use for non-programmers
is of primary importance, and we need to make different design choices than
the ones made for general purpose programming languages.
Here are examples:
* [declarative/functional semantics](Declarative_Semantics.md)
* No support for "programming in the large".
  These features are included in general purpose programming languages
  to support the writing of large programs, and to make it easier for a
  team of programmers to make sense of a large code base.
  They work by adding structure and organization to the code base,
  and by forcing developers to follow rules so that the structure is
  preserved.
  There is a tradeoff involved: the developer has to learn more in
  order to be productive in the language. There is a larger barrier to
  entry for beginners, there is more work and reasoning involved in
  writing a program. Examples include static type checking,
  'classes' in object oriented languages like Java.

