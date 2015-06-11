# Programming With Objects

Objects are powerful; they solve a variety of different problems in OpenSCAD. The key features are:
* An object is a collection of named fields that can be queried using `.` notation.
* Objects can encapsulate a model's geometry together with its parameters and metadata.
* An object can be "customized", using function call notation to override some fields and recompute the geometry.

### Objects are Modules for Beginners
In classic OpenSCAD, modules are parameterized shapes.
Objects are also parameterized shapes, but they are easier to teach
to beginners. You don't need to learn about two different parameter
mechanisms (the parameter list, and `$children`/`children()`).
Instead, you just create an exemplar object, which can be prototyped as a top level
OpenSCAD script. Then you can selectively override parameters using function call syntax,
as in the `lollipop` example given previously.

### Dictionaries of Named Parameters
Objects can encapsulate a set of parameters for defining a model,
and organize those parameters in a hierarchy,
using dotted names like `model.component.subcomponent.param`.

Currently this is being done using lists of name/value pairs
and the `search` function, but the resulting code is cryptic.

### Bill of Materials

Some users need to extract metadata from their model, eg to construct a "bill of materials".
Unfortunately, they must rely on low level, non-declarative features to extract this information,
like `echo` and `parent_module`.
The CSG tree is a pure value capable of storing all of the necessary metadata.
It can become the basis of a better way to extract metadata.

For example, you could write a script, `makebom.scad`,
which takes a target script as an argument.
Makebom traverses the target CSG tree,
and extracts metadata, which it returns as the 'bom'
component of its object.
If we provide a way to dump a selected part of the CSG tree as XML or JSON,
then you can extract the BOM like this:

```
openscad -D target=mymodel.scad -i bom -o mybom.xml makebom.scad
```
with this implementation:
```
// makebom.scad
target = undef;
extract_bom(object) = ...;
bom = extract_bom(script(target));
```
Until we have standard conventions for representing BOM metadata,
each project will need its own implementation of `makebom.scad`.

### the Conway Polyhedron Operators
Mathematician John Conway has designed
[a language for generating symmetric polyhedra](http://en.wikipedia.org/wiki/Conway_polyhedron_notation).
It consists of some primitive polyhedra, plus operators for transforming one polyhedron
into another. It is a powerful geometric solid modelling language that fits
well with OpenSCAD, with little overlap.

[Kit Wallace has implemented this for OpenSCAD](https://github.com/KitWallace/openscad/blob/master/conway.scad).

To implement Conway operators in OpenSCAD1, you need to define an abstract data type for a polyhedron. It has to be implemented as an array, containing vertices, faces, and whatever else is needed. The Conway operators become functions that map a poly to another poly. There needs to be a separate module to render a Conway polyhedron.

We can do better than this in OpenSCAD2.
A Conway polyhedron can be represented as an object,
with named fields for the vertices, faces, etc.
The polyhedron object can contain its own geometry,
so there is no need for a user to invoke a separate render operation.
The goal is [composability](Composable_Building_Blocks.md):
from a user's perspective, we'd like polyhedrons constructed by `conway.scad`
to be interoperable with primitive polyhedrons.

An open question is whether built-in modules can be redesigned to
return an object, containing the necessary fields, so that library
functions such as the Conway operators can operate on them.

To answer this question, we should look at existing libraries
that construct and operate on polygon values, and try to determine
a standard interface.
