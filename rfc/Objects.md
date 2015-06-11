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

## The `script` function
To reference a script file, use the `script` function.
Given a filename argument,
it reads a script file, and returns the resulting object.

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
lollipop = script("lollipop.scad");
```

Note: this is consistent with the way that all other external files are
referenced: you pass a filename argument to a function that reads the file
and returns a value.
Other examples are `import()`, `dxf_cross()` and `surface()`.

## The Object API

Objects are [First Class Values](First_Class_Values.md).

An object contains a set of named fields that can be referenced using `.` notation.
* `lollipop.height` is the stick height

An object is a geometric object containing a sequence of shapes.
It can be used in any context requiring a shape or sequence of shapes.
For example,
* `scale(10) lollipop`
* `intersection() lollipop // intersection of the stick and candy`

Objects support all of the
[generic sequence operations](Sequences.md):
* `len(lollipop) == 2`
* `lollipop[1] == cylinder(3,50)`

## Object Literals
The [First Class Values](First_Class_Values.md) principle requires object literals.

An object literal is a script surrounded by brace brackets.
```
// define the lollipop object
lollipop = {
  radius   = 10; // candy
  diameter = 3;  // stick
  height   = 50; // stick

  translate([0,0,height]) sphere(r=radius);
  cylinder(d=diameter,h=height);
};

// now add some lollipops to our geometry list
translate([-50,0,0]) lollipop;
translate([50,0,0]) lollipop;
```

This is a backwards-compatible reinterpretation of the `{...}` syntax in OpenSCAD1.

## Constructing New Objects from Old

There are two ways to build a new object from an existing object:
customization and inclusion.

### Customization

`object(name1=value1, name2=value2, ...)` customizes an object
by overriding specified definitions with new values,
re-evaluating the script and returning a new object.
  
```
// add a lollipop with bigger candy to the geometry list
lollipop(radius=15);
```

A script can be customized on the command line with the `-D` flag.
```
openscad -Dname1=value1 -Dname2=value2 ... myscript.scad
```

The new Customizer GUI under development does the same thing, only interactively.

### Inclusion

`include object;` includes all of the fields and geometry
of a specified base object into the current object under construction.

Using the `include` operator, you can create a new object
that is an extension of an base object.
For example, `lollipop_with_mint` extends `lollipop` with new fields and geometry:
```
lollipop_and_mint = {
   include lollipop;
   mint_diameter = 15;
   translate([mint_diameter*2, 0, 0])
      cylinder(h=mint_diameter/4, d=mint_diameter);
};
```

As a special case, `include script("filename");`
is the OpenSCAD2 syntax for `include <filename>` in OpenSCAD1.

### Composing Customization with Inclusion

By composing the two operations, you have the general ability
to create a new object by "inheriting" from an old object,
overriding existing fields and adding new fields.
This is like inheritance in object oriented programming,
except at the object level instead of the class level.

```
big_lollipop_and_mint = {
   include lollipop(radius=15, length=60);
   mint_diameter = 15;
   translate([mint_diameter*2, 0, 0])
      cylinder(h=mint_diameter/4, d=mint_diameter);
};
```

OpenSCAD1 supports this same operation at the script level, using a different syntax:
```
// big_lollipop_and_mint.scad
include <lollipop.scad>
radius=15;
length=60;
mint_diameter=15;
translate([mint_diameter*2, 0, 0])
  cylinder(h=mint_diameter/4, d=mint_diameter);
```
The OpenSCAD1 version of this API suffers from bugs, which are described
in [Definitions and Scoping](Definitions_And_Scoping.md).
The OpenSCAD2 implementation of customization and inclusion is intended
to preserve support for this feature, with better semantics.

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
The conversion from list to object reports an error if non-geometric values occur in the list.
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
