# Generalized Lists

OpenSCAD has the following types for representing an ordered sequence of objects:
* a list [a,b,c] is a sequence of values
* a string "abc" is a sequence of Unicode code points
* a range [1:10] is a sequence of numbers
* a group `group(){cube(c);sphere(s);}` is a sequence of shapes.
  As a special case, `children()` is the group of shape arguments passed to a module.

OpenSCAD has generic operations on sequences,
but not all operations are supported on all sequence types.

|                   |list |string|range|group|`children()`
|-------------------|-----|------|-----|-----|----------
|len(seq)           | yes | yes  | -   | -   |`$nchildren`
|seq[i]             | yes | yes  | yes | -   |`children(i)`
|for (i=seq) ...    | yes | -    | yes | -   |-
|concat(seq1, seq2) | yes | *    | -   | -   |-
|has empty sequences| yes | yes  | -   | yes |yes
|slice notation     | -   | -    | -   | -   |`children(i,j)`

Note that strings can be concatenated using `str(s1,s2)`.

The goal of this RFC is to make all features available to all sequence types.
The rationale is simplicity, consistency and [Composability](Composable_Building_Blocks.md).

## Generalized Strings
* `for` is extended so that it iterates over the characters in a string
* `concat` is extended so that it concatenates strings.
  The arguments to `concat` must be either all strings (the result is a string),
  or all non-strings (the result is a list).

## Generalized Ranges
Ranges are generalized so that empty ranges are supported.
If the end of the range is < the start of the range (with positive step value),
then the range is empty (consistent with Haskell).

I'm concerned that this will affect backwards compatibility,
since at present, `[10:1]` is equivalent to `[10:-1:1]`.
My solution is to introduce a new range syntax, which will
support the new range semantics, and leave the old range values
to work as they always have (but the old ranges will be deprecated).

The new range syntax is taken from Haskell.
I claim that the Haskell syntax is easier to understand,
and that this will improve ease of use.
* range with step 1: `[start..end]`
* range with step k: `[start,start+k..end]`

The new range values work with all of the generic sequence operations.
You can `concat` two ranges, or a range and a list,
and the result will be a list.

Although new ranges are implemented internally using a more compact
representation than lists, at the language and user level, they
are operationally indistinguishable from lists, therefore they are lists.
(Except that they are printed using range notation.)

## Generalized Slice Notation
The only place we currently support slice notation is `children(i,j)`.
Since this syntax is going to be deprecated,
I'd like a new generalized slice notation syntax available to take its place
when code is upgraded to the new OpenSCAD2 syntax.

The new slice notation is taken from Rust:
* `seq[start..end]`
* `seq[start..]`
* `seq[..end]`

## Unify Lists and Groups
As part of First Class Values,
we will make shapes into first class values.
There is no longer a reason for lists and groups to be separate types,
so we will replace groups with lists.
The old syntax that previously produced a group,
will now produce a list of shapes.
