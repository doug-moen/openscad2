
# Scoping Rules for Scripts

The current scoping rules for scripts are buggy and overly complex.
In OpenSCAD2, we can fix both the bugs and the complexity by switching to a very
simple rule: the scope of a definition within a script is the entire script.

A corolary is that the order of definitions within a script doesn't matter.
This story becomes a bit more complicated when `overlay` statements
are used: see [Object Inheritance](Inheritance.md) for more details.

The order independence of definitions in a script is a subtle change from the original
language, but it is backwards compatible for the case of a script containing only
variable definitions (assignments) and geometry.

We will now do a case analysis to prove backwards compatibility,
and show how this change reduces language complexity and fixes existing language bugs.

## Backwards Compatibility

The backwards compatibility mechanism requires that a script written in the original language
does not change its meaning in OpenSCAD2, if that script does not contain function or module definitions,
`include` or `use` statements.

To demonstrate backward compatibility, we need to consider scripts containing only variable definitions
(aka assignment statements) and geometry statements.

Case 1: Geometry statements may contain forward references to variables.
This works in the original language:
```
cube(x);
x = 10;
```
This script is order independent. Relative to geometry statements,
the scope of a variable definition is the entire script, just as in OpenSCAD2.

There are two cases.

In case 2, the script is a compound statement, and there is an outer
definition with the same name. In this case, the scope of the definition
is again the entire script, which means it is order independent.
This only applies to the new feature added in 2015.03, where compound
statements can now have local variable definitions.
Try this example:
```
X = "outer";
if (true) {
   echo(X=X); // ECHO: "inner"
   Y=X; // Y is set to "inner"
   echo(Y=Y); // ECHO: "inner"
   X = "inner";
}
```

In case 3, the script is either the entire file, or it is a compound statement
where there is no outer definition with the same name.
In this case, variable definitions are order dependent relative to each other in the original
language, but the scripts are once again forward compatible with OpenSCAD2.

## Complexity

In the original language, the scope of a function or module definition
is the entire script. These definitions are already order independent.

The scope of a variable definition (aka assignment statement)
is more complicated. There are two cases.

...

## Bugs

...
