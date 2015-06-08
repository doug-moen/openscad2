# Generic Sequences

OpenSCAD has the following types for representing an ordered sequence of values:
* a list [a,b,c] is a sequence of arbitrary values
* a string "abc" is a sequence of Unicode code points
* a range [1:10] is a sequence of numbers
* a group `group(){cube(c);sphere(s);}` is a sequence of shapes.
  As a special case, `children()` is the group of shape arguments passed to a module.

OpenSCAD has generic operations on sequences,
but not all operations are supported on all sequence types.

|                   |list |string|range|group|`children()`
|-------------------|-----|------|-----|-----|----------
|len(seq)           | yes | yes  | -   | -   |`$children`
|seq[i]             | yes | yes  | -   | -   |`children(i)`
|for (i=seq) ...    | yes | -    | yes | -   |-
|concat(seq1, seq2) | yes | *    | -   | -   |-
|has empty sequences| yes | yes  | -   | yes |yes
|slice notation     | -   | -    | -   | -   |`children([i:j])`
|seq[index_vector]  | -   | -    | -   | -   | `children(index_vector)`

Note that strings can be concatenated using `str(s1,s2)`.

The goal of this RFC is to make all features available to all sequence types.
The rationale is simplicity, consistency and [composability](Composable_Building_Blocks.md).
This will make it easier to create a library of generic sequence operations.

## Strings
* `for` is extended so that it iterates over the characters in a string
* `concat` is extended so that it concatenates strings.
  The arguments to `concat` must be either all strings (the result is a string),
  or all non-strings (the result is a list).

Note that strings are not [fully composable](Composable_Building_Blocks.md),
so not all functions that operate on generic sequences
will work on strings unless they handle strings as a special case. The problem is that
list comprehensions don't generate strings: `[for(c="abc")c] != "abc"`. 
To fix that, we'd need to introduce
a character data type, such that `"abc"[0] == 'a'`,
and we'd need to ensure that `['a','b','c'] == "abc"`.
Eg, Haskell does this. I'm not going to propose this change
unless we can resolve backward compatibility issues,
and demonstrate that the implementation effort is reasonable compared to the benefits.
Right now I'm not sure.

## Ranges
OpenSCAD1 does not support empty ranges. The consequence is that if you write this code:
```
for (i = [0:len(list)-1]) ... list[i] ...
```
then your code will not work if `list` is empty, unless you check for that first.
What happens is that for an empty list, the above `for` loop will iterate twice
with `i=-1` and `i=0`. This is a potential bug lurking in many OpenSCAD1 scripts.

OpenSCAD2 fixes this bug and supports empty ranges.
If the end of the range is < the start of the range (with positive step value),
then the range is empty (consistent with Haskell).
Plus, we extend all of the generic sequence operations to ranges.

I'm concerned that this change would affect backwards compatibility,
since at present, `[10:1]` is equivalent to `[10:-1:1]`,
instead of yielding the empty range.
Also, you can currently use r[0], r[1], r[2] to reference the start, step and end values of a range.
Maybe there's code out there that relies on this.

My solution is to introduce a new range syntax, which will
support the new range semantics, and leave the old range values
to work as they always have (but the old ranges will be deprecated).

The new range syntax is taken from Haskell,
which closely resembles the
[set builder notation](http://en.wikipedia.org/wiki/Set-builder_notation)
taught in high school math.
As a result, this syntax is easier to understand for non-programmers,
and that this will improve ease of use.
* range with step 1: `[start..end]`
* range with step k: `[start,start+k..end]`

If `list` is `[]`, then `[0..len(list)-1]` is `[0..-1]` which is `[]`.
Note that `[z..a]` is empty whenever `z > a`.
In general, the sequence of values specified by `[start,start+k..end]`
is given by this C pseudocode:
```
for (i = start; i <= end; i += k)
   yield(i);
```

The new range values work with all of the generic sequence operations.
You can `concat` two ranges, or a range and a list,
and the result will be a list.

Although new ranges are represented internally as 3 numbers,
at the language and user level, they
are operationally indistinguishable from lists, therefore they are lists.
For example, `echo([1..5])` prints `[1,2,3,4,5]`.
Ranges in Python2 and Haskell work the same way.

## Slice Notation
The only place we currently support slice notation is `children([start:end])`.
Slice notation is *important*.
It makes it easier to write recursive functions over lists.

The new slice notation is taken from Rust:
* `seq[start..end]`
* `seq[start..]`
* `seq[..end]`

Slice notation makes it easier to write recursive functions over lists,
and makes list functions more flexible, since they can now operate on a slice.

Right now, recursive list functions need to have an auxiliary index parameter,
usually called `i`, for keeping track where we are in the list during recursion.
For example, here is `sumv` from MichaelAtOz's `vectormath.scad`.
The `i` and `s` parameters allow you to sum either a slice of the list, or the entire list.

```
function sumv(v,i,s=0) = (i==s ? v[i] : v[i] + sumv(v,i-1,s));
```

Using slices, we can define a simpler function `sum`, which doesn't require the parameters `i` and `s`.
If you need to sum only part of the list, you just pass a slice.

```
sum(v) = v==[] ? 0 : v[0] + sum(v[1..]);
```

## Generalized Indexing using an Index Vector
The only place we currently support generalized indexing is `children(v)`,
where `v` is a vector of indexes (a list or a range).
Since this syntax is deprecated,
we need a new generalized indexing syntax available to take its place
when code is upgraded to the new OpenSCAD2 syntax by the upgrade tool.

So we'll support `seq[v]` for all sequence types.

## Objects
Groups have been replaced by [objects](Objects.md).
An object consists of a set of named fields,
combined with a sequence of geometric values (shapes and objects).

When used with any of the sequence operations,
an object behaves as if it were the list of its geometric elements.
It is as if the object were automatically converted to a list.
This is the dual of what happens when a list is used in a context
requiring a geometric value: the list is implicitly converted
to an object composed of the list's geometric values.
