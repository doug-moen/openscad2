# First Class Values

In OpenSCAD2, every thing that can be referenced or manipulated by OpenSCAD code is a first class value.
This means:
* It can be passed as an argument to a function.
* It can be returned as a result from a function.
* It can be an element of a list.
* It can be written as a literal expression.
  This means we have anonymous function literals.
* It can be printed as a valid OpenSCAD expression using `echo`.
* It can be given a name using definition syntax: `name = value;`.

This can't happen until the value, function and module namespaces
have been unified into a single namespace.
Fixed by [Definitions and Scoping](Definitions_And_Scoping.md).

## Types
So far, OpenSCAD2 has the following value types:
* Undefined (one value, `undef`)
* Boolean (two values, `true` and `false`)
* Number
* String
* List or range
* Function
* Shape
* Object

We should have an operation for testing the type of a value.
Some possibilities:
* a set of type test functions, `isnumber(x)` etc, like Scheme.
* a typeof(x) operation that returns some sort of type value, like Javascript.
* a set of predefined type objects, plus an `isa` operator.
  Eg, `x isa Boolean`.
  This might be the best. There's a project to add type declarations,
  for the purpose of using a GUI to tweak model parameters, which would
  also use these type names.

Actually, this is wrong-ish. What you actually need to test for is whether a
given value has a desired behaviour, whether it obeys a particular contract.
See also "duck typing". This is more useful than what you get by partitioning values
into disjoint types based on how the value was constructed. The point is that
values and behaviours are overlapping, not disjoint. Eg, there should be a Sequence
type that tests if a value obeys the Sequence protocol.

## First Class Numbers
Currently, numbers are not first class values.
That's because `1/0` prints as `inf`,
and `0/0` prints as `nan`,
but neither `inf` nor `nan` are valid expressions.
