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
For example, this OpenSCAD1 module definition:
```
module rot(a)
   rotate([a,a,a]) children();
```
is equivalent to this OpenSCAD2 function definition:
```
rot(a)(children) =
   rotate([a,a,a])(children);
```
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
* The `<<` operator is a low precedence, right associative function call operator,
  which is available in both statement and expression syntax.
* The `<<` operator can be omitted in certain contexts,
  which correspond to the traditional module call syntax.
  If the right argument of `<<` begins with a token other than `(` or `[`,
  and if the right argument doesn't contain unary or binary operators
  (other than modifier characters in the statement syntax),
  then `<<` can be omitted.

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
In the statement syntax, `f(x) % g(x)` calls the module `f(x)` with `%g(x)`
as its children. In the expression syntax, the same phrase invokes the remainder operator (`%`)
with the arguments `f(x)` and `g(x)`. A similar problem occurs with `*`.
As a result, if you want to convert the statement `rotate(45) %cube(10);`
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
(Once you upgrade to modern syntax, OpenSCAD2 will create an object
if and only if there are brace brackets in the syntax to denote an object literal.
This is different from the way that OpenSCAD1 implicitly creates groups
even when you don't want it to, leading to the module composability problem.)

This syntax is not allowed in expressions.
You must place the `for` in a list or object literal.

The same restrictions apply to any statement that is classified
as a [generator](Generators.md) by the new design for
generalized list comprehensions.

---------------------------------
-----------------------------------
-------------------------------
------------------------------------
---------------------------------
## 4. Programming with Functions

### Currying
Since function values are first class, a function can return another function.
We can use this to implement a technique called *currying*, named after inventor Haskell Curry.
This technique is so powerful that in typical functional programming languages, most functions are curried.

Here's the trick. Suppose you have a function with two arguments:
```
add(a,b) = a + b;
```
You can redesign it to work like this:
```
add(a)(b) = a + b;
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
map(f)(list) = [for (x=list) f(x)];
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

### Right-Associative Function Call

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

### The `<<` can be omitted in some cases

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
This caveat only applies to expressions, where module call syntax was not previously supported.
Statement syntax is still fully backward compatible: the `<<` operator is the only binary operator
supported at the statement level.

### User Defined Modules
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
add_wings(span)(children) = {
    translate([-(span/2),0,0]) children[1];
    children[0];
    translate([span/2,0,0]) children[1];
};
```
Since this module doesn't deal with an arbitrary list of shapes,
but in fact requires exactly 2 shapes as arguments,
you might try this instead:
```
add_wings(span, body, wing) = {
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
