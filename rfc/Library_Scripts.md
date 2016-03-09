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
  In most cases, there's no reason to use `include` anymore.
  Instead, you can write code like this:
  ```
  // add a lollipop to our geometry
  scale(2) script("lollipop.scad");
  ```
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
* `use` is specifically designed for referencing a library script, as a client.
  It imports top level definitions but not example geometry or internal definitions.
  The imported library APIs are not exported by the client script.
* `include` is a form of *object inheritance*
  (see [Object Inheritance](Inheritance.md)).
  The use cases for `include` are much narrower and more specialized.
  For example, if one library script wants to include another library's API
  as part of its own (ie, inheritance), then it would `include` the other library.

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

To support selective import, we'll add the `only` operator,
which is composed with `use` as follows:
```
use only (name1, name2, ...) object;
```
By itself, the `only` operator constructs a subset of an object
containing only fields with the specified names.

The `use only` command will be useful in porting OpenSCAD1 library `use` and `include`
in cases where OpenSCAD2 reports name conflicts, eg caused by two libraries
defining the same name, or a conflict between a library definition and a local definition.

TODO: add a `without` operator.

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
use only (deg, PI) script("MCAD/math.scad");
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
It is built by composing three generic operations: `script`, `use` and `only`.

## Parameterized Libraries
Some library scripts contain tweakable top-level parameters.
For example,
* [MCAD/lego_compatibility.scad](https://github.com/openscad/MCAD/blob/master/lego_compatibility.scad)
  contains 12 parameters for 3D printed lego blocks. You can tweak `cylinder_precision`
  to control the number of polygons used in cylindrical features. You might want to tweak
  the remaining parameters to build Duplo blocks.
* [MCAD/gridbeam.scad](https://github.com/openscad/MCAD/blob/master/gridbeam.scad)
  has 7 parameters.

In OpenSCAD1, you can't `use` a parameterized library, you must `include` it.
To set a parameter, you assign a value after you include the script.
For example,
```
include <MCAD/gridbeam.scad>
beam_is_hollow = 0;
zBeam(3);
```

This code won't work after conversion to OpenSCAD2 syntax,
you'll get a multiple definition error for `beam_is_hollow`.
What you do instead is customize the library script.
Also, it's now recommended to `use` all libraries.
For example,
```
use script("MCAD/gridbeam.scad")(beam_is_hollow = 0);
zBeam(3);
```
or
```
GB = script("MCAD/gridbeam.scad");
GB(beam_is_hollow = 0).zBeam(3);
```

OpenSCAD2 has improved support for parameterized libraries, because
* You can consistently `use` any library, even if it is parameterized.
* You can customize at the point of a module call.

Still, this is a significant syntactic change in how parameterized libraries are used.
The rationale for multiple definition errors is given
[here](Definitions_And_Scoping.md#missing-and-multiple-definitions).

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

## `only`
The `only` operator returns a projection of an object
containing only a specified subset of its fields.
```
only(name1, name2, ...) object
```
is equivalent to
```
{
   name1 = object.name1;
   name2 = object.name2;
   ...
}
```
This is composed with `use` in the following idiom:
```
use only (mm, inch) script("MCAD/units.scad");
```
See [Library Scripts](Library_Scripts.md).
