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
you don't need a main module,
although you may need auxiliary modules.
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

The prototype style is the preferred style for use with the
new Customizer GUI that is under development.
This style is also easier for beginners.
Scripts are shorter and easier to read and write,
and for simple models, you don't need to write function definitions.

## Prototypes with Auxiliary Functions

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

In OpenSCAD2, the simplest kind of inheritance is done using customization,
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

In order to support the full power of inheritance in an object oriented language,
we need to add two special variables, `$self` and `$super`.
Sorry, I haven't constructed good geometric examples for these yet.

If you want to override a function 'f' that you are inheriting from a base object, you can do this:
```
include parent(f(x) = g(x) + h(x));
```

OpenSCAD2 is lexically scoped, so in the above statement, 'g(x) + h(x)' is resolved in the current lexical environment, not in the environment of the object you are including. If 'g' and 'h' are only defined in the base object that is being included, is the compiler smart enough to resolve these references? Possibly not.
The alternative is to write:
```
include parent(f(x) = $self.g(x) + $self.h(x));
```
The special variable `$self` denotes the smallest enclosing object literal, or the object for the script file itself if referenced outside an object literal.

Now suppose that the new definition of 'f' needs to refer to the original 'f' from the base object. That's what `$super` is for.
```
include parent(f(x) = $super.f(x) + 1);
```
The only context where `$super` is meaningful is in the argument list of object customization.

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
Here's how it compares to Python:

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
include script("MCAD/math.scad");
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
use (deg, PI) script("MCAD/math.scad");
echo(deg(PI));
</pre>

</table>

This interface matches the feature set of Python, but it's more
powerful because it is more [composable](Composable_Building_Blocks.md).
* `script(filename)` is an expression that can be used in any context
  where an object is wanted.
* The argument to `script` is an expression: it need not be a string literal.
* The *object* argument of `include` is an expression
  that evaluates to an object, rather than a fixed filename.
  (So it could be an object name, an object literal, an object customization.)
* Ditto for `use`.

You can selectively override parameters within an included script
by using object customization:
```
lollipop = script("lollipop.scad");
include lollipop(radius=15); // more candy!
```

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
