# Overview of OpenSCAD2

OpenSCAD2 is a backwards compatible redesign of OpenSCAD.
The original goal was first class function values to support generalized extrusion.
However, Marius challenged me to make everything a first class value,
and to make the language as consistent and uniform as possible.
This can't be done without syntax changes,
so a secondary goal is to provide a beautiful and natural syntax.

## Beautiful, Natural Syntax
OpenSCAD is a 3D modelling tool, not a programming language.
Users should not be expected to have experience with a C-like language
in order to understand the syntax: exposure to high school math should be sufficient.

OpenSCAD2 provides a more human readable alternative to some of the syntax inherited from C.
(Of course the old syntax continues to work.)

| old | new | explanation
|-----|-----|------------
| `!a` | `not a` |
| `a && b` | `a and b` |
| `a || b` | `a or b`  |
| `a ? b : c` | `if (a) b else c` |
| `pow(a,x)` | `a^x` |
| `a % m` | `a mod m` |
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
there is new syntax for function & module definitions, and
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
linear_extrude (height=40, twist(h) = 35*cos(h*2*pi/60)) {
    circle (10);
}
```

## Objects
Objects are a powerful new addition to OpenSCAD,
but they arise naturally as the answer to some questions:
how can I make library scripts into first class values,
and what does <tt>{</tt><i>script</i><tt>}</tt> mean in an expression?
