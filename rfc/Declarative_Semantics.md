# Declarative Semantics

OpenSCAD is intended to have declarative (aka functional) semantics,
which are free of side effects.
So you can't increment a variable or mutate a data structure.
But "side effect free" is a negative definition: why is this a good thing?

When using the declarative programming style, your program
directly describes the desired end result, instead of being a procedure
that the machine should follow to build the desired result.
(It's the opposite of "imperative programming" or "procedural programming".)
As a result, programs are easier to write, understand and reason about.

Declarative programs and languages have these properties:
* **a simple denotation semantics** <br>
  *Denotational semantics* is a technique for describing the exact mathematical meaning
  of a computer program. It has been used in formally describing the semantics of
  programming languages, and for proving programs correct. It works by assigning a
  "denotation" or meaning to every part of a program. The denotation of an expression
  is constructed from the denotation of its subexpressions.

  For a simple declarative language with no side effects, the denotation of an
  expression is quite simple: it is the value computed by that expression.
  For a language with side effects, the denotation of an expression is more complicated,
  because it has to fully describe the side effects as well as the computed value.
  
* **expressions denote objects in the problem domain** <br>
  For example, in OpenSCAD,
  `cube(1)` is an expression that denotes a cube,
  which is an object from the domain of 3D modelling.
  In a procedural language, cube(1) might denote, not a value,
  but a procedure
  that draws a cube onto a display surface, as a side effect of the
  procedure call.

* **compositional semantics** <br>
  In the functional programming community,
  this means that the value of an expression
  depends only on the values of its subexpressions.
  In other words, it is easy to understand what an expression means.
  It's true because expressions don't have side effects.
  [This phrase has a different meaning in the field of semantics.]

* **referential transparency** <br>
  In the functional programming community,
  this means that you can substitute an expression
  with another expression that computes the same value,
  and you don't change the meaning of the program.
  This makes programs easier to modify.
  It's also important to the OpenSCAD implementors:
  this property makes programs easier to optimize.
  It's true because expressions don't have side effects.
  [This phrase has a different meaning in the field of semantics.]

* **order independence** <br>
  The order in which the implementation evaluates the arguments in a function call
  doesn't matter, so you don't have know or care about this implementation detail
  to understand a program.
  This means that commutative operators really are commutative:
  The expressions `a+b` and `b+a` are exactly equivalent
  (which they wouldn't be if `a` and `b` had side effects:
  order of evaluation would be important).

* **equational reasoning** <br>
  In grade school algebra, you are taught to solve mathematical equations by
  substituting like for like, and transforming the equation by apply rules like
  the commutative and associative properties of addition and multiplication.
  That's equational reasoning, and it can also be applied to a program written
  in a declarative language. When you see `name = expr;` in an OpenSCAD2 program,
  it means that wherever you see `name` in the program, you can substitute it
  with `expr`, and vice versa. And you can transform programs by applying
  algebraic rules like the commutative law (see *order independence* above).

* **composable** <br>
  Your ability to create a system of [composable building blocks](Composable_Building_Blocks.md)
  depends on the extent to which the building blocks have declarative semantics.
  For a counterexample, imagine that `cube(10)` is a procedure with no return value,
  but whose side effect is to
  draw a cube onto a display. Then you wouldn't be able to compose `cube` with `intersect`,
  `difference`, etc.

## Bibliography
* https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf
* http://www.thocp.net/biographies/papers/backus_turingaward_lecture.pdf
