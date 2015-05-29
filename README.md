# Better abstraction mechanisms for OpenSCAD
OpenSCAD2 is a backward compatible redesign of the [OpenSCAD](http://openscad.org/) language.
The goals are:
 1. to make OpenSCAD easier to use;
 2. to make OpenSCAD more expressive and powerful, not by adding complexity and piling on features, but by making the core language simpler and more uniform, and by removing restrictions on how language elements can be composed together to create larger components.

**Summary**: Everything is now a first class value. Functions, modules, shapes, groups and even OpenSCAD scripts are first class values.

**Why Is This So Big?** Making everything first class while retaining backward compatibility is a hard design problem: everything depends on everything else. It's important to map out all of the required changes in advance, before we start implementation.

## RFC documents
The design documentation is structured as a collection of RFCs.
To comment on an RFC, click on [Issues](//github.com/doug-moen/openscad2/issues)
in the sidebar, and either create a new issue with the same name as the RFC, or find the existing issue.
* [Ease Of Use](rfc/Ease_Of_Use.md)
* [Declarative Semantics](rfc/Declarative_Semantics.md)
* [Composable Building Blocks](rfc/Composable_Building_Blocks.md)
* [First Class Values](rfc/First_Class_Values.md)
* [Definitions And Scoping](rfc/Definitions_And_Scoping.md)
* [Simple Values](rfc/Simple_Values.md): Booleans, Numbers, Strings
* [Generic Sequences](rfc/Sequences.md):
    [Strings](rfc/Sequences.md#strings),
    [Ranges](rfc/Sequences.md#ranges),
    [Slice Notation](rfc/Sequences.md#slice-notation),
    [Objects](rfc/Sequences.md#objects)
* [Generators](rfc/Generators.md): generalized list comprehensions, `for`, `if`, `let`, `each`
* [Functions](rfc/Functions.md):
    [Function Literals](rfc/Functions.md#function-literals),
    [Curried Functions](rfc/Functions.md#curried-functions),
    [Right Associative Function Call](rfc/Functions.md#right-associative-function-call),
    [Modules are Curried Functions](rfc/Functions.md#modules-are-curried-functions),
    [User Defined Modules](rfc/Functions.md#user-defined-modules),
    [Fixing the Module Composition Problem](rfc/Functions.md#fixing-the-module-composition-problem)
* [Module Calls](rfc/Module_Calls.md)
* [Objects](rfc/Objects.md):
    [Scripts denote Objects](rfc/Objects.md#scripts-denote-objects),
    [Library Files](rfc/Objects.md#library-files),
    [Object Literals](rfc/Objects.md#object-literals),
    [The CSG Tree](rfc/Objects.md#object-literals),
    [Programming with Objects](rfc/Objects.md#jprogramming-with-objects)
* Brands [Varieties](rfc/Varieties.md)
* Standard Libraries: Geometry, Lists, Linear Algebra
* Error Reporting
* Backwards Compatibility
* Implementation: Lexer, Parser, Analyzer, Evaluator, Pruner
