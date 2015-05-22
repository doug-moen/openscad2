# Composable Building Blocks

The Holy Grail of programming language design
is to create a simple yet powerful language
with a small number of fundamental building blocks
that can be composed together in many ways.

Design Strategies for Composability:
* orthogonality
  * unify features that are almost the same, but with unnecessary differences
  * split up features that do two things at once into separate features that can be composed
* eliminate the need to write "glue" code through standard interfaces
* remove restrictions on how language elements can be composed

How OpenSCAD2 increases composability:
