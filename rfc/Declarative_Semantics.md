# Declarative Semantics

OpenSCAD is intended to have declarative or functional semantics,
which are free of side effects.
So you can't increment a variable or mutate a data structure.
But "side effect free" is a negative definition: why is this a good thing?

When using the Declarative Programming style, your program
directly describes the desired end result, instead of being a procedure
that the machine should follow to build the desired result.
(It's the opposite of "imperative programming" or "procedural programming".)

In the declarative style of programming,
programs have these properties:
* *expressions denote objects in the problem domain* <br>
  Programs are made of expressions.
  These expressions denote mathematical objects (values) that are
  in the problem domain. For example, in OpenSCAD,
  `cube(1)` is an expression that denotes a cube,
  which is an object from the domain of 3D modelling.
  In a procedural language, cube(1) might denote, not a value,
  but a procedure
  that draws a cube onto a display surface, as a side effect of the
  procedure call.
* *compositional semantics* <br>
  The thing an expression denotes is a value,
  which depends only on the values of its subexpressions,
  and not on other properties of them.
  The meaning (denotation) of an expression
  is constructed from the denotations of its subexpressions,
  in a way that directly makes sense for the problem domain.
  For example, in OpenSCAD, the denotation of
  `union(){sphere(s);cylinder(c);}`
  is simply the union of two geometric objects.
  Once again, the denotations are not this transparent
  if function calls have side effects.
* *referential transparency* <br>
* order independent
* simple semantics
* compositional, composable
* easy to reason about
* equational reasoning
* useful mathematical properties for reasoning about programs

http://www.thocp.net/biographies/papers/backus_turingaward_lecture.pdf
