# Implementation

OpenSCAD2 has a somewhat different implementation than OpenSCAD1.
The main difference is the addition of new stages to the translator,
which are the Analyzer and Coder.
Also, the data transmitted between each stage has changed.
```
Lexer
--tokens--> Parser
            --parse-tree--> Analyzer
                            --AST--> Upgrade Tool
                            --AST--> Coder
                                     --code--> Evaluator
                                               --csg-tree--> Preview
                                               --csg-tree--> Render
```

## Lexer
The Lexer produces a stream of tokens, as before.
Changes:
* The implementation of `include`.
  Previously, the Lexer interpolated the contents of the included file
  into the token stream. Now included scripts are not opened until the Analyzer stage.
* Every token has the preceding white space attached to it.
  The EOF token contains the final trailing whitespace.
  The token stream now contains enough information to exactly reproduce the original source text.
  This is used by the [syntax upgrade tool](Backwards_Compatibility.md#upgrade-tool).

Consider that each token contains its position in the source file
(used when generating error messages), and that the token stream contains the
full source code.
Given this, the fastest and most space efficient implementation
is to read the entire script into a contiguous array of characters,
then tokenize this character array. Each token value contains 32 bit offsets
into the array (instead of 64 bit pointers), recording its position and preceding white space.
This will be faster and more compact than dynamically allocating and copying
a std::string for each white space sequence.

## Parser
The Parser is still written in Bison, but the grammar is a complete rewrite.
The grammar is somewhat vaguer than before. For example, we previously encoded
the syntax of list comprehensions in the grammar. Now, list comprehensions are just
expressions, and syntactic restrictions on where `for` can occur are now enforced
by the Analyzer.

The output is a parse tree which is no longer intended to be executed, but which
is instead fed to the analyzer. The parse tree now contains all of the original tokens from the token stream,
so it can be used by the upgrade tool to reproduce the original source text.

## Analyzer
The Semantic Analyzer performs semantic analysis of the parse tree,
figures out the meaning of the program, and annotates the parse tree,
producing an AST, or annotated syntax tree.

The Analyzer is responsible for enforcing context sensitive syntax restrictions,
issuing syntax errors when these are violated. Some of the work of enforcing the
syntax that used to be done by the Bison parser, is now done by the analyzer.

Phase 1: The Analyzer performs a global analysis on the script to determine if it
is OpenSCAD1 (3 namespaces) or OpenSCAD2 (1 namespace), and annotates the
parse tree according to whether we are using backward compatibility mode
or OpenSCAD2 runtime semantics.

Phase 2:
The Analyzer looks up all identifiers and determines which definition binds them,
and reports errors about undefined or multiply defined names.
It implements the `include` and `use` operators, opening the referenced script
file and analyzing them to determine which bindings are imported.

The AST produced by the analyzer is used by the upgrade tool to upgrade a script
to OpenSCAD2 syntax and output the modified source file.

## Object Implementation
OpenSCAD scripts and `{...}` object literals are compiled into Object ASTs.

An Object AST consists of:
* `geometry`: a list of ASTs, one for each geometry statement
* `public_bindings`: a map from identifiers to fields, which is populated from definitions and `include` statements
* `use_bindings`: another map from identifiers to fields, which is populated from `use` statements
* `parent_scope`. When resolving an identifier during semantic analysis,
  the search order is `public_bindings`, then `use_bindings`, then `parent_scope`.

While building the object,
* In the object that results from reading a pure OpenSCAD1 script,
  each field contains up to 3 value ASTs, corresponding to the variable, function and module namespaces.
* In the object that results from reading a pure OpenSCAD2 script,
  each field contains a single value AST.
* If an OpenSCAD1 script includes an OpenSCAD2 script, or vice versa,
  then we are building a hybrid object where some of the fields are OpenSCAD1 style,
  and some are OpenSCAD2 style.
* If an OpenSCAD1 script references a field, it specifies whether it is fetching from
  the variable, function or module namespace. If the field is actually an OpenSCAD2 field,
  then we ignore the namespace specifier, and the lookup succeeds. The value might have the
  wrong type, in which case there could be an error reported during evaluation.
* If an OpenSCAD2 script references an OpenSCAD1 field,
  then a compile time error occurs if the field has more than one value AST.

### Self Reference

When an expression on the right side of a definition is compiled,
the semantic analyzer has special treatment for identifiers within that
expression that reference other fields in the same object. Eg, in
```
{ x = 1; y = x + 2; }
```
the expression for `y` is `x + 2`, which contains `x`,
which is a reference to another field in the same object.
These are called "self references", and they are compiled as indirections
through the `$self` register in the virtual machine. For example, the above object
is compiled as
```
{ x = 1; y = $self.x + 2; }
```

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

## Coder

The Coder or Code Generator takes the AST and generates executable
code for the Evaluator. It figures out the run time data structures
needed to represent local and global variables, and converts bound
identifiers into indexes into the appropriate run time environment table.
The output is an executable code tree.

It would be awesome to use LLVM as the code generator.
Not sure about the effort required.

## Evaluator
The input of the evaluator is different from before.
It's no longer a raw parse tree straight out of Bison,
but instead is an executable code tree generated by the Coder.

The output of the evaluator is the CSG tree, but it
is now represented as an Object Value.

OpenSCAD1 uses a form of lazy evaluation for module calls.
If the child argument of a module contains `echo` calls,
but `children` isn't referenced, then the `echo`s will not be executed.

For performance reasons,
the new evaluator will also use lazy evaluation, at least for object literals
and object customization. The new language encourages you to use object
customization freely, and I want to minimize the cost of this.
