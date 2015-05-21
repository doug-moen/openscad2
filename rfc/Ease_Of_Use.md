# Ease Of Use

## Useability Goals
 1. OpenSCAD is meant to be easy to use.
    It has proven to have a low barrier of entry for beginners,
    and we want to preserve this.

    OpenSCAD2 helps by making the language simpler and more consistent.

 2. There are pain points in the language, where some common tasks involved
    in geometric modelling require convoluted workarounds or complex code.

    OpenSCAD2 helps by making the language more expressive and powerful.

## A Non-Goal
OpenSCAD is a 3D modelling tool, not a programming language,
and it is intended to meet the needs of 3D designers who want to create models
(and who may not be experienced programmers). It is not intended to meet the
needs of computer programmers. Therefore, ease of use for 3D designers and non-programmers
is of higher importance than ease of use for programmers who are accustomed to
object oriented programming. Thus we need to make different design choices than
the ones made for general purpose programming languages.
Here are examples:
* We use [declarative/functional semantics](Declarative_Semantics.md),
  which are the best match to the domain of 3D modelling,
  instead of the imperative/state transition semantics
  used by most programming languages.
* There is no support for "programming in the large".
  These features are included in general purpose programming languages
  to support the writing of large programs, and to make it easier for a
  team of programmers to maintain a large code base.
  They work by adding structure and organization to the code base,
  and by forcing developers to follow rules so that the structure is
  preserved.
  There is a tradeoff involved: the developer has to learn more in
  order to be productive in the language. There is a larger barrier to
  entry for beginners, there is more work and reasoning involved in
  writing a program. Examples include static type checking,
  or 'classes' in object oriented languages like Java.

