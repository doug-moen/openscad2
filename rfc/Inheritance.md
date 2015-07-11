# Object Inheritance

OpenSCAD2 supports "object inheritance":
deriving a new object from an existing base object,
by overriding some fields and adding new fields.
This is an advanced feature that most users will not need.
However, it is required for backwards compatibility.

The original language supports "script inheritance" by composing the `include`
statement with the ability to override definitions. These are low level features
that result in unexpected behaviour that is difficult to understand,
as can be seen in the wiki and in some forum posts.
These features are also buggy.

OpenSCAD2 takes a higher level approach, encapsulating each idiom combining `include`
and override as a high level feature with better semantics, a clearer mental model,
and better error messages if you mess up.

## The Problem
OpenSCAD has some features that cause great confusion for new users of the language.
* A name can be defined twice within the same block. The second definition
  overrides the first. The resulting behaviour is very strange.
* A reference to an undefined binding generates a warning, but not an error.
  The binding evaluates to `undef`, and then unexpected behaviour can follow.

### Duplicate Definitions
This is legal in the original language:
```
x=1;
echo(x);  // ECHO: 17
x=17;
echo(x);  // ECHO: 17
```
With its C-like syntax, OpenSCAD tricks the new user into thinking that the language
supports re-assignable variables, and it almost seems to work, but something isn't
right here...

In OpenSCAD2, this program is an error: duplicate definitions.

This "override" feature in the original language is useful, but only when
combined with `include`.
* You write a script that defines some parameters with default values,
  then includes a second script which overrides some of these parameters
  and defines new parameters.
* You include a script (eg, a reusable library or model script),
  then override some of that script's top level definitions.

These idioms are supported in OpenSCAD2 by new features that make the override semantics
explicit.

### Undefined Bindings
OpenSCAD1 gives warnings (but not errors) about undefined bindings:
* WARNING: Ignoring unknown variable 'x'.
* WARNING: Ignoring unknown function 'f'.
* WARNING: Ignoring unknown module 'm'.

The fact that the script is still executed when there are undefined bindings
is a source of confusion and forum posts, as some people try to understand the
resulting behaviour. For example, the
[user manual entry about `include`](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Include_Statement)
explains how, when overriding a variable in an included script,
you must sometimes put the override *before* the include,
and sometimes put it *after* the include.
(Search for "j=4" in the linked document.)
In fact, the necessity to put the override before the include
only happens if the variable being overridden is referenced but not defined
in the script being included.

The new implementation of OpenSCAD will promote these warnings to errors
in both OpenSCAD1 and OpenSCAD2 modes.

There are situations where it makes sense for a script to reference
names that it doesn't define. Such a script is not intended to stand alone.
Instead, it is only intended to be `include`d by another script, which supplies
the missing bindings.
These scripts are called *mixins*. In OpenSCAD2, they are identified by
special syntax which make explicit the missing bindings required by the script.

### A Bug, Fixed by Lazy Evaluation
OpenSCAD 2015.03 has a bug related to `include` and override.
```
include <foo> // has parameters 'x' and 'y'
x = 1; // override x
a = x + 1;
y = a + 1; // override y.
```
This code will emit a "WARNING: unknown variable a",
then it will run and set y to undef.
(This problem has been discussed in the forum.
Google this: "The last value assigned to j is 4 and indeed the echo shows that,
so why is k assigned undef? Seems like a bug in OpenScad".)

The key to fixing this bug is to understand that OpenSCAD is a declarative language
(not an imperative one), that `id=expr;` is a definition (with no side effects),
not an assignment statement, and that therefore,
definitions do not need to be evaluated in the same order they are written.

The bug can be fixed in two ways:
* To reorder definitions into an order where each value is computed before it is needed,
  using a topological sort on the dependencies of each definition.
  This happens at compile time.
* To use lazy evaluation: definitions are not evaluated until the first time their
  value is needed, and then the result is cached.
  This happens at run time, and is more powerful, since it is guaranteed to find
  an evaluation order, if it exists, even if it is data dependent.

My current plan is to use lazy evaluation for evaluating scripts.

## Include and Overlay

The `include` and `overlay` operators
provide general support for object inheritance:
the ability to derive a new object from an existing base object
by overriding existing fields and adding new fields.
This is analogous to inheritance in a class-based object oriented language.

This is in constrast to [customization](Objects.md#customization),
which uses the syntax
`object(name1=value1, name2=value2, ...)`
to override object parameters with new values.
Customization is a more limited operation
that is analogous to invoking a constructor in a class-based OOP language.
  
Two things you can't do with customization,
that you can do with `include` and `overlay`:
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
is limited by the fact that the extension object cannot access
fields in the base object. This limitation is overcome
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
  Just as definitions within a script are order independent,
  the location and order of `include` statements is not important.
* The `overlay` statement takes either an object or a [mixin](#mixins) argument,
  and allows new bindings imported from the object or mixin
  to override earlier bindings of the same name.
  The script<br>
  `{..; overlay M1; ..; overlay M2; ..;}`<br>
  is equivalent to<br>
  `{..; ..; ..;} overlay M1 overlay M2`.

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

In OpenSCAD2, the scope of an override must be made explicit.
You must specify which included script is being overridden.

Normally, customization is all you need:
```
include script("MCAD/bearing.scad")(epsilon=0.02);
```
In more complex cases, you might need to use `overlay` to customize the included script.
Eg,
```
include script("foo.scad") overlay {
  ...multiple override definitions that depend on each other...
};
```

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

<!--
OpenSCAD1 fully supports mixins at the level of script files,
but existing code will trigger warning messages until the syntax is updated:
* To include a script that overrides existing definitions,
  use `overlay <filename>` instead of `include <filename>`.
  Without this, you get warnings about multiply-defined names.
* If a mixin script contains references to bindings that are undefined unless supplied
  by an including script, then it must begin with a `mixin` declaration that lists all
  of the undefined names. Without this, the undefined names produce warnings.

In OpenSCAD2, these warnings become errors.
-->

### Constructing a Mixin
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

### Applying a Mixin
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

<!--
## Missing and Multiple Definitions
In OpenSCAD2 it is illegal to define the same name twice within the same scope:
you get a duplicate definition error.
It is also illegal to refer to a name that isn't defined.

The purpose of these errors is to make you aware that something funny is going on
in your code, so that you can fix any problems.

This creates a backward compatibility issue.
There is existing OpenSCAD1 code that won't work when these restrictions are enforced.
This code is expected to work okay in backward compatibility mode, but after
upgrading the code to OpenSCAD2 syntax, the code will need to be changed.

If there are missing definitions, the problem should be easy to fix: just define the missing bindings.
Eg, just write `x=undef;` to eliminate an "x is not defined" error message.

Duplicate definitions can happen by accident.
* You have `used`d or `include`d two different library scripts that define the same name X,
  and you never noticed the conflict. This is dangerous: the last definition of X wins,
  and the first library is forced to use the second library's definition of X,
  which probably breaks the first library.
  To fix this problem, use selective import
  (`use only (names) library`) to import only the names you actually want from one of the libraries.
* You have `use`d a library script and imported a name X which you have also defined locally.
  Let's assume this is an accident, and that you did not intend to modify the internal workings
  of the library by replacing its internal implementation of X with your X.
  In that case, use selective import (`use only`) to only import the names that you want
  from the library.

There are existing idioms that rely on duplicate definitions.
If your code uses these idioms, you'll have to change it to use new idioms.
You can override definitions in OpenSCAD2, but it can't happen accidently,
it has to be done explicitly using customization syntax: `object(overrides)`.

1. You have `include`d a script S that defines X,
   and you have defined your own version of X.
   ```
   include <S.scad>
   X = 42;
   ```
   Your intent is to customize the behaviour of S
   by overriding its definition of X with your own.
   In OpenSCAD2, you have to explicitly customize S
   using `S(X=42)`,
   and then `include` the resulting object.
   ```
   include script("S.scad")(X = 42);
   ```

2. You `include` a script containing default parameter settings,
   then you `include` another script containing project-specific overrides.
   This is followed by code that uses the resulting settings.
   ```
   include <defaults.scad>
   include <overrides.scad>
   ...
   ```
   This is translated into OpenSCAD2 using the merge operator.
   ```
   include merge(script("defaults.scad"), script("overrides.scad"));
   ...
   ```

The new definitional syntax in OpenSCAD2 will fully obey these rules.



## Implicit vs Explicit Overrides
In the new implementation, the main difference between `include`
in OpenSCAD1 vs OpenSCAD2 are implicit vs explicit overrides.
In OpenSCAD1, you can override definitions in an included file like this:
```
include <MCAD/gridbeam.scad>
beam_is_hollow = 1; // override
```
In OpenSCAD2, overrides are explicit.
Overrides are specified by customizing the object before including it:
```
include script("MCAD/gridbeam.scad")(
    beam_is_hollow = 1);
```
In short, the scope of override definitions is made explicit,
and that's an improvement in our scoping rules.
-->
