# Module Calls
A module call (or module instantiation) returns a shape or a group of shapes.

In OpenSCAD2, shapes and groups become [first class values](First_Class_Values.md).
Module calls are now legal within expressions.
Modules themselves are first class values.
Designing the syntax and semantics of module call expressions
while retaining backward compatibility
is the biggest challenge in the design of OpenSCAD2.

## Two Kinds of Modules
OpenSCAD2 distinguishes between two kinds of modules.
* A *childless* module has no children argument.
  Examples are `cube`, and a user defined module
  that doesn't reference `children()`.
  A typical module call is `cube(10);`.
* A *module with children* has a children argument.
  Examples are `rotate`, and a user defined module
  that references `children()`.
  A typical module call is `rotate(45) cube(10);`.

## Modules are Functions
## Module Calls in Statements
## Module Calls in Expressions
