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
* catamorphisms (fold)
* anamorphisms (unfold)
* hylomorphisms (these are also covered by *Origami* and *Folds&Unfolds*)
* paramorphisms

## unfold
Unfold seems like the next most interesting operator after fold.
But how to express it conveniently in OpenSCAD?

Unfold: Expand a structure up from a single value.

unfoldL :: (b → Maybe (a × b)) → (b → [a ])

unfoldL f b = case f b of
  Just (a, b') → a : unfoldL f b'
  Nothing → [ ]

Sometimes it is convenient to provide the single argument of unfoldL as
three components: a predicate indicating when that argument should return
Nothing, and two functions yielding the two components of the pair when it
does not. The resulting function unfoldL takes a predicate p indicating when
the seed should unfold to the empty list, and for when this fails to hold,
functions f giving the head of the list and g giving the seed from which to
unfold the tail:

unfoldL :: (β → Bool) → (β → α) → (β → β) → β → List α
unfoldL p f g b = if p b then Nil else Cons (f b) (unfoldL p f g (g b))

-- unfold is just like a C for loop:
unfold (b=val; p b; b=g b) f b
