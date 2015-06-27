# Phased Implemention of OpenSCAD2

## Phase 1: Better Error Reporting
The new Lexer is implemented, which records the position of each token in the source file.
More errors are reported, and each error indicates the position within the source file
where the bad code is located. Ideally, the GUI will highlight the bad token in red.
From the command line, error messages indicate filename:linenumber:column of the bad code.

## Phase 2: Overrides and Mixins
The new Parser and Semantic Analyzer are implemented.
The `include <file>` statement reads the file, analyzes it, issues warnings and errors,
before the contents are interpolated into the including script.
Mixin script files, `override` and `overlay <file>` are implemented.
Lazy evaluation of objects eliminates some problems and bugs related to the ordering of
definitions when a definition is overridden.
This is still an "OpenSCAD1" with 3 namespaces, and there are no object or mixin values,
but much of the groundwork
required for the single namespace is now in place.

## Phase 3: First Class Functions
A minimal subset of the new language that supports first class functions.
* unified namespace
* values, functions and module names all belong to the same namespace
* shapes, groups, objects, mixins are not first class values yet
* modules are not yet unified with functions

The unified namespace requires the new definition syntax:
* function literals
* new function definitions: `f(x) = x + 1`
* module literals, which are a transitional syntax: `module(parameters)statement`
* `script("filename")`, an object/mixin expression (doesn't return a value)
* `use object;` and `include object;` and `overlay object;`

Transitional syntax for module values, which remain distinct from functions.
A module literal is only legal in one context, in a definition:
```
box = module(x,y,z) cube([x,y,z]);
```
The body of a module is exactly as before, with `children()` etc.

This temporary module syntax delays a lot of changes.
There are no object literals.

There will be two languages, OpenSCAD1 and OpenSCAD2,
with 3 namespaces and 1 namespace respectively.

Suppose I place no restrictions on using the new syntax in OpenSCAD1 scripts.
Then what happens? Things get messy.
* New function definition syntax places the function `f` in the variable namespace?
  Or it creates an OpenSCAD2 Field in the public_bindings map of the object,
  which puts the definition in all namespaces?
  * The former means `f(x)` won't work, as `f` is not found.
    Although `(f)(x)` would work.
  * The latter allows `f(x)` to work,
    but makes `f(x)=x;` different from `f=function(x)x;`.
    Unless the use of OpenSCAD2 syntax in the right side of a definition
    changes the binding to use the single namespace.

## Phase 4: First Class Script Files
* `script(filename)` now returns a value (an object or mixin)
* but `{script}` is not an object literal yet
* dot notation for objects
* `only(id1,id2,...) object`

## Phase 5: First Class Geometry
Now, everything is a first class value.
* shapes are values
* groups are unified with objects
* `{script}` is an object literal
* modules are unified with functions
