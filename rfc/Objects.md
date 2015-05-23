# Objects
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

To reference an external library file, use the `package` function.
It reads a file, and returns the resulting object.
For example,
```
lollipop = package("lollipop.scad");
math = package("MCAD/math.scad");
shapes = package("MCAD/shapes.scad");
```
Now you can use `math.PI` and `shapes.box(1,2,3)`.

More operations on objects:

* `include object;` includes all of the top level definitions and shapes from the object into your script.
  For example,

   ```
   include package("examples/example020.scad");
   ```

* `use object;` includes just the top level definitions, not the shapes.

   ```
   use package("examples/example020.scad");
   spring();
   ```

* `using(name1,name2,...) object;` imports specified names from an object.

   ```
   using(box, ellipsoid, cone) shapes;
   ```

* `object(p1=val1,p2=val2,...)` customizes an object, overriding specified definitions with new values,
  by re-evaluating the script and returning a new object.
  
   ```
   lollipop(radius=15); // more candy!
   ```

## Programming with Objects
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
```

This is a backwards-compatible reinterpretation of the `{...}` syntax in OpenSCAD.
It is very powerful.

Objects can encapsulate a set of parameters for defining a model,
and organize those parameters in a hierarchy,
using dotted names like `model.component.subcomponent.param`.

OpenSCAD evaluates a script to produce a tree of shapes: that's what the CSG tree is.
With the introduction of object literals,
we will now evaluate a script to produce a tree of shapes and objects.
The root of this tree is the script's object.
Objects are more powerful because they can encapsulate a model's geometry together with its parameters,
so that functions can render a model's geometry and query its parameters using the same value.

