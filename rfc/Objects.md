# Objects

A "geometric object", or "object" for short, is a first class value that represents an OpenSCAD script.
* An object contains named fields, which correspond to the top level definitions in a script.
  These fields are referenced as `object.name`.
* An object contains geometry, a sequence of shapes and objects,
  which correspond to the top level geometry statements in a script.
  Geometry is referenced using [sequence operations](Sequences.md).
* Objects are constructed by `script(filename)`, which reads an object from a script file,
  and by `{script}`, which is an object literal.
* Objects may be transformed.
  `object(name1=val1,...)` customizes an object, re-evaluating its script with specified
  definitions overridden by new values, returning a new object.

Objects have multiple roles in OpenSCAD2.
* Objects are the replacement for groups in the CSG tree.
* A geometric model is represented by an object, which encapsulates both its geometry and its parameters.
* Library scripts are referenced as objects. The `include` and `use` operators now take objects as arguments.
  Library scripts with tweakable top-level parameters, like
  [gridbeam.scad](https://github.com/openscad/MCAD/blob/master/gridbeam.scad),
  are parameterized objects.
* A set of model parameters, by itself, can be represented as an object.
* The ability to access fields and customize a parameterized model or library
  makes new programming idioms possible.

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

Since objects are the replacement for groups,
you can group shapes using `{shape1; shape2;}`.
And this makes object literals
a backwards-compatible reinterpretation of the `{...}` syntax.

## Constructing New Objects from Old

### customization

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

Customization is a relatively fast operation, since most of the
structure of the new object is shared with the base object.
Customization is also a limited operation that is only good for
overriding parameters in an object. Two things you can't do
with customization, that you can do with `overlay`:
* You can't add new fields to the object.
* You can't create a dependency between two fields
  in the new object, such that customizing one field updates the other.

### `overlay`
The `overlay` operator customizes fields within a base object,
and adds new fields and geometry, as specified by an extension object.

If `base` and `extension` are both objects,
then `base overlay extension` customizes the base object with those fields in `extension` that are also in `base`,
and extends the base object with those fields in `extension` that are not in `base`.
The geometry within `extension` is added to the end of the base's geometry list.
The result is a new object.

If `base` is a shape or a list of shapes and objects, then it is first converted to an object.
This could be used to add metadata to an existing shape or object.
For example,
```
material(x)(shape) = shape overlay {$material = x;};
material("nylon") cube(10);
```

If there are dependencies between fields in the extension object,
then those dependences are preserved in the derived object.
For example, in
```
base overlay {x=1; y=x+1;}
```
then regardless of what the `base` object contains,
the derived object will contain two fields `x` and `y`,
such that customizing `x` will update `y` based on the new value of `x`.

### `overlay` with a mixin
The `overlay` operation described in the previous section
is limited by the fact that the extension object cannot refer
to fields in the base object. This limitation is overcome
by using a [mixin](#mixins) in place of an extension object:
`base overlay mixin`.
[Mixins are described here](#mixins).

### the `include` and `overlay` statements
`include object;` includes all of the fields and geometry
of a specified base object into the current object under construction.
The `object` argument is a compile time constant.

`overlay object;` does the same thing, with the following differences:
* It's an error for a binding imported by `include`
  to conflict with another definition or `include` in the same block.
* The `overlay` statement takes either an object or a [mixin](#mixins) argument,
  and allows new bindings imported from the object or mixin
  to override earlier bindings of the same name.

In OpenSCAD2, one definition cannot override another definition of the same name
unless this is made explicit in the source code. Otherwise, it is an error.

Therefore, in order to translate an OpenSCAD1 `include <file>` statement
into OpenSCAD2, you need to make explicit any overrides that are occurring.

In general, `include <file.scad>` can be translated in two ways:
* `include script("file.scad");` &mdash; the normal case
* `overlay script("file.scad");` &mdash; if `file.scad` overrides previous definitions

In OpenSCAD1, you can include a script, then customize that script by overriding
some of its definitions. For example,
```
include <MCAD/bearing.scad>
epsilon = 0.02;  // override epsilon within bearing.scad
```
In OpenSCAD2, this customization must be explicit.
Normally, the simple customization (function call) syntax is all you need:
```
include script("MCAD/bearing.scad")(epsilon=0.02);
```
In more complex cases, you might need to use `overlay` to customize the included script.

Note that you can also customize a library script referenced by `use`,
something not possible in OpenSCAD1.
```
use script("MCAD/bearing.scad")(epsilon=0.02);
```

In OpenSCAD1, library scripts are referenced using either `use` or `include`,
depending on how the library script is written. You may need to read the
source to figure out how to reference it. In OpenSCAD2, `use` is recommended
for referencing all library scripts, while `include` is only needed
for special purposes.

Inclusion is really a form of object inheritance.
The use cases for `include` in OpenSCAD2 are narrower than in the original language:
* A model script includes another model in order to extend it with
  new fields and geometry. That's an exceptional case.
  More commonly, you just reference the other model, as `lollipop;`
  instead of `include lollipop;`.
* A library script includes another library, for the purpose of
  extending the other library's API. That's an exceptional case.
  More commonly, you just use the library, as `use library;`.

See [Library Scripts](Library_Scripts.md) for more discussion of `use`.

<!--
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

Inclusion is a form of object inheritance. The use cases for `include` in OpenSCAD2
are narrower than in the original language:
* A model script includes another model in order to extend it with
  new fields and geometry, as above. That's an exceptional case.
  More commonly, you just reference the other model, as `lollipop;`
  instead of `include lollipop;`.
* A library script includes another library, for the purpose of
  extending the other library's API. That's an exceptional case.
  More commonly, you just use the library, as `use library;`.

In OpenSCAD2, it's an error for a binding imported by `include`
to conflict with another definition or `include` in the same block.
Overrides are always specified explicitly, they don't happen implicitly.
In the next few sections, we'll discuss several idioms for
explicit overrides using customization and `overlay`.

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
In the original language, the only way to override parameters within an object
is via `include`, and it's not explicit which definitions are overrides.
In OpenSCAD2, customization is a separate operation from inclusion.
For example, you can customize a library you are using
via `use library(name=value);`.
-->

### `only`
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

## Parameter Sets
A set of model parameters can be represented as an object.
This is used by a couple of idioms.

Some authors create scad files containing sets of model parameters.
For example, Nophead's Mendel90 project has `config.scad` which looks, in part, like this:
```
...a long list of default configuration settings...
include <machine.scad> // override defaults for a particular machine
```
Here's my translation of this code into OpenSCAD2:
```
defaults = {
...a long list of default configuration settings...
};
include defaults with script("machine.scad");
```

Some authors represent a parameter set as an array of name/value pairs,
and use `search` to look up a parameter. In OpenSCAD2, a parameter array
can be replaced by an object literal, and you can use `paramset.name`
to look up a parameter. This way, it's also easy to organize parameters into a hierarchy.

### `apply`
`apply(base_object, parameter_set)` customizes the base object
with the specified parameters. It has the same semantics as customization.
Unlike the `overlay` operator, this will report an error if `parameter_set`
contains fields not within `base_object`.

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

## Mixins
In the original language,
it is possible to write an OpenSCAD script
that is not intended to stand alone.
Instead, it is only intended to be `include`d by another script.
These scripts are called *mixins*.
A mixin script may:
* Refer to bindings that it does not define.
  The including script is intended to supply these bindings.
* Override bindings whose default values are set by the including script.

For example,
[`dibond_config.scad`](https://github.com/nophead/Mendel90/blob/master/scad/conf/dibond_config.scad)
in the [Mendel90](https://github.com/nophead/Mendel90) project
is a mixin script that does both of these things.
It's only designed to work when included by
[`config.scad`](https://github.com/nophead/Mendel90/blob/master/scad/conf/config.scad).

What does a mixin script denote?
It doesn't denote an object: that doesn't make sense when some of the fields
depend on undefined bindings.
Instead, a mixin script denotes a mixin value, which contains incomplete, unevaluated code.

In OpenSCAD2, mixins are first class values
that specify a set of customizations and a set of extensions
that can be applied to a base object using the `overlay` operator.
* In their most general form, mixins are constructed using the `mixin` keyword.
  This syntax adds two features missing from mixin scripts in the original language:
  the ability to refer to the base object when overriding a field definition,
  and the ability to declare the fields that the base object must contain
  (and optionally provide default values).
* As a special case, objects can be used as mixins.
  An overlay object can override
  existing fields in the base, and add new fields and geometry.
  See [`overlay` operator](#overlay).

OpenSCAD1 fully supports mixins at the level of script files,
but existing code will trigger warning messages until the syntax is updated:
* To include a script that overrides existing definitions,
  use `overlay <filename>` instead of `include <filename>`.
  Without this, you get warnings about multiply-defined names.
* If a mixin script contains references to bindings that are undefined unless supplied
  by an including script, then it must begin with a `mixin` declaration that lists all
  of the undefined names. Without this, the undefined names produce warnings.

In OpenSCAD2, these warnings become errors.

### OpenSCAD2: Constructing a Mixin
The first statement in a mixin script is a `require` statement,
which lists the mixin's prerequisites. When the script is evaluated,
the result is a mixin, instead of an object.

A `require` statement has the syntax `require (prerequisites);`.
The *prerequisites* is a comma separated list specifying which fields
must be defined by the base object.
A prerequisite is either `id` or `id=value`; in the latter case,
you are suppying a default value.

Following the `require` statement are statements
that override existing bindings,
and add new bindings and geometry.
All pre-existing fields in the base object that are referenced
by the mixin script should be listed in the prerequisites,
otherwise you'll get an error about an undefined name.

To override a field in the base object, you need to use an `override`
definition, which is just a regular definition prefixed with the `override`
keyword. Within the body of an override definition,
the special variable `$original` is bound to the original value in
the base object field that is being overridden.
`$original` allows the new field value to be defined in terms
of the base field value. This is particularly useful
when overriding functions.

### OpenSCAD2: Applying a Mixin
A mixin is applied to a base object using an overlay expression:
`base overlay mixin` returns the derived object.

The `overlay` operator is associative, thus `(obj overlay mixin1) overlay mixin2`
is equivalent to `obj overlay (mixin1 overlay mixin2)`.
Thus you can combine two mixins using `overlay`.

The overlay statement `overlay mixin1;` is a variant of `include`
that applies the mixin to all definitions in the script before
the `overlay` statement.
* `{include Object; overlay Mixin;}` is equivalent to `Object overlay Mixin`.
* `{include Mixin1; overlay Mixin2;}` is equivalent to `Mixin1 overlay Mixin2`.
* When using the statement form, the mixin argument must be a compile time constant,
  whereas the expression form is more general, since it works on run time values.

<!--
### Ordering Constraints on Mixins
Consider this example:
```
2dpoint = {x=0; y=0; r=sqrt(x^2 + y^2);};
pt = 2dpoint(3,4);
echo(pt.r); // ECHO: 5

3dmixin = {require(x,y,r); z=0; r=sqrt(x^2 + y^2 + z^2);};
3dpoint = 2dpoint overlay 3dmixin;
echo(3dpoint); // ECHO: {x=0; y=0; z=0; r=sqrt(x^2 + y^2 + z^2);}
```
Note the ordering of the fields in `3dpoint`.
When a new object is derived by applying a mixin to a base,
the order of definitions in the derived object's script can be important.
In this example, `x`, `y` and `z` must be defined before `r`.
The ordering of names in the prerequisite list
and the ordering of definitions in the body
is used to compute the ordering of definitions in the derived script.
This explains the peculiar ordering requirements for mixin literals.
-->

<!--
## Customization with Self Reference
There's a problem with the `object(args)` customization syntax.
It's not clear that it supports "self reference": can the replacement field definitions
refer to other fields in the object? It looks like a function call, so it appears that the
replacement field expressions are in fact converted to pure values before being plugged in to the object.
* The mixin feature has been carefully designed to support self reference.
* I've claimed that `include object(args)` is the OpenSCAD2 replacement syntax for
  the original OpenSCAD idiom of including a script then overriding some of its definitions.
  The latter syntax *does* support self reference.

So what are the options? Fix/clarify customize, or specify a different replacement syntax?
* Fix/clarify customize.
  * Limit customization so that the field list of the base object is known at compile time.
  * Function call doesn't compile arguments until run time. (That's how it works now, but that's slow.)
  * Use special syntax in the argument list for self reference: eg, `$self`.
* Specify a different replacement syntax.
  * `include object overlay {...};`
  * Or something close to the original syntax:
    <pre>
    include object;
    override x=1;
    </pre>

Another issue. This doesn't work in the current language:
```
include <foo.scad> // defines x and y
a = x;
y = a;
```
You get a message that a is undefined, and y becomes undef.
Does this code work with mixins?
```
mixin(x,y);
a = x;
y = a;
```
According to my design, yes it works. The script of the base object defines x and y, in that order.
This script is rewritten to define x, a, y in that order.

This kind of thing will never work with customization as a function call.
But it could be made to work for traditional 'include and override' syntax.
```
include <foo.scad>
a = x;
override y = a;
```
In this design, you have to override bindings in the same order that they were originally defined.
Either that or I topologically sort the definitions and issue an error in the event of a cycle.

Alternatively, I could just use lazy evaluation.
That means the order in which definitions are written
only determines scoping, it doesn't determine the order in which
the definitions are evaluated.
* The Nix language in NixOS has a similar design.
  Nix doesn't even bother to detect cycles,
  it just goes into an infinite loop, which is also just like Haskell.
* It simplifies the implementation if I don't have to reorder stuff.
  Mixins are simplified since the ordering requirements go away.
* How to echo a customized object?
* The 'echo' command becomes kind of sketchy with lazy evaluation.
  It will get invoked when geometry is evaluated (this is also lazy).

Within an `override` definition,
the special variable `$original`
is bound to the original value from the definition which is being overridden.

### Strengths and Limitations of `overlay`
An object has a dependency chain.
`overlay` supports dependencies in the extension object, preserving those dependencies in the new object.
[Really? Merge didn't do that.]
Topological sort. Paradoxical dependencies cause an error.

Paradox example with original language:
```
-- foo.scad --
x = 1;
y = x+1;
-- bar.scad --
include <foo.scad>
x = y + 1;
```
This will currently produce a warning: undefined variable y.

### Customization with Self Reference

OpenSCAD2 object customization, `object(name1=value1,name2=value2,...)`,
needs to identify self reference within each value<sub>i</sub> expression,
so that it can compile the expressions correctly.
For example, in
```
base = { x = 1; y = x + 2; };
customized = base(y = x + 3);
```
the `x` in `y = x + 3` on the second line is not defined in the lexical environment.
It is a self-reference that can only be resolved using `base`.
This means we need to determine the `public_bindings` map for the base object
at the time that customization expressions are analyzed.

This, in turn, puts restrictions on the kinds of expressions that can be used
for the base object in a customize expression. Alternatively,
* We could compile customize expressions at run time. Not really different from
  the run-time lookup of identifiers that occurs in the current implementation,
  but the current implementation has really slow function calls, and my goal
  is to do better than this.
* We could require self reference to be explicit within the argument list
  of a customize expression. In the previous example, you would literally
  need to type `base(y = $self.x + 3)` in order for self reference to work.
  This gives us a simpler and faster implementation,
  but adds another thing for users to learn.

The `include` statement copies public bindings from the base object,
into the object being constructed. Nothing additional needs to be done about
self references at the time of include.

At run time, when a field of an object
is referenced via `object.field`, the `$self` register is set to the value of object`,
and the code for that field is evaluated. Objects use lazy evaluation. The evaluation of
a field within a particular object happens once, then the result value is cached.

This particular implementation is based on the implementation of inheritance and override
in single-dispatch object oriented languages.
-->
