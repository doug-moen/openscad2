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
* A *childless module* has no children argument.
  Examples are `cube`, and a user defined module
  that doesn't reference `children()`.
  A typical module call is `cube(10);`.
* A *module with children* has a children argument.
  Examples are `rotate`, and a user defined module
  that references `children()`.
  A typical module call is `rotate(45) cube(10);`.

## Modules are Functions
Because everything is a first class value in OpenSCAD2, functions are
much more powerful: they can now do everything that a module does in OpenSCAD1.
In OpenSCAD2, the module definition syntax (using the keyword `module`)
now just defines a function, and builtin modules are now functions.

There are two cases.

1. A childless module is a function that maps an argument list to a shape.
For example, `cube` is a simple function that returns a shape.
`cube(10)` is a function call.

2. A module with children is a function that may be invoked using
a double function call, like this: `rotate(45)(cube(10))`.
The second argument list consists of a single argument,
which is the children. The children can be a single shape,
or it can be a list or object containing multiple shapes.

Here's how the second case works.
`rotate(45)` is an ordinary function call which returns
a second function. This second function is then called with
the children argument, and returns the geometry.
This works because functions are first class values.
A function call can return another function.

For example, this OpenSCAD1 module definition:
```
module rot(a)
   rotate([a,a,a]) children();
```
is equivalent to this OpenSCAD2 function definition:
```
rot = function(a)->(children)->
   rotate([a,a,a])(children);
```

## Fixing the Module Composability Problem
The new design for modules solves the module composition problem. In the old design,
* A module takes a group of shapes as an argument (accessed with children()).
* A module returns a group of shapes as a result.
* But there is no way to take the group of shapes returned by one module M1, and pass that as the children() list to another module M2.
* For example, you can't compose `intersection` with `for`.

In the new design, there is no problem. `intersection()({for (i=x) f(i);})` just works.

## Module Calls in Statements
* m(args) {...}
* m(args) generator
* m(args) m2(args);

## Module Calls in Expressions
