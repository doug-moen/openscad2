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
In order to make this work, OpenSCAD2 has a single namespace for all named values.

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
which implies that `x` is a mutable variable that can later be assigned a different value.
This is misleading terminology, and `x` is not really a variable in the imperative
language sense.
[OpenSCAD1 is actually a functional language.](Declarative_Semantics.md)

In OpenSCAD2, there is a single unified definition syntax.
Within a script,
```
name = expression;
```
is a definition that binds `name` to the value denoted by `expression`.
This means that `name` can be substituted for `expression`,
or vice versa, anywhere in the scope of the definition,
without changing the meaning of the program.

We call `name` a named value, or a binding.

As a special case, you can abbreviate
```
hypot = function(x,y) sqrt(x^2 + y^2);
```
as
```
hypot(x,y) = sqrt(x^2 + y^2);
```
The two definition syntaxes are entirely equivalent,
and the abbreviation is allowed wherever `name=expr` is legal,
including in function calls.

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
OpenSCAD2 uses simple, consistent scoping rules that apply
uniformly to all definitions and bindings.

The scope of a definition begins at the following statement
(or at the following definition in a `let` bound definition list),
and continues to the end of the script or `let` expression.
As a special case, forward references are legal within function or
module bodies: this makes recursive definitions possible.

Scopes are nested. Definitions in an inner scope
shadow or hide bindings inherited from an outer scope.
* The outermost scope is the *global* scope,
  which contains all of the built-in bindings,
  such as `true`, `cos`, and `cube`.
* Inside of that is the file-level scope for each *.scad script file.
* An object literal (syntax: `{script}`) introduces a nested scope.
* A `let` construct introduces a nested scope.
* A `function` or `module` introduces a nested scope which contains
  the formal parameters.

To preserve lexical scoping, the `include` operator has a new implementation
in OpenSCAD2. It no longer performs a textual substitution, similar to `#include` in C.
Instead, the referenced script is separately compiled,
and then its top level definitions are imported
into the scope of the including script. This means that definitions in the including
script are not visible to the code in the script being included.

In OpenSCAD1, this mixing together of the definitions from the includer and the includee
causes unpredictable behaviour and chaos, as discussed in several forum posts.
However, this feature has also been deliberately used to allow the includer to override
parameters in the includee. OpenSCAD2 provides a safe, lexically scoped mechanism for
overriding definitions in an included script, [as discussed here](Objects.md).

## Missing and Multiple Definitions
In OpenSCAD2 it is illegal to define the same name twice within the same scope.
You get a duplicate definition error. (I assume this is a safe change: probably no
existing scripts depend on this.)

It is also illegal to refer to a name that isn't defined.
That also produces an error message. (This is more likely to cause problems
with existing scripts.)
