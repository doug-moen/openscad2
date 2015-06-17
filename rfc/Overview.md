# Overview of OpenSCAD2

OpenSCAD2 is a backwards compatible redesign of OpenSCAD.
The original goal was first class function values to support generalized extrusion.
However, Marius challenged me to make everything a first class value,
and to make the language as consistent and uniform as possible.
This can't be done without syntax changes,
so a secondary goal is to provide a beautiful and natural syntax.

## New Syntax
OpenSCAD is a functional language with a C-like syntax.
This causes two problems:
* OpenSCAD is primarily a 3D modelling tool, not a programming language.
  It is targetted at designers, not professional programmers.
  Users should not be expected to have experience with a C-like language
  in order to understand the syntax: exposure to high school math should be sufficient.
* If you are a computer programmer (as opposed to a designer who happens to write programs),
  then you are quite familiar with C-like languages: Javascript, Java, C#, etc.
  For you, OpenSCAD causes cognitive dissonance: it has a C-like syntax,
  but the idioms of C do not work. You can't increment a variable or mutate an array.
  This actually creates an ease-of-use problem,
  and we would be better off if the language looked less C-like.

OpenSCAD2 provides a alternative to some of the syntax inherited from C.
The goal is to make the syntax look more like high-school math.
(Of course the old syntax continues to work.)

| old | new | explanation
|-----|-----|------------
| `!a` | `not a` |
| `a && b` | `a and b` |
| `a || b` | `a or b`  |
| `a ? b : c` | `if (a) b else c` | consistent syntax for<br>statements and expressions
| `pow(a,x)` | `a^x` | standard syntax for exponentiation<br>in math, physics + functional languages
| `a % m` | `a mod m` | true mathematical modulus operator
| `[a:z]`<br>`[a:k:z]` | `[a..z]`<br>`[a,a+k..z]` | range. Like set-builder notation<br>from high school math.
| -         | `a[start..]`<br>`a[..end]`<br>`a[start..end]` | slice

## First Class Values
In OpenSCAD2, everything is a first class value,
including functions, modules, groups, shapes,
and even library scripts.
All values can be written as literal constants,
printed using `echo`,
passed as a function argument, returned as a result,
stored as a list element.

This makes the language more consistent and more powerful
without adding complexity. Generalized extrusion operators
using first class function arguments is one outcome.

Ranges have been unified with lists, so that `[1..5]`
is the same as `[1,2,3,4,5]`.

Modules have been unified with functions, so that there is one
easy-to-use function definition syntax, and the oddball syntax
of `$children`, `children()` and `children(i)` has been deprecated.

## Unified Namespace and Simplified Scoping Rules
In order to make everything a first class value,
we need to have a single namespace,
instead of 3 namespaces for variables, functions and modules.

In order to make this change and also retain backward compatibility,
we need new syntax for function & module definitions, and
for the `include`/`use` operators.
If you use the new syntax, you get one namespace, and full access to the
features of OpenSCAD2. If you use the old definition syntax, you are in
backward compatibility mode, and old scripts continue to run.
The GUI provides a tool for upgrading a script to the new syntax.

## Functions and Modules
When using the new definition syntax, modules and functions are the same thing.
This considerably simplifies the language, and the new function definition
syntax is quite pleasant to use.

<table>
<tr>
<td> <b>old</b>
<td> <b>new</b>
<tr>
<td>
<pre>
function hypot(x,y) = sqrt(pow(x,2) + pow(y,2));
</pre>
<td>
<pre>
hypot(x,y) = sqrt(x^2 + y^2);
</pre>
</tr>
<tr>
<td>
<pre>
module box(x,y,z) cube([x,y,z]);
</pre>
<td>
<pre>
box(x,y,z) = cube([x,y,z]);
</pre>
</tr>
<tr>
<td>
<pre>
module elongate(n) {
  for (i = [0 : $children-1])
    scale([n, 1, 1]) children(i);
}
</pre>
<td>
<pre>
elongate(n)(children) = {
  for (c = children)
    scale([n, 1, 1]) c;
};
</pre>
</tr>
</table>

The new function definition syntax
can also be used for labeled arguments in a function call.
Here's an example of a generalized extrusion API:
the `twist` argument is a function.
```
linear_extrude(height=40, twist(h)=35*cos(h*2*pi/60)) {
    square(10);
}
```

## Objects
Objects are a powerful new addition to OpenSCAD,
but they arise naturally as the answer to some questions:
how can I make library scripts into first class values,
and what does <tt>{</tt><i>script</i><tt>}</tt> mean in an expression?

Objects have multiple roles in OpenSCAD2.
* An OpenSCAD2 script is evaluated to an object.
* Objects are the replacement for groups in the CSG tree.
* Library script files are referenced as objects.
* An object literal is a script enclosed in braces: `{script}`.

An OpenSCAD script may contain top level definitions and geometry statements.
An object is the value that results from evaluating a script.
An object has a set of named fields and a sequence of geometry values.

The fields within an object are referenced using `object.name` notation.
They may be parameters or metadata which describe the contained geometry.
But objects can be used in any situation where a set of named fields is required.

To reference an external library file, use the `script` function.
It reads the file and returns the resulting object.
```
use script("MCAD/math.scad");
shapes = script("MCAD/shapes.scad");
shapes.box(1,2,3);
```

An object can be customized using function call notation:
`object(name1=val1,...)` re-evaluates the script
with specified definitions overridden by new values, and returns a new object.

For example,
```
lollipop = {
  radius   = 10; // candy
  diameter = 3;  // stick
  height   = 50; // stick

  translate([0,0,height]) sphere(r=radius);
  cylinder(d=diameter,h=height);
};
lollipop(radius=15); // more candy!
```

There's lots more that can be done with objects.
Read the [full OpenSCAD2 proposal](../README.md) and explore.
