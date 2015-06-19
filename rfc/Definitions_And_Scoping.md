# Definitions and Scoping

## Unified Namespace
In OpenSCAD1, there are 3 separate namespaces, for variables, functions and modules.
This means you can use the same name for a variable and a function, for example,
and there will be no conflict. But this same feature prevents us from passing
functions as arguments to functions or modules, which gets in the way of
implementing new features like generalized extrusion, where functions are used
to define 3D shapes.

In OpenSCAD2, [everything is a first class value](First_Class_Values.md),
including functions and modules.
Anything can be passed as an argument to a function or returned as a result.
In order to make this work, OpenSCAD2 has a single namespace.

This creates a backward compatibility problem, which is resolved by
"backward compatibility mode" for OpenSCAD1 scripts.
See [Backward Compatibility](Backward_Compatibility.md) for details.

## Unified Definition Syntax
In OpenSCAD1, there are 3 different definition syntaxes, corresponding to
the 3 different namespaces:
* `name = expr;` defines a variable, in the variable namespace.
* `function name(parameters) = expr;` defines a function, in the function namespace.
* `module name(parameters) statement` defines a module, in the module namespace.

Note that OpenSCAD1 calls `x = 5;` an *assignment statement*,
which implies that `x` is a mutable variable of the kind found
in imperative programming languages.
That's not the case;
[OpenSCAD1 is actually a functional language](Declarative_Semantics.md).
To avoid confusion, OpenSCAD2 uses the term *definition* instead.

In OpenSCAD2, there is a single unified definition syntax.
Within a script,
```
name = expression;
```
is a definition that binds `name` to the value denoted by `expression`.
This means that `name` can be substituted for `expression`,
or vice versa, anywhere in the scope of the definition,
without changing the meaning of the program.

As a special case, you can abbreviate a definition whose right side is
a [function literal](Functions.md#function-literals)
```
hypot = function(x,y) sqrt(x^2 + y^2);
```
as
```
hypot(x,y) = sqrt(x^2 + y^2);
```
The two definition syntaxes are entirely equivalent,
and the abbreviation is allowed wherever `name=expr` is legal,
including in function calls
and in `-D` command line arguments.

Another way to specify a set of local definitions
is using `let`. This syntax is valid in both expressions and statements.
```
let (definitions) expression
let (definitions) statement
```
where `definitions` is a comma separated list of definitions.
For example,
```
let (a = 2, f(x) = x + 1) f(a)
```
is an expression that returns `3`.

## Lexical Scoping
OpenSCAD2 is a block structured, lexically scoped language
with simple, consistent scoping rules that apply
uniformly to all bindings.

A block is a syntactic construct that binds identifiers to values,
and delimits the scope of those bindings. Lexical scoping means
that a binding is not visible outside of its block.
* An [object literal](Objects.md#object-literals)
  `{script}` is a block.
  Within the script, definitions bind identifiers to values.
* An OpenSCAD script file is a block.
  It's a special case of an object literal:
  top level definitions bind identifers to values,
  and there is no need for brace brackets to delimit the script.
* A `let` construct is a block.
  The syntax is `let (definitions) expression`
  or `let (definitions) statement`.
  The parenthesized list of definitions bind identifiers to values.
* A function literal is a block.
  The formal parameters are the identifiers
  that are bound to values by a function call.
* The parenthesized argument list in a function call is a block.
  Each labeled argument behaves like a definition.

The scope of a binding begins at the following statement
(for a script), or at the following definition (in a `let` bound definition list)
or at the following formal parameter (for a function literal),
or at the following argument (for a function call argument list),
and continues to the end of the block.
As a special case, forward references are legal within nested function or
module bodies: this makes recursive definitions possible.

Scopes are nested. Bindings in an inner scope
shadow or hide bindings inherited from an outer scope.
* The outermost scope is the *global* scope,
  which contains all of the built-in bindings,
  such as `true`, `cos`, and `cube`.
* Inside of that is the file-level scope for each *.scad script file.
* Inside of that are the object literals, let constructs, and function literals
  contained in the script file.

It is illegal to refer to a name that isn't defined.

It is illegal to define the same name twice within the same scope:
you get a duplicate definition error.

## Effects of New Scoping Rules
OpenSCAD 2015.03 already implements the "simple, consistent lexical scoping" rules
if you just consider scripts with variable definitions, with no duplicate
definitions, no function or module definitions, no `use` or `include` statements.

In the new implementation, OpenSCAD1 will be tweaked to
obey the scoping rules more fully, which will make the language
more predictable and consistent, but will have little impact on backward compatibility.

The new definitional syntax in OpenSCAD2 will fully obey these rules.

### on Undefined Bindings
OpenSCAD1 already gives warnings about undefined bindings:
* WARNING: Ignoring unknown variable 'x'.
* WARNING: Ignoring unknown function 'f'.
* WARNING: Ignoring unknown module 'm'.

The new implementation of OpenSCAD will promote these warnings to errors
in both OpenSCAD1 and OpenSCAD2 modes.

This will remove a source of confusion from the language.
The [user manual entry about `include`](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Include_Statement)
explains how, when overriding a variable in an included script,
you must sometimes put the override *before* the include, and sometimes put it *after* the include.
(Search for "j=4" in the linked document.)

This makes the `include` statement more confusing than necessary,
but the necessity to put the override before the include
only happens if the variable being overridden is referenced but not defined
in the script being included. The new implementation will make this situation an error.

### on Duplicate Definitions
The current OpenSCAD implementation makes this legal:
```
x=1;
echo(x);  // ECHO: 17
x=17;
echo(x);  // ECHO: 17
```
The behaviour is quite confusing for new users.
The [user manual section on Variables](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/General)
contains a lengthy example script which explains this behaviour.
<!-- As a new user, my initial reaction was stunned disbelief. -->

In the new implementation,
this code will cause a compile time error
in both OpenSCAD1 and OpenSCAD2 mode.

Duplicate definitions are not a feature,
they are a side effect of the mechanism for overriding parameter settings
in an included script. The latter is important and will continue to work.

### on Function and Module Definitions
In OpenSCAD1, the scope of a function or module definition
is the entire block in which it occurs. For example, this is legal:
```
echo(f(1));
y = 17;
function f(x) = x+y;
```
This kind of code isn't compatible with the "sequential scoping, sequential evaluation"
mental model that I want for OpenSCAD2. It's also not compatible with
functions being ordinary values and function bindings being no different from other bindings

We won't change this behaviour in OpenSCAD1,
but the equivalent OpenSCAD2 code will give an error for the first line: "f is not defined".

### on `use <F>`
Currently, `use <F>` is only legal at the top level of a script file.
In the new implementation, it will be legal in any subscript, the same as `include <F>`.

Currently, `use <F>` violates the scoping rules.
F is placed last in the search order, after the script file itself, and *after* the global bindings.
If a new release of OpenSCAD adds new functions and modules,
these will shadow functions or modules imported from `use`d library scripts,
which is a problem (adding new builtins could break existing code).
It's also a violating of the scoping rules, which state that the global scope
is outside of all other scopes.
In the new implementation,
bindings imported into a block by `use` are searched
*before* the parent scope is searched.

<!--
In the new implementation, `use <F>` adds bindings
of all the functions and modules in F to the current object.
And this fixes the scoping rule violation.
If a search of the file level scope for a function or module fails
(this scope now includes the bindings imported by `use`),
then we proceed to the next enclosing scope, which is the global scope.

The bindings added by `use <F>` to the object
do not conflict with explicit definitions of the same name and type:
the explicit definition silently overrides the binding imported by `use`.
-->

The current implementation is silent if two bindings with the same name and type are imported by `use`
from different libraries. This could mask bugs.
In the new implementation, OpenSCAD1 will report a warning (so existing code won't break)
and OpenSCAD2 will report an error.

Are bindings added to an object by `use` externally accessible?
* As named fields? No. Use `include` if you want this behaviour.
* If you `use` the object? No.
  The rationale is, if library B uses library A, then B has access to A's bindings,
  but does not export A's API. If library B wants to export A's API,
  then it should include A.
* Can these bindings be overridden by customization?
  Yes. A use case is MCAD/bearing.scad, which references `epsilon` from units.scad,
  which defines `epsilon=0.01`. `epsilon` should be considered
  an overrideable parameter, with 0.01 as its default value.
  Any script that uses units.scad and directly references epsilon,
  should allow epsilon to be overridden by customization.
* If you include the object, all bindings are copied from the included object
  into the current object, and this includes bindings created by `use`,
  which preserve their properties: they can be overridden, but are not exported
  as named fields or via `use`.

See [Library Scripts](Library_Scripts.md) for more information about `use` in OpenSCAD2.

### on `include <F>`
The current implementation of `include <F>` works by textually
substituting the contents of file F into the input stream at a low level.

This won't work for the new implementation, since OpenSCAD1 scripts
can include OpenSCAD2 scripts, whereas you can't meaningfully mix the
old and new definition syntax in a single file
(since `f(x)` is interpreted differently in OpenSCAD1 vs OpenSCAD2 mode).

In the new implementation, `include <F>` will read file F and compile it
into an object O. Once the current script is analyzed, a second pass will
find all the definitions in the block containing `include <F>` that
override definitions within F, and use these definitions to customize the
object O. The customized object O is then what's imported.

This is a different implementation with basically the same semantics.
Where the semantics differ are in the direction of improved lexical scoping.

#### Implicit vs Explicit Overrides
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

#### Clarifying the scope of overrides
Code that doesn't work in 2015.03:
```
include <foo> // has parameters 'x' and 'y'
x = 1; // override x
a = x + 1;
y = a + 1; // override y. y is undef
```
This code will emit a "WARNING: unknown variable a",
but then it will run and set y to undef.
(This problem has been discussed in the forum.
Google this: "The last value assigned to j is 4 and indeed the echo shows that, so why is k assigned undef? Seems like a bug in OpenScad".)

This code is wrong because it involves a scoping violation,
and it reports a compile error in the new implementation.
Users won't have to wonder why `y` is `undef` because we won't evaluate the program.

It becomes more obvious why this code is wrong if you
translate it into an OpenSCAD2 customized include:
```
include script("foo")(
    x=1,
    y=a+1);
a = x + 1;
```

#### Improved Lexical Scoping

## Include
The `include` operator has changed in OpenSCAD2 to support lexical scoping.

In OpenSCAD1, `include <F>` works by textually including the specified file F.
Let's say this is done at the "top level" of a script S.
Then top level definitions of S are mixed together with top level definitions from F.
For example, if script S happens to define
```
/* return vertex list for i'th tan from the game of tangrams */
function tan(i) = ...;
```
for its own reasons, and script F happens to call `tan`, expecting to get the builtin tangent function, then F will instead get S's version of `tan`.

By contrast, OpenSCAD2 is lexically scoped. Within script S, the scope of `tan` is restricted
to the script itself; it doesn't bleed into other scripts that it includes.
To implement this, the included script F is separately compiled
and global names that it references are resolved independent of any script that happens to include it.

In OpenSCAD1, this mixing together of the definitions from the includer and the includee
causes unpredictable behaviour and chaos, as discussed in several forum posts.
However, this feature is also deliberately used to allow the includer to override
parameters in the includee. OpenSCAD2 provides a safe, lexically scoped mechanism for
overriding definitions in an included script, [as discussed here](Objects.md).

## Dynamic Scoping
OpenSCAD1 supports dynamic scoping in function and module calls.

Officially, there are a few documented special variables beginning with `$`
that have dynamic scope, like `$fn`.

Unofficially, you can pass a labelled argument with any name you want, and it will be
bound as a local variable in the body of the function or module,
shadowing a global variable of the same name.
This is not a feature, it is an undocumented artifact of the current implementation.
Marius has asked users who have discovered this not to rely on it.

In OpenSCAD2, I don't currently plan to support dynamic binding at all,
even in backwards compatibility mode, except for those cases where it is documented to work
(`$fn` et al).
In OpenSCAD2, you will get an error message if you pass a labeled argument to a function
that doesn't declare that label in its formal parameter list. This is a feature:
passing bad arguments to a function is a common bug, and it's really helpful to
get an error message so you can fix the bug.

If your code happens to be relying on the undocumented form of dynamic binding, then there may be
an alternate idiom that you can use in OpenSCAD2 to get the same effect.
Let's suppose that you are doing this to override a global variable X defined within a library script S.
You are overriding the value of X in a call to module M.
Your current code:
```
include <S.scad>
M(X=42);
```
In OpenSCAD2, you can get the same effect by customizing the script at the point of the module call.
```
S = script("S.scad");
S(X=42).M();
```

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
