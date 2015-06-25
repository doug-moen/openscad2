# Structured Functional Programming

Recursive functions are the "assembly language" of
functional programming, and direct recursion the "goto".
We would like to formulate a set of primitives
for "structured functional programming",
which are the high level alternative to writing recursive functions,
just as "structured programming" was formulated as a high level alternative to the "goto".

References:
* [Functional Programming with Bananas, Lenses, Envelopes and Barbed Wire](http://eprints.eemcs.utwente.nl/7281/01/db-utwente-40501F46.pdf)
* [Origami Programming](https://www.cs.ox.ac.uk/jeremy.gibbons/publications/origami.pdf)
* [Folds and Unfolds all around us](http://conal.net/talks/folds-and-unfolds.pdf)

Although the reference material is highly abstract and may seem difficult,
my goal for Structured Functional Programming is to make functional programming
easier for OpenSCAD users: easier for beginners than writing recursive functions.

Our list comprehension syntax already accomplishes this goal in a limited domain,
but list comprehensions don't cover all of the standard patterns that we need
to eliminate recursion. It is interesting that OpenSCAD list comprehension syntax
uses the primitives `for`, `if` and `let`, which are also structured programming primitives.
Maybe we can push this correspondence further.

According to *Bananas*,
the important patterns of recursion are:
* catamorphisms
* anamorphisms
* hylomorphisms (these are also covered by *Origami* and *Folds&Unfolds*)
* paramorphisms
