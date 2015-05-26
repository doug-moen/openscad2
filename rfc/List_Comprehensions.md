# List Comprehensions

In OpenSCAD2, `for`, `if` and `let` are list comprehension operators.
They can be used in two contexts:
* in expression syntax within a `[...]` list literal.
  In this context, they specify a sequence of values that are added to a list.
* in statement syntax, either at the top level of a script,
  or within `{...}` object literals.
  In this context, they specify a sequence of shapes that are added to an object.

The syntax and semantics of the list comprehension operators are unified
across expression and statement syntax as much as possible, while
preserving backward compatibility. Whatever you can do in one context,
you can also do in the other context.
These changes will make the language more consistent and more powerful.

Also:
* `*expression` is equivalent to `if (false) expression`.
* `each sequence` equivalent to `for (i=sequence) i`.
