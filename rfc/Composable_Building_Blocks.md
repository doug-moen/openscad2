# Composable Building Blocks

The Holy Grail of programming language design
is to create a simple yet powerful language
with a small number of orthogonal building blocks
that can be composed together in many ways.

Design Strategies for Composability:
* [declarative semantics](Declarative_Semantics.md)
* orthogonality
  * unify features that are almost the same, but with unnecessary differences
  * split up features that do two things at once into separate features that can be composed
* eliminate the need to write "glue" code when composing elements, by using standard interfaces
* remove restrictions on how language elements can be composed
* eliminate syntactic overhead for common compositions

Composability Failure in OpenSCAD:
* Can't pass a function as an argument to a module for generalized extrusion.
  Fix: [First Class Values](First_Class_Values.md).
* Can't compose `for` with `intersection`.
  Fix: this is [the module composability problem](Functions.md#fixing-the-module-composability-problem).
* `concat` has a variable-length argument list, and can't be composed with an expression that generates a sequence of lists to be concatenated, eg a `for` loop, so users implement `flatten` instead. In Haskell, `concat` takes a single argument, which is a list of lists: this makes Haskell's `concat` highly composable, and eliminates the need for a separate `flatten` function.
* Can't compose `children()` with `for`, eg `for (shape=children()) ...`.
  Fix: [Generic Sequences](Sequences.md).
* Ranges can be composed with `for`, but can't be interchanged with lists of number
  in other contexts. Fix: [Generic Sequences](Sequences.md).

## Bibliography
* http://stackoverflow.com/questions/2887013/what-does-composability-mean-in-context-of-functional-programming
