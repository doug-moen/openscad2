# Composable Building Blocks

The Holy Grail of programming language design
is to create a simple yet powerful language
with a small number of orthogonal building blocks
that can be composed together in many ways.

Design Strategies for Composability:
* declarative semantics
* orthogonality
  * unify features that are almost the same, but with unnecessary differences
  * split up features that do two things at once into separate features that can be composed
* eliminate the need to write "glue" code when composing elements, by using standard interfaces
* remove restrictions on how language elements can be composed
* eliminate syntactic overhead for common compositions

Composability Failure in OpenSCAD:
* Can't pass a function as an argument to a module for generalized extrusion.
  Fix: [First Class Values](First_Class_Values.md).
* can't compose `for` with `intersection`
* `concat` has a variable-length argument list, can't be composed with an expression that generates a sequence of lists to be concatenated, eg a `for` loop, so users implement `flatten` instead. In Haskell, `concat` takes a single argument, which is a list of lists: this makes Haskell's `concat` highly composable, and eliminates the need for a separate `flatten` function.
* Can't compose `children()` with `for`, eg `for (shape=children()) ...`.
  Fix: [Generalized Lists](Generalized_Lists.md).

## Bibliography
* http://stackoverflow.com/questions/2887013/what-does-composability-mean-in-context-of-functional-programming
