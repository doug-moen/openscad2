# Simple Values

This is a collection of fairly trivial language extensions.
They mostly address ease of use, but also consistency and completeness.

## Booleans
### and, or, not
For ease of use,
I would like to add boolean operators `and`, `or` and `not`.
These are simple aliases for `&&`, `||` and `!`, with the same precedence.

Rationale: OpenSCAD is a 3D modelling tool for graphical designers.
It should not assume prior experience with a C-like programming language.
These names should be easier to understand.

### if (cond) ... else ...
I would like to support `if (condition) expr else expr` as an expression.
This is more readable than `..?..:..` when conditional code extends
over multiple lines, and is part of the unification of expression syntax
with statement syntax (making the language more consistent).

## Numbers
### exponentiation
I would like to add an exponentiation operator, `x^y`,
as an alternative to `pow(x,y)`.
It has higher precedence than `*`, and is right associative.

### mod
I would like to add an infix `mod` operator, with the same precedence as `%`,
except that unlike `%`, it correctly computes the modulus for both positive
and negative arguments.
```
a mod m == a - m*floor(a/m)
```
Reference: http://mathworld.wolfram.com/Mod.html

Rationale: the name `mod` is more accessible to users without a background
in C-like programming languages, and answers a frequently asked question,
"where is the mod operator?".
Also, this mod operator has mathematically correct behaviour.
By contrast, our `%` operator is actually implemented by the C++ remainder operator `%`,
which computes an implementation-defined "remainder", not the modulus.

### inf, nan
Currently, numbers are not [first class values](First_Class_Values.md).
That's because 1/0 prints as inf, and 0/0 prints as nan, but neither inf nor nan are valid expressions.
Let's fix this.

## Strings
### ucode
For completeness, `ucode(string)` returns the numeric value of the first Unicode code point in `string`,
which is a non-empty string.
The result will be an integer between 1 and 0x10FFFF, or `undef` for a bad argument.
`ucode` is the dual of `chr(number)`.
