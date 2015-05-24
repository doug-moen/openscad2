# First Class Functions

This RFC deals with the following changes:
* Functions, modules and shapes are [first class values](First_Class_Values.md).
* Anonymous function literals are added.
* Modules are a special case of functions.
* Module call syntax is a special case of function call syntax,
  and therefore legal in expressions.
* The [module composition problem](Composable_Building_Blocks.md) is fixed
  (eg, `for` can't be composed with `intersection`).

## Function Literals
An anonymous function literal looks like this:

```
function(x, y) -> sqrt(pow(x,2) + pow(y,2))
```

The `function` keyword can be omitted, when needed for brevity.

The preferred definition syntax for named functions is now

```
hypot = function(x, y) -> sqrt(pow(x,2) + pow(y,2));
```

## Curried Functions
Since function values are first class, a function can return another function.
We can use this to implement a technique called *currying*, named after inventor Haskell Curry.
This technique is so powerful that in typical functional programming languages, most functions are curried.

Here's the trick. Suppose you have a function with two arguments:
```
add = function(a,b) -> a + b;
```
You can redesign it to work like this:
```
add = function(a) ->
        function(b) ->
          a + b;
```
Normally you would abbreviate this by omitting some of the `function` keywords:
```
add = function(a) -> (b) -> a + b;
```
With this definition, `add(2)(3)` returns `5`.
This has two benefits:
* partial application (discussed here)
* right-associative function call syntax (discussed in the next section).

A curried function can be partially applied.
`add(1)` is a function that adds 1 to its argument.
This is useful if you have a library of "higher order functions"
that take functions as arguments.

For example, let's consider the famous `map` function:
```
map = function(f) -> (list) -> [for (x=list) f(x)];
```
If you want to add 1 to each element of a list, you can compose `add` with `map` like this:
```
map(add(1))(list)
```
But `map` itself can be partially applied. `map(add(1))` is a function that adds 1 to each element of a vector.
If you want to add 1 to each element of a matrix, you can do this:
```
map(map(add(1)))(matrix)
```
In short, you can use currying to build a library of highly composable operations,
for list manipulation, linear algebra and geometric transformations.
Once we have these features, we can start building the libraries.

## Right-Associative Function Call

Once you start programming with curried and higher order functions,
it becomes useful to have a *right associative function call* operator
as a syntactic convenience. In OpenSCAD2,
```
f << g << h << x
```
is an alternate way of writing `f(g(h(x)))`.
For deeply nested function calls, this avoids a pileup of `)` characters
at the end of the call.

Here's an example from earlier, rewritten to use `<<`:
```
map(map << add << 1) << matrix
```

## Modules are Curried Functions

In OpenSCAD2, transformation modules like `scale`, `translate` and `intersection`
are considered to be curried functions.
Any module with children arguments is considered to be a curried function, where the children
are passed as a single argument (possibly a list) after the first argument list.
For example,
```
scale(10)(cube(1))
```
which can also be written as
```
scale(10) << cube(1)
```
For backward compatibility with original OpenSCAD module call syntax,
the `<<` operator can be omitted if the right argument does not begin with `(` or `[`.
So you can also write this:
```
scale(10) cube(1)
```
If we apply this abbreviation to our previous example of incrementing a matrix,
we get this:
```
map(map add 1) matrix
```

Although it's nice to suppress the `<<` operator in small crowded expressions,
I find it is helpful to write it out explicitly when you have a function call
chain that extends over multiple lines. Many people write OpenSCAD code like this:
```
rotate([90,0,0])
translate([0,0,-20])
cylinder(r=10,h=40);
```
which I find hard to read. The high visibility of the `<<` operator
improves readability for code like this:
```
rotate([90,0,0])
<< translate([0,0,-20])
<< cylinder(r=10,h=40);
```

Note that you can't omit `<<` if the right argument contains a unary or binary operator.
For example,
```
scale(10) << %cube(1)
```
cannot be abbreviated as
```
scale(10) % cube(1)
```
because this is confused with the modulus operator.

## User Defined Modules
At this point, we have shown that modules are a special case of functions.
Although the old module definition syntax is never going away,
you are no longer required to use it.

Old syntax:
```
module add_wings(span) {
    translate([-(span/2),0,0]) children(1);
    children(0);
    translate([span/2,0,0]) children(1);
}
```
A first cut at translating to the new syntax:
```
add_wings = function(span)->(children)-> {
    translate([-(span/2),0,0]) children[1];
    children[0];
    translate([span/2,0,0]) children[1];
};
```
Since this module doesn't deal with an arbitrary list of shapes,
but in fact requires exactly 2 shapes as arguments,
you might try this instead:
```
add_wings = function(span, body, wing)-> {
    translate([-(span/2),0,0]) wing;
    body;
    translate([span/2,0,0]) wing;
};
```
If you are teaching OpenSCAD2 to beginners, then I recommend
you start with [Objects](Objects.md#programming-with-objects).
Objects are as powerful as modules, and easier to learn.
Function definitions can be introduced later as an advanced topic.
```
bird = {
   span = 80;
   wing = scale([1,.25,.1]) sphere(r=span/2);
   body = rotate([90,0,0])
          << translate([0,0,-20])
          << cylinder(r=10,h=40);

   translate([-(span/2),0,0]) wing;
   body;
   translate([span/2,0,0]) wing;
};
bird(span=120);
```
When using objects instead of modules, you don't need to learn about
the two kinds of parameterization or the complexities of `children()` and `$children`.
Instead, you just create an exemplar object, which can be prototyped as a top level
OpenSCAD script. Then you can selectively override parameters using function call syntax.

## Fixing the Module Composition Problem

The new design for modules solves the module composition problem.
In the old design,
* A module takes a group of shapes as an argument (accessed with `children()`).
* A module returns a group of shapes as a result.
* But there is no way to take the group of shapes returned by one module M1,
  and pass that as the `children()` list to another module M2.
  If you try, then what happens is that `$children==1`,
  and `children()` contains 1 element, which the group returned by M1.
