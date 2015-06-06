# Functions

This RFC deals with the following changes:
* Functions, modules and shapes are [first class values](First_Class_Values.md).
* Anonymous function literals are added.
* Modules are a special case of functions.
* Module call syntax is a special case of function call syntax,
  and therefore legal in expressions.
* The [module composition problem](Composable_Building_Blocks.md) is fixed
  (eg, `for` can't be composed with `intersection`).

## 1. Functions are Values
### Function Literals
An anonymous function literal looks like this:

```
function(x, y) sqrt(x^2 + y^2)
```

### Function Definitions
It is possible to define a named function using a function literal:
```
hypot = function(x, y) sqrt(x^2 + y^2);
```

However, we provide an abbreviation for this.
The preferred definition syntax for named functions is now
```
hypot(x, y) = sqrt(x^2 + y^2);
```

The old function definition syntax is no longer preferred,
because it puts function names into a separate namespace
(see [backward compatibility](Backward_Compatibility.md)).

This abbreviation for function definitions
can also be used with named function arguments.
Here is an example of a generalized extrusion API inspired by ImplicitCAD,
where the `twist` argument is a function:
```
linear_extrude (height=40, twist = function(h) 35*cos(h*2*pi/60)) {
    square(10);
}
```
We can abbreviate the setting for `twist` like this:
```
linear_extrude (height=40, twist(h) = 35*cos(h*2*pi/60)) {
    square(10);
}
```

### Curried Functions
Since function values are first class, a function can return another function.
We can use this to implement a technique called *currying*,
where a function has more than one argument list.

For example,
```
add(x) = function(y) x + y;
```
`add(2)` is a function that adds `2` to its argument.
So `add(2)(3) == 5`.

The definition of `add` can be abbreviated as:
```
add(x)(y) = x + y;
```
and `add` is a curried function with 2 argument lists.

Currying is widely used by functional programming languages
to make library APIs more expressive and composable.
OpenSCAD2 represents modules with children as curried functions.

## 2. Modules are Functions

### Two Kinds of Modules
In OpenSCAD2, the module definition syntax (using the keyword `module`)
now just defines a function, and builtin modules are now functions.

There are two cases.
* A *childless module* has no children argument.
  Examples are `cube`, and a user defined module
  that doesn't reference `children()`.
  A childless module is a simple function that returns a shape.
  For example, `cube(10)` is a function call.

* A *module with children* has a children argument.
  Examples are `rotate`, and a user defined module
  that references `children()`.
  A module with children is a curried function
  that may be invoked using a double function call, such as: `rotate(45)(cube(10))`.
  The second argument list consists of a single argument,
  which is the children. The children can be a single shape,
  or it can be a list or object containing multiple shapes.

### Converting Module Definitions to Function Definitions
Here's how to convert an OpenSCAD1 module definition
to an equivalent OpenSCAD2 function definition:

<table>

<tr>
<td>
<td> <b>old</b>
<td> <b>new</b>

<tr>
<td> childless
<td>
<pre>
module box(x,y,z)
   cube([x,y,z]);
</pre>
<td>
<pre>
box(x,y,z) =
   cube([x,y,z]);
</pre>

<tr>
<td> with children
<td>
<pre>
module elongate(n) {
  for (i = [0 : $children-1])
    scale([n, 1, 1]) children(i);
}
</pre>
<td>
<pre>
elongate(n)(children) = {
  for (c = children)
    scale([n, 1, 1]) c;
};
</pre>

</table>

When converting a module definition to a function definition,
here is how children references are converted:

| old | new |
|-----|-----|
|`children()`|`children`|
|`children(i)`|`children[i]`|
|`children([i:j])`|`children[i..j]`|
|`$children`|`len(children)`|

You don't have to use the double-function-call syntax for invoking modules
within a function body. The traditional module call syntax also works,
but with limitations, as described in part 3 of this RFC.

The GUI provides a command for performing these conversions automatically.

### Fixing the Module Composability Problem
The new design for modules solves the module composability problem.
In the old design,
* A module takes a group of shapes as an argument (accessed with children()).
* A module returns a group of shapes as a result.
* But there is no way to take the group of shapes returned by one module M1,
  and pass that as the children() list to another module M2.
* For example, you can't compose `intersection` with `for`.

In OpenSCAD2, the double function call syntax for modules with children
solves the composability problem. In the second argument list,
you directly specify the children,
so `intersection()({for (i=x) f(i);})` just works.

Double function call syntax for modules is a syntax error in OpenSCAD1,
so there is no backward compatibility problem.

## 3. Traditional Module Call Syntax

### Backward Compatibility
OpenSCAD2 is backward compatible, so it supports the traditional
module call syntax. But there is a choice to be made.
* Do we use the old semantics, which have the module composability problem?
* Or do we use the new, more desirable
  [OEP2](https://github.com/openscad/openscad/wiki/OEP2:-Implicit-Unions)
  semantics?

In this RFC, I'll assume the new improved semantics.
The other option is discussed in [backwards compatibility](Backwards_Compatibility.md).

### Right-Associative Function Calls
Traditional module call syntax looks like this:
```
scale([0.5,1,1.5])
  rotate([45,45,45])
    translate([10,20,30])
      cube(10)
```
If this is converted to double-function-call syntax, it looks like this:
```
scale([0.5,1,1.5])
  (rotate([45,45,45])
    (translate([10,20,30])
      (cube(10))))
```
with the result that parentheses pile up at the end.

Traditional module call syntax is, in effect,
a *right associative function call* syntax
that reduces the number of parentheses needed
when geometric transformations are chained together.

Most functional programming languages provide an explicit right associative function call operator,
for exactly the same reasons: it reduces the number of parentheses required when chaining transformations.

OpenSCAD2 provides both options.
* The pipeline operator `<<` is a low precedence, right associative function call operator,
  which is available in both statement and expression syntax.
  You can think of `h << g << f << x` as a pipeline
  where data flows from right to left through a series of transformations:
  it's equivalent to `h(g(f(x)))`.
* The `<<` operator can be omitted in certain contexts,
  which correspond to the traditional module call syntax.
  If the right argument of `<<` begins with a token other than `(` or `[`,
  and if the right argument doesn't contain unary or binary operators
  (other than modifier characters in the statement syntax),
  then `<<` can be omitted.

Abbreviated function call syntax:

| expression | abbreviation
|------------|-------------
| `f(x)`     | `f x`
| `f(1)`     | `f 1`
| `f(g(h(1)))` | `f g h 1`
| `rotate(45)(cube(10))` | `rotate(45) cube(10)`

Some people write a chain of transformations like this:
```
scale([0.5,1,1.5])
rotate([45,45,45])
translate([10,20,30])
cube(10);
```
This is difficult to read. In my experiments, I find that writing `<<` explicitly
makes the code clearer when a chain of transformations extends across multiple lines:
```
scale([0.5,1,1.5])
<< rotate([45,45,45])
<< translate([10,20,30])
<< cube(10);
```

### Limitations on Modifier Characters
There is a syntactic conflict between OpenSCAD statement and expression syntax.
In the statement syntax, `f(x) % g(x)` calls the module `f(x)` with `%g(x)`
as its children. In the expression syntax, the same phrase invokes the remainder operator (`%`)
with the arguments `f(x)` and `g(x)`. A similar problem occurs with `*`.
As a result, if you want to convert the statement `rotate(45) %cube(10);`
to an expression, you have a couple of choices:
* `rotate(45) << %cube(10)`
* `rotate(45)(%cube(10))`

### Limitations on `for`
In OpenSCAD2, the `for` operator is a [generator](Generators.md),
part of "generalized list comprehension" syntax.
It is no longer considered a module.
This means it can only occur within a list or object literal.
For backwards compatibility reasons, we must allow statements like this:
```
rotate(45) for (i=x) m(i);
```
However, the compiler will insert the missing braces, and convert this to:
```
rotate(45) {for (i=x) m(i);}
```
The "upgrade to modern syntax" command will also insert the missing braces.
Once you upgrade to modern syntax, OpenSCAD2 will create an object
if and only if there are brace brackets in the syntax to denote an object literal.
This is different from the way that OpenSCAD1 implicitly creates groups
even when you don't want it to, leading to the module composability problem.

This syntax is not allowed in expressions.
You must place the `for` in a list or object literal.

The same restrictions apply to any statement that is classified
as a [generator](Generators.md) by the new design for
generalized list comprehensions.
