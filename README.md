# Better abstraction mechanisms for OpenSCAD
OpenSCAD2 is a backward compatible redesign of the [OpenSCAD](http://openscad.org/) language.
The goals are:
 1. to make OpenSCAD easier to use;
 2. to make OpenSCAD more expressive and powerful, not by adding complexity and piling on features, but by making the core language simpler and more uniform, and by removing restrictions on how language elements can be composed together to create larger components.

To do this, we'll focus on improving OpenSCAD's abstraction mechanisms. In a programming language, abstraction mechanisms are the mechanisms used to define new things in terms of existing things.

## RFC documents
The design documentation is structured as a collection of RFCs.
To comment on an RFC, click on [Issues](//github.com/doug-moen/openscad2/issues)
in the sidebar, and either create a new issue with the same name as the RFC, or find the existing issue.
* [Ease Of Use](rfc/Ease_Of_Use.md)
* [Declarative Semantics](rfc/Declarative_Semantics.md)
* [Composable Building Blocks](rfc/Composable_Building_Blocks.md)
* [First Class Values](rfc/First_Class_Values.md)
* [Definitions And Scoping](rfc/Definitions_And_Scoping.md)
* [Sequences](rfc/Sequences.md):
    [Strings](rfc/Sequences.md#generalized-strings),
    [Ranges](rfc/Sequences.md#generalized-ranges),
    [Slice Notation](rfc/Sequences.md#generalized-slice-notation),
    [Groups](rfc/Sequences.md#unify-lists-and-groups)
* Functions
* [Objects](rfc/Objects.md):
    [Library Files](rfc/Objects.md#library-files),
    [Programming with Objects](rfc/Objects.md#jprogramming-with-objects)
* [Varieties](rfc/Varieties.md)
* Error Reporting
