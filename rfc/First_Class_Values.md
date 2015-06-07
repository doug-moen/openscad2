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

This can't happen until the variable, function and module namespaces
have been unified into a single namespace.
Fixed by [Definitions and Scoping](Definitions_And_Scoping.md).

The goal of First Class Values is to improve [composability](Composable_Building_Blocks.md).

## Violations of First Class Values in OpenSCAD1

* Functions and modules are not first class. Fixed by [Functions](Functions.md).
* Shapes are not first class.
* Groups are not first class. Fixed by [Objects](Objects.md).
* Number are not first class,
  because `1/0` prints as `inf`,
  and `0/0` prints as `nan`,
  but neither `inf` nor `nan` are valid expressions.
  Fixed by [Simple Values](Simple_Values.md).
