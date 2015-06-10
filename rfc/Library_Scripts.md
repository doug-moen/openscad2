# Library Scripts

There are two kinds of external script files that you might want to reference
from your code: model scripts, and library scripts.

A model script is a parameterized geometric model
which you may wish to customize and include in a larger model you are building.

A library script is an API for solving some class of problems.
It defines mathematical constants, functions and modules
which you may wish to reference from your code.
MCAD is a prototypical example of a collection of library scripts.

Most of the MCAD library scripts contain example code which demonstrates
how to use the API. Different authors use different conventions.
Sometimes the code is commented out, sometimes it is encapsulated
in one or more "test" modules (the module names begin with "test"),
and sometimes the example code is written as top level geometry statements
which are not commented out.

## The OpenSCAD1 Interface
The current OpenSCAD interface for referencing script files looks like this:
* `include <filename.scad>`
* `use <filename.scad>`

The `include` command includes the entire file (all of the top level definitions, plus the geometry).
while the `use` command only includes the function and module definitions (no variables, no geometry).

The `include` mechanism allows you to selectively override parameters within an included script,
like this:
```
include <lollipop.scad>
radius = 15; // more candy!
```

## Problems with OpenSCAD1
There are a number of problems with the OpenSCAD1 interface.
* The distinction between `include` and `use` is confusing to users.
* The fact that `use` omits variables is a problem for library scripts
  that need to define named mathematical constants as part of their API,
  or for use in their functions and modules.
* It is buggy because `include` just copies the contents of `filename.scad` into your script,
  character by character, and if there is an error within the script, then the filename/linenumber
  in the error message is incorrect, because the file boundaries disappeared before the text was parsed.
* The mechanism for overriding parameters in a model script is confusing and buggy.
  The problems are discussed in a number of forum posts.
  The solution is the OpenSCAD2 object customization feature. It works better because it is lexical scoped,
  as discussed in [Definitions and Scoping](Definitions_And_Scoping.md).
* It is limited because you can't control which top level definitions
  from a library are added to your script.

The confusion between `include` and `use` is because there is no standard
way to include a library script so that you get the entire API, even the constants,
but you don't get the geometry from example code. You have to read the library script,
figure out what style it is written in, then choose either `include` or `use`
based on this research.

This is true even for the latest versions of the MCAD scripts.
* Some MCAD scripts export mathematical constants as part of their API.
  You must use `include`. Examples are `math.scad` and `materials.scad`.
* Some MCAD scripts define mathematical constants that are used within
  their functions and modules. They won't work with `use`, you must use
  `include`. Examples are `lego_compatibiity.scad`, `involute_gears.scad`.
* Some MCAD scripts have top level geometry as example code.
  They are designed to work with `use`.
  For example, `trochoids.scad` contains demo code with top level geometry
  and parameter definitions, including a definition of `$fn`.
  These parameter definitions are intended to be invisible
  when the script is `use`d.

## Referencing a Model Script
The OpenSCAD2 interface for referencing and parameterizing an external model script
is given in [Objects](Objects.md). Briefly:
* `script(filename)` reads a script file and returns an object.
* `include object;` includes all of the named fields and geometry from another object
  into the object currently being defined.
* `object(name1=value1,...)` customizes an object. The object's script is re-evaluated
  with overridden values for some of the script's definitions,
  and a new object is returned.

## Referencing a Library Script
OpenSCAD2 should provide a standard interface that works for
referencing any library script, regardless of whether it contains example code,
and regardless of whether the API includes mathematical constants.

The obvious solution is to provide a variant of the `use` command
which doesn't include geometry, but which does include all of the
top level definitions, even if they are numeric constants.
The syntax is `use object;`.
As a special case, definitions of `$` variables like `$fn` are not included;
they are considered part of the geometry.

In OpenSCAD2, the `include` and `use` commands have well defined
and distinct use cases:
* `include` is not intended for use with library scripts.
  It's designed for model scripts, since it includes the model's geometry.
  More generally, `include` implements *object inheritance*
  in the OpenSCAD2 object system.
  It is backward compatible with the OpenSCAD1 `include` command.
* `use` is specifically designed for library scripts.
  It includes top level definitions but not geometry.
  It is not fully backwards compatible with the OpenSCAD1 `use` command,
  because it includes all definitions, even numeric constants.

Most modern programming languages have a "module system" for referencing
external libraries. The standard features are:
* **Qualified reference.**
  You can use a syntax like M.x to reference `x` within module M,
  without importing M's definitions directly into your namespace.
* **Selective import.**
  You can selectively import some of a module's definitions into your namespace,
  by listing the names you want to import.
* **Import everything.**
  You can import all of a module's definitions into your namespace.

To support selective import, we'll add the `using` command,
which takes as arguments a list of names to import from an object,
plus an object expression.
So
```
using (name1, name2, ...) object;
```
is an abbreviation for
```
name1 = object.name1;
name2 = object.name2;
...
```
The `using` command will be useful in porting some cases
of the OpenSCAD1 `use` command, where there are name conflicts
because the OpenSCAD2 `use` command imports too many names.
For example,
```
using (epitrochoid,hypotrochoid) script("MCAD/trochoids.scad");
```
because `use` will import the parameters for the trochoid demo code.
Currently, all of the other MCAD library scripts
work fine with OpenSCAD2's `use` command.

Here's how OpenSCAD2 compares to the Python module system:

<table>

<tr>
<td align=center> <b>Python</b>
<td align=center> <b>OpenSCAD2</b>

<tr>
<td>
<pre>
import math
print math.pi
</pre>
<td>
<pre>
math = script("MCAD/math.scad");
echo(math.PI);
</pre>

<tr>
<td>
<pre>
from math import *
print degrees(pi)
</pre>
<td>
<pre>
use script("MCAD/math.scad");
echo(deg(PI));
</pre>

<tr>
<td>
<pre>
from math import degrees, pi
print degrees(pi)
</pre>
<td>
<pre>
using (deg, PI) script("MCAD/math.scad");
echo(deg(PI));
</pre>

</table>

This interface matches the feature set of Python, but it's more
powerful because it is more [composable](Composable_Building_Blocks.md).
* `script(filename)` is an expression that can be used in any context
  where an object is wanted.
* The argument to `script` is an expression: it need not be a string literal.
* The *object* argument of `use` is an expression
  that evaluates to an object, rather than a fixed filename.
  (So it could be an object name, an object literal, an object customization.)
* Ditto for `using`.

## Writing a Library Script

There is an almost universal desire among the authors of library scripts
to include example code that demonstrates how to use the API.
So we should support this.

There should be a standard way for library scripts to include example code
that you can interact with using the new Customizer GUI, without having to
uncomment example code. When you reference a library script for the purpose
of using its API, the example code is not included in your model.


In OpenSCAD2, there is a new coding standard for writing library scripts.
It supports the following requirements:
* The script may contain example code that demonstrates how to use the API,
  and it doesn't have to be commented out.
* The example code should be annotated for the Customizer GUI.
* There are sometimes multiple examples.
  The customizer GUI should provide a mechanism for selecting between
  alternative models.
* The top level parameters that control the example code are not part of the
  library API. They shouldn't be visible in contexts where the API is being used,
  so they should somehow be made private.

The OpenSCAD2 interface for referencing an external library script ...

## Old Stuff

### the `script` function
To reference an external library file, use the `script` function.
It reads a file, and returns the resulting object.

If you just want to drop a single lollipop into your model,
you could do this:
```
// add a lollipop to our geometry list
script("lollipop.scad");
```

If you want to reference the same script more than once,
you can give it a name.
For example,
```
math = script("MCAD/math.scad");
echo(math.deg(math.PI));
```

Note: this is consistent with the way that all other external files are
referenced: you pass a filename argument to a function that reads the file
and returns a value.
Other examples are `import()`, `dxf_cross()` and `surface()`.

<!--
But it's the `import` function that's called in those
other cases. Why not just use `import` for reading library scripts? The problem is that `import` uses the filename extension to decide what type of file it is reading. I'm told that users are not consistent in using the extension ".scad" for files referenced by `include` and `use`. I don't want to force people to rename their files before they can upgrade to OpenSCAD2.
-->

### the `include` operator

`include object;` includes all of the top level definitions and shapes from the object into your script.
It can be used for referencing library files, and it is like "inheritance" for objects.

The upgrade tool converts OpenSCAD1 `include <filename>` commands
to `include script("filename");`.
It is legal for an OpenSCAD2 script to include an OpenSCAD1 script file,
and vice versa.
The details are in [Backward Compatibility](Backward_Compatibility.md).

For example,
```
include script("examples/example020.scad");
```

### the `use` operator
According to the OpenSCAD1 User Manual,
> `use <filename>` imports modules and functions, but does not execute any commands other than those definitions.

The upgrade tool needs to be able to translate this into equivalent OpenSCAD2 code.
We could add a `use object;` command, similar to the `include` operator.
The meaning is clear as long as the referenced script is written in OpenSCAD1.

But things get fuzzy if you `use` an OpenSCAD2 script, since the compiler doesn't
have a general ability to distinguish function definitions from other definitions: we might
not know until runtime what type of value is bound by a particular definition.
The easy thing to do is to restrict `use` to only importing definitions that use
"function definition syntax". So `f(x)=x+1;` would be imported,
but `rot45=rotate(45);` would not be imported. That is very arbitrary,
and to me it is unpleasant, since it creates the possibility that changing the
way that a library function is defined (eg, computing the function using higher
order functions) could break clients, even if the interface doesn't change.
If we defined `use` in this way, I would want to immediately deprecate it.

But there are other possible ways to translate `use <filename>` in the upgrade tool,
and there are other possible semantics we could give to the `use` operator.

Consider what problem the `use` command appears to have been designed to solve:
* We don't want to include the script's geometry, and we don't want to include all of the
  top level definitions, because some may conflict with local definitions.

My approach is to create a fresh solution to this problem,
achieving feature parity with Python,
and recycling the `use` keyword for the new operation.

So
```
use (name1, name2, ...) object;
```
is an abbreviation for
```
name1 = object.name1;
name2 = object.name2;
...
```
As mentioned earlier, this is inspired by `from module import name1,name2,...` in Python.

The upgrade tool converts `use <filename>` by
opening `filename`, making a list of function and module definitions,
and putting this list into an OpenSCAD2 `use` statement. The user running the
upgrade tool can edit this list of names as desired.

<!--
* `use object;` makes the top level definitions in *object* available for
  lookup from the current scope, but doesn't include those definitions
  into the current object. This is for the benefit of library scripts that don't
  want to export all of the definitions that they make use of from other
  libraries. If your script happens to define an object with the same name
  as a binding visible via `use`, then your definition takes precedence.

   ```
   use script("MCAD/shapes.scad");
   box(1,2,3);
   ```
-->
