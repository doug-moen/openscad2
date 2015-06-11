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

This is true even for the June 2015 versions of the MCAD scripts.
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

The obvious solution is a `use` command
which doesn't import geometry, but which does import all of the
top level definitions, even if they are numeric constants.
The syntax is `use object;`.
As a special case,
* Names beginning with `$` (like `$fn`) are not imported;
  they are considered part of the geometry.
* Names beginning with `_` are not imported;
  they are considered internal to the library.
  OpenSCAD2 does *not* support rigorous information hiding&mdash;this is
  merely a convention of the `use` command.

In OpenSCAD2, the `include` and `use` commands have well defined
and distinct use cases:
* `include` is not intended for use with library scripts.
  It's designed for model scripts, since it includes the model's geometry.
  More generally, `include` is a form of
  [*object inheritance*](Objects.md#inheritance)
  in the OpenSCAD2 object system.
* `use` is specifically designed for library scripts.
  It imports top level definitions but not geometry or internal definitions.

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
The `using` command will be useful in porting OpenSCAD1 library `use` and `include`
in cases where OpenSCAD2 reports name conflicts, eg caused by two libraries
defining the same name, or a conflict between a library definition and a local definition.

Here's how OpenSCAD2 compares to the Python module system:

<table>

<tr>
<td>
<td align=center> <b>Python</b>
<td align=center> <b>OpenSCAD2</b>

<tr>
<td> <b>Qualified<br>Reference</b>
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
<td> <b>Selective<br>Import</b>
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

<tr>
<td> <b>Import<br>Everything</b>
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

</table>

This interface matches the feature set of Python, but it's more
powerful because it is more [composable](Composable_Building_Blocks.md).
* `script(filename)` is an expression that can be used in any context
  where an object is wanted.
* The *object* argument of `use` is an expression
  that evaluates to an object, rather than a fixed filename.
  (So it could be an object name, an object literal, an object customization.)
* Ditto for `using`.

## Writing a Library Script

There is an almost universal desire among the authors of library scripts
to include example code that demonstrates how to use the API.
So we should support this better.

There should be a standard way for library scripts to include example code
that you can interact with using the new Customizer GUI, without having to
uncomment example code. When you reference a library script for the purpose
of using its API, the example code is not included in your model.

OpenSCAD2 will support the following requirements for writing library scripts:
* The script may contain example code that demonstrates how to use the API,
  and it doesn't have to be commented out.
* The example code can be annotated for the Customizer GUI.
* There are sometimes multiple examples.
  The customizer GUI should provide a mechanism for selecting between
  alternative models.
* The top level parameters that control the example code are not part of the
  library API. They shouldn't be imported by `use`.

Annotations for the customizer GUI are out of scope for this RFC,
but the new `use` command supports all of the other requirements.
You just need to use identifiers starting with `_` for definitions
that are part of the demo code.
