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

## Customizing an object
`object(p1=val1,p2=val2,...)` customizes an object, overriding specified definitions with new values,
by re-evaluating the script and returning a new object.
  
```
// add a lollipop with bigger candy than the rest
lollipop(radius=15);
```

## Prototypes vs Modules
Here are two programming styles that can be used
for creating reusable scripts that render a model:
the "module" style, and the "prototype" style.

In the "module" style, you put all of your logic into modules.
At the end of the script, the main module is invoked to render the model.
The intent of this style is that other scripts can reuse the logic
by `use`ing the script.

For example,
```
module lollipop(
  radius   = 10,
  diameter = 3,
  height   = 50)
{
  translate([0,0,height]) sphere(r=radius);
  cylinder(d=diameter,h=height);
}

lollipop();
```

In the "prototype" style,
you put parameter definitions at the top of your script.
This allows inexperienced users to find and tweak the parameters,
without necessarily understanding how the rest of the code works.
On Thingiverse, the parameters are given Customizer annotations,
so that visitors to Thingiverse.com can tweak the parameters
using the Customizer GUI, without even reading the script.
OpenSCAD is soon getting its own Customizer GUI, and this will
be an important part of the experience of using OpenSCAD2.

In the "prototype" style,
you don't need a main module.
It is simpler to write out the body of the main module
as top level geometry statements that reference the parameters
as top level definitions.

For example,
```
radius   = 10; // candy
diameter = 3;  // stick
height   = 50; // stick

translate([0,0,height]) sphere(r=radius);
cylinder(d=diameter,h=height);
```

You may need auxiliary modules, but they can directly refer to top level
parameters as "global variables". In this style, there is no need to
pass all parameters as arguments, which saves a lot of code if you
have many model parameters.

In OpenSCAD2, the prototype style is just as powerful as the module style
for code reuse. Instead of writing
```
use <lollipop.scad>
lollipop(radius=15);
```
in the module style, you can instead write
```
lollipop = script("lollipop.scad");
lollipop(radius=15);
```
in the prototype style.

In the module style, you have a main module to which you pass all of the
model parameters as arguments (you can provide defaults for all the arguments).
You invoke the module to build the geometry.

In the prototype style, you have an object that represents the model:
it acts as a container for all of the model parameters,
and also contains the geometry, and contains any auxiliary functions used
to build the model.

The prototype style is the preferred style for use with the
new Customizer GUI that is under development, since it puts
the parameters at the top level of a script where the Customizer can see them.
This style is also easier for beginners.
Scripts are shorter and easier to read and write,
and for simple models, you don't need to write function definitions.

Finally, using objects to group model parameters together with geometry
is a powerful idea which enables some new programming idioms.

## Inheritance
The "prototype" style of OpenSCAD programming
is named after the classless style of object oriented programming
called [Prototype-based programming](http://en.wikipedia.org/wiki/Prototype-based_programming).
Prototype based programming was designed to be just as powerful as class-based programming,
except that it's a lot simpler.

In a prototype based language,
instead of class definitions, you have object literals.
Instead of constructing an instance of a class,
you clone an existing "prototype" object, and make changes to it.
This is done using "object customization" in OpenSCAD2.

Prototype based languages have inheritance,
where an object is defined to be just like a base object,
except with some changes, which are made by overriding existing
fields and adding new fields.
Just as with classes in class-based OOP languages,
base objects need to be designed with inheritance in mind.
They need to provide fields that are "hooks" that can be overridden
by derived objects.

In OpenSCAD2, the simplest kind of inheritance is customization,
where you just override existing fields.
```
big_lollipop = lollipop(radius=15, height=60);
```

The `include` command adds all of the fields and geometry of a specified object
to the current object. It comes from OpenSCAD1, but the syntax has changed
from `include <filename>` to `include object;`.

You can extend a base object with new fields and geometry using the `include` command.
```
lollipop_and_mint = {
   include lollipop;
   mint_diameter = 15;
   translate([mint_diameter*2, 0, 0])
      cylinder(h=mint_diameter/4, d=mint_diameter);
};
```

You can combine these two idioms and inherit from a customized base object.
Insert example here.

### Inheritance and Self Reference
OpenSCAD2 has the same power as a single-dispatch object oriented language.
The syntax `obj.f(x)` has the semantics of invoking a method within an object.
This means we need to implement the semantics of "self reference".
In Smalltalk, this feature is embodied by the `self` and `super` keywords.
In OpenSCAD2, *self* and *super* are opcodes in the virtual machine,
and it's the compiler's responsibility to insert these opcodes in the correct places.
In other words, I don't think we need any additional syntax to make inheritance
with single dispatch work. All of the OOP semantics come from composing these
three features:
* object literals
* `include`
* object customization

And this is awesome, because the more syntax and language features we need
to make OOP work, the harder it is to learn and use.

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
