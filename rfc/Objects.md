# Objects
"Geometric objects", or "objects" for short,
are a new kind of value which has multiple roles in OpenSCAD2.
* Objects are the replacement for groups in the CSG tree.
  An object contains geometry: a possibly empty sequence of shapes and objects,
  which can be referenced using [sequence operations](Sequences.md).
* An object also contains a possibly empty set of named fields,
  which can be referenced using `.` notation: `object.name`.
  These may be parameters or metadata which describe the contained geometry.
  But objects can be used in any situation where a set of named fields is required.
* An OpenSCAD2 script is evaluated to an object.
* External library files are referenced as objects.
  The `include` and `use` operators now take objects as arguments.
* An object literal is a script enclosed in braces: `{script}`.
* An object can be customized using function call notation:
  `object(name1=val1,...)` re-evaluates the script with specified
  definitions overridden by new values, and returns a new object.

## Scripts denote Objects
If OpenSCAD2 has a [declarative semantics](Declarative_Semantics.md),
then an OpenSCAD script must have a meaning&mdash;what is it?
The answer: a script denotes an object.

A script consists of a set of top level definitions, plus some top level geometry statements.
An object is what a script denotes, so an object is a set of named fields, plus a sequence of shapes.

For example,

```
// lollipop.scad
radius   = 10; // candy
diameter = 3;  // stick
height   = 50; // stick

translate([0,0,height]) sphere(r=radius);
cylinder(d=diameter,h=height);
```

The lollipop script denotes an object with 3 named fields
(radius, diameter, height) and two shapes, a sphere and a cylinder.

In accordance with [First Class Values](First_Class_Values.md),
we are going to make objects into first class values.
If `lollipop` is the object denoted by the lollipop.scad script,
then
* `lollipop.height` is the stick height
* `lollipop` is interpreted as a sequence of shapes, in any context that
  expects a shape or list of shapes. For example, `scale(10) lollipop`.
* An object can be used in any context expecting a list,
  and it behaves like a list of shapes. For example,
  * `len(lollipop) == 2`
  * `lollipop[1] == cylinder(3,50)`

Some more operations on objects are described in the next section.

## Library Files
The current OpenSCAD interface for referencing external library files looks like this:
* `include <filename.scad>`
* `use <filename.scad>`

This interface is kind of limited, and kind of buggy.
It is limited because you can't control which top level definitions are added to your script.
It is buggy because `include` just copies the contents of `filename.scad` into your script,
character by character, and if there is an error within the script, then the filename/linenumber
in the error message is incorrect, because the file boundaries disappeared before the text was parsed.

The `include` mechanism allows you to selectively override parameters within an included script,
like this:
```
include <lollipop.scad>
radius = 15; // more candy!
```
However, this mechanism is quite buggy, as discussed in several forum threads.

We are going to provide a better interface.

To reference an external library file, use the `script` function.
It reads a file, and returns the resulting object.
For example,
```
lollipop = script("lollipop.scad");
math = script("MCAD/math.scad");
shapes = script("MCAD/shapes.scad");
```
Now you can use `math.PI` and `shapes.box(1,2,3)`.

Note: this is consistent with the way that all other external files are
referenced: you pass a filename argument to a function that reads the file
and returns a value. But it's the `import` function that's called in those
other cases. Why not just use `import` for reading library scripts? The problem is that `import` uses the filename extension to decide what type of file it is reading. I'm told that users are not consistent in using the extension ".scad" for files referenced by `include` and `use`. I don't want to force people to rename their files before they can upgrade to OpenSCAD2.

More operations on objects:

* `include object;` includes all of the top level definitions and shapes from the object into your script.
  This is like "inheritance" for objects.
  For example,
   ```
   include script("examples/example020.scad");
   ```

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

* `object(p1=val1,p2=val2,...)` customizes an object, overriding specified definitions with new values,
  by re-evaluating the script and returning a new object.
  
   ```
   lollipop(radius=15); // more candy!
   ```

## Object Literals
The [First Class Values](First_Class_Values.md) principle requires object literals.

An object literal is a script surrounded by brace brackets.
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

This is a backwards-compatible reinterpretation of the `{...}` syntax in OpenSCAD.

## The CSG Tree
Objects are the replacement for groups in the CSG tree.

The root of the CSG tree is the object denoted by the main script.
The leaf nodes of the CSG tree are shapes, and the non-leaf nodes are objects.

A list of shapes and objects is operationally equivalent to
an object containing the same geometry sequence.
However, if such a list is used in a context where geometry is required,
then the list is implicitly converted to an object.
For example, if you write
```
union()([ cube(12,true), sphere(8) ]);
```
then the list is converted to an object, so the above code is equivalent to
```
union() { cube(12,true); sphere(8); }
```
The conversion from list to object discards any non-geometric values in the list.
This conversion ensures that only objects and shapes appear in the final CSG tree.

The modifier characters `%`, `#` and `!` take a geometry value as an argument,
and set a modifier flag in the value. If the argument is a list, it's first converted
to an object, since only shape and object values contain storage for modifier flags.

The undocumented `group` module has always been an identity function that returns its children:
```
group(){ cube(12,true); sphere(8); }
```
In OpenSCAD2, the above call to `group()` returns an object, and is equivalent to just
```
       { cube(12,true); sphere(8); }
```

## Programming with Objects

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
extract_bom = function(object) -> ...;
bom = extract_bom(script(target));
```
Until we have standard conventions for representing BOM metadata,
each project will need its own implementation of `makebom.scad`.
