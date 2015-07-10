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

The [backward compatibility mechanism](Backwards_Compatibility.md)
imposes a significant constraint on these scoping rules.
An OpenSCAD script written in the original language,
with no function or module definitions, and no `include` or `use` statements,
must not change its meaning when interpreted as OpenSCAD2.

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

For a script, the scope of a binding is the entire script:
see [Scoping Rules for Scripts](Scoping_For_Scripts.md).

Otherwise, the scope of a binding begins at the following definition (in a `let` bound definition list),
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
These are changes from the original language,
and there is more discussion in [Object Inheritance](Inheritance.md).

## Effects of New Scoping Rules
OpenSCAD 2015.03 already implements the "simple, consistent lexical scoping" rules
if you just consider scripts with variable definitions, with no duplicate
definitions, no function or module definitions, no `use` or `include` statements,
and no geometry.

In the new implementation, OpenSCAD1 will be tweaked to
obey the scoping rules more fully, which will make the language
more predictable and consistent, but will have little impact on backward compatibility.

The new definitional syntax in OpenSCAD2 will fully obey these rules.

### on Geometry
In the current language,
```
cube(x);
x = 10;
```
is legal. That violates the scoping rules,
since `cube(x);` contains a forward reference to `x`.

So based on what I've said above and elsewhere,
this code needs to work in OpenSCAD1,
but the upgrade tool will rearrange the code to
```
x = 10;
cube(x);
```
so that it will work in OpenSCAD2.

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

### on `use`
Currently, `use <F>` is only legal at the top level of a script file.
In the new implementation, it will also be legal in object literals, the same as `include <F>`.

Currently, `use <F>` violates the scoping rules.
F is placed last in the search order, after the script file itself, and *after* the global bindings.
If a new release of OpenSCAD adds new functions and modules,
these will shadow functions or modules imported from `use`d library scripts,
which is a problem (adding new builtins could break existing code).
It's also a violating of the scoping rules, which state that the global scope
is outside of all other scopes.
In the new implementation,
bindings imported into a block by `use` are searched
after the bindings created by definitions and `include`,
but *before* the parent scope is searched.

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

The bindings added to an object by `use` are not externally visible.
They aren't visible as named fields, they can't be customized,
they are invisible to clients that `use` or `include` the object.

The current implementation is silent if two bindings with the same name and type are imported by `use`
from different libraries. This could mask bugs.
In the new implementation, OpenSCAD1 will report a warning (so existing code won't break)
and OpenSCAD2 will report an error.

<!--
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
-->

See [Library Scripts](Library_Scripts.md) for more information about `use` in OpenSCAD2.

### on `include`

In the new implementation, the argument to `include` is compiled into an object,
and then each binding is imported into the block.
The imported bindings carry with them their lexical environment (the parent scope).
In short, `include` supports lexical scoping,
which the current implementation does not, since it works by pure text substitution.

[More information about `include` in OpenSCAD2.](Inheritance.md)

<!--
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
overriding definitions in an included script, [as discussed here](Inheritance.md).
-->

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
