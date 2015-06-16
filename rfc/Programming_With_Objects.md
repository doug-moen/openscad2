# Programming With Objects

Objects are powerful; they solve a variety of different problems in OpenSCAD. The key features are:
* An object is a collection of named fields that can be queried using `.` notation.
* Objects can encapsulate a model's geometry together with its parameters and metadata.
* An object can be "customized", using function call notation to override some fields and recompute the geometry.

## Dictionaries of Named Parameters
Objects can encapsulate a set of parameters for defining a model,
and organize those parameters in a hierarchy,
using dotted names like `model.component.subcomponent.param`.

Currently this is being done using lists of name/value pairs
and the `search` function, but the resulting code is cryptic.

## Objects are Modules for Beginners
In classic OpenSCAD, modules are parameterized shapes.
Objects are also parameterized shapes, but they are easier to teach
to beginners. You don't need to learn about two different parameter
mechanisms (the parameter list, and `$children`/`children()`).
Instead, you just create an exemplar object, which can be prototyped as a top level
OpenSCAD script. Then you can selectively override parameters using function call syntax,
as in the `lollipop` example given previously.

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
Don't worry, the script-level variables aren't actually "global",
because the script can be instantiated with different parameter values
as many times as needed.

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

## Prototype-Based Programming
The "prototype" style of OpenSCAD programming
is named after the classless style of object oriented programming
called [Prototype-based programming](http://en.wikipedia.org/wiki/Prototype-based_programming).
Prototype based programming was designed to be just as powerful as class-based programming,
except that it can be a lot simpler, requiring less complicated language mechanisms.

In a prototype based language,
* Instead of class definitions, you have object literals. We have them.
* Instead of constructing an instance of a class,
  you clone an existing "prototype" object, and make changes to it.
  This is done using "object customization" in OpenSCAD2.
* There is some form of inheritance,
  where an object is defined to be just like a base object,
  except with some changes, which are specified by
  overriding existing fields and adding new fields.
  This is done using [customization and inclusion](Objects.md#constructing-new-objects-from-old).

In short, OpenSCAD2 appears to have all of the necessary language mechanisms
required to support object oriented programming.
Whether this is completely true will become clear in time, as OpenSCAD2 is implemented.
However, it seems that prototype based programming can be mined for useful idioms and design patterns
that can be reused in OpenSCAD2.

<!--
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
-->

## Bill of Materials

Some users need to extract metadata from their model, eg to construct a "bill of materials".
Or they need to translate their model to another modeling language
(see [openscad2povray](https://github.com/archie305/openscad2povray).

Currently, a "bill of materials" is commonly created by embedding `echo` statements
in the code, then collecting and filtering the console output.
OpenSCAD2Povray uses a combination of tricks, such as collecting `echo` output,
using `parent_module` and `$parent_modules`, and post-processing the CSG tree.

The problem with relying on features like `echo` and `parent_module`
is that they are low-level and non-declarative, and are too tightly coupled
to the current evaluator. In the future, we want to take advantage of OpenSCAD's
[declarative semantics](Declarative_Semantics.md)
to build a faster evaluator.
Referential transparency means we don't have to evaluate the same identical expression
more than once, we can cache results (which affects the number of echos that are executed).
Order independence means we can evaluate subexpressions out of order, or concurrently
(taking advantage of multiple cores), but this affects the order in which echos occur.

We need to provide users with a high level, declarative way of accomplishing these tasks.
The CSG tree is a pure value capable of storing all of the necessary metadata.
It can become the basis of a better way to extract metadata.

For example, you could write a script, `makebom.scad`,
which takes a target script as an argument.
Makebom traverses the target CSG tree,
and extracts metadata, which it returns as the 'bom'
component of its object.
If we provide a way to dump a selected part of the CSG tree as plain text or JSON,
then you can extract the BOM like this:

```
openscad -D target=mymodel.scad -i bom -o mybom.json makebom.scad
```
with this implementation:
```
// makebom.scad
target = undef;
extract_bom(object) = ...;
bom = extract_bom(script(target));
```
The same design pattern will work for openscad2povray.

I'm supposing that OpenSCAD is extended with a `-i` flag
to specify which subtree of the CSG tree to process,
and that the `-o` flag is extended to support output of JSON or plain text.
Plain text output requires that the node specified by `-i` is a string.
JSON output requires that the node specified by `-i`
consists of solely of `undef`, boolean, number, string, list and object values,
which are output as the 6 JSON data types.

## the Conway Polyhedron Operators
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
