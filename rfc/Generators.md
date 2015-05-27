# Generators

In classic OpenSCAD, there is a `for` module used at the statement level,
and there is a similar-yet-different `for` keyword used in list comprehensions.
List comprehensions also support `if` and `let`.

OpenSCAD2 tries to unify the syntax and semantics of statements and expressions,
so that whatever you can express in the statement world, you can
also express in the expression world, and vice versa.
This makes the language more consistent and more powerful.

As a result, OpenSCAD has a single unified `for` operation that is available in
both [object literals](Objects.md#object-literals) and in list literals.
We call `for` a generator, because
a `for` expression generates a series of values that are added to either
a list or an object.

There are 4 generators (not including the [modifier characters](#modifier-characters)),
all of them hard coded in the grammar.
There are no user-defined generators.
You cannot define a function that takes a generator as an argument,
or returns a generator as a result.

## Using Generators in List Literals
In classic OpenSCAD, there are two syntaxes for list literals.
There is the original syntax, `[expr1,expr2,...]`,
and there are list comprehensions: `[list-comprehension]`.

In OpenSCAD2, we unify these two syntaxes, so that a list literal
contains a comma separated list of generators.
A generator is defined to be either an expression or a list comprehension.

The goal of this unification is to provide equivalent syntax for
both list literals and object literals. For example:
```
[a(), if (b) c(), for (d=list) f(d), e()]
{a(); if (b) c(); for (d=list) f(d); e();}
```
Here is a grammar for generators within a list literal:
```
generator ::= for (i=sequence_expr) generator
generator ::= if (boolean_expr) generator
generator ::= if (boolean_expr) generator else generator
generator ::= let (bindings) generator
generator ::= each sequence_expr
generator ::= expression
```
Note that `sequence_expr` is an expression that returns a [sequence value](Sequences.md),
which is normally a list or an object.

The `each` operator is new: it takes a sequence value as argument,
and adds each element to the list being constructed.
`each x` is equivalent to `for(i=x)i`.

This new list literal syntax is fully upward compatible with the old syntax.

## Using Generators in Object Literals
The same syntax is available in object literals, except modified to use statements.
The semantics are the same as for list literals, and this is a change.

Previously, the `for` statement was actually a module instantiation which returned a group,
which added a single element to the group under construction.
Now, `for` behaves the same way as a `for` in a list comprehension.
On each iteration, it adds zero or more elements to the object under construction.
These new semantics are more desirable: OEP2 describes an alternate route to getting these
new semantics. But there is a backward compatibility concern,
discussed in [Backward Compatibility](Backward_Compatibility.md).

Likewise, an `if` without an `else` has no effect if the condition is false.
Previously, it would add an empty group to the group under construction in this situation.

Within an object literal, `each` has additional semantics.
If the argument is an object,
`each` will transfer background shapes
from one object to another (see [Modifier Characters](#modifier-characters)).

## Modifier Characters
The `%`, `#`, `!` and `*` modifier characters are not operations on shapes.
Instead, they are generators whose use is restricted to objects,
i.e. you can't use them in lists.

The `*` operator is the disable modifier character.
`*x;` is equivalent to `if(false)x;`.

The `%` operator is the background modifier character.
This has weird semantics. It has almost the same semantics as `*`, the disable modifier,
(since the shape is not rendered), but the shape is displayed during preview for debugging purposes.
How to implement this in OpenSCAD2 is an open question. Here's my current idea:
* It is only implemented in objects, not in lists.
  So there is no unary `%` operator in the expression grammar.
* The backgrounded object is "semantically absent" from the object.
  `len(object)` does not include background shapes in the count,
  `object[i]` can't be used to access a background shape,
  and you also can't reach a background shape using `for(sh=object)...`.
  This is consistent with the fact that `difference` ignores background shapes
  when selecting `children[0]` from its children list.
* At the implementation level, an object has a list of rendered shapes,
  and a second, hidden list of background shapes.
* The `include` and `each` operations will transfer background shapes from
  one object to another, but during the evaluation phase, all other operations
  ignore background shapes.

The `!` operator (root) has even weirder semantics than `%`.
I'll worry about the OpenSCAD2 semantics and implementation later.

And `#` (debug).

By syntactically restricting the use of the modifier characters
to the 'generator' role within an object literal, I have simplified
the implementation and dodged some nasty problems.
* There's no extra overhead added to lists to support background shapes.
* In the expression syntax,
  I do not have to disambiguate between `scale(10) %cube(c)`
  and `f(x) % g(x)` (background vs modulus).
  Likewise for `scale(10) *cube(c)` vs `f(x) * g(x)`.
  I would have this ambiguity if modifier characters were shape operators.
