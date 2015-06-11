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

The scope of a binding begins at the following statement
(for a script), or at the following definition (in a `let` bound definition list)
or at the following formal parameter (for a function literal),
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
  (the `using` command) to import only the names you actually want from one of the libraries.
* You have `use`d a library script and imported a name X which you have also defined locally.
  Let's assume this is an accident, and that you did not intend to modify the internal workings
  of the library by replacing its internal implementation of X with your X.
  In that case, use selective import (`using`) to only import the names that you want
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
   Once again, you need to use the syntax for explicitly customizing an object.
   ```
   include script("defaults.scad")(include script("overrides.scad"));
   ...
   ```
