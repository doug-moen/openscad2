# Phased Implemention of OpenSCAD2

## Phase 1: Better Error Reporting
The new Lexer is implemented, which records the position of each token in the source file.
More errors are reported, and each error indicates the position within the source file
where the bad code is located. Ideally, the GUI will highlight the bad token in red.
From the command line, error messages indicate filename:linenumber:column of the bad code.

## Phase 2: Minimum Viable Product for First Class Functions
How small a subset of the new language do we need to support in order to get first class functions?

My initial thought is that the unified namespace is required.
This means new syntax:
* function literals
* new function definitions: `f(x) = x + 1`
* `use object;` and `include object;`
* `script("filename")`

We'd have to support modules in the unified namespace.
That seems to imply first class shape values, objects, and other changes,
so that the new syntax for defining functions that behave like modules actually works.

An alternative is to introduce temporary scaffolding.
A temporary syntax for module values, which remain distinct from functions.
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

  
