# Varieties

This RFC describes an advanced programming feature that might not be needed.
I don't want to implement it until we establish a need for it.

The feature is inspired by an observation: I've seen people write code
to test the "type" of a value using ad-hoc kludges, such as `len(x) != undef`
to test if something is a list (although this condition is also true for strings).

We can provide a more formal and reliable way to write these tests:
    *value* `isa` *variety*
queries a value for what operations it supports,
what contexts it can be legally used in.

I hesitate to use the words "type" or "class", because that might lead to
misunderstandings, based on what these words mean in other programming languages.
So, for the moment, I'm using "variety".

A value may belong to several different varieties,
and varieties are organized in a hierarchy or heterarchy.
A variety isn't meant to tell you how a value was created,
what function or syntax was used to construct it.
It is meant to tell you how the value behaves,
what operations it supports, whether it is suitable
for some particular purpose.
This is different from testing the "type" or "class"
of a value in many dynamically typed languages.

Here is a provisional hierarchy of built-in varieties:
* Undefined (one value, `undef`)
* Boolean (two values, `true` and `false`)
* Number
* Sequence
  * String
  * List (includes "new ranges")
  * Object
* Function
* Shape
  * 2DShape
    * ...
  * 3DShape
    * Cube
    * Sphere
    * Intersection
    * ...
* Variety

For example, you could write a module that takes either
2D or 3D shapes as arguments, and uses `x isa 2DShape`
to provide the correct behaviour, based on the dimensionality.

## User Defined Varieties

This extends the *Simple Objects* facility
so that developers can define new varieties,
and specify which varieties an object supports.

To construct a new variety, use `VarietyName = variety();`.
Note that `variety()` has a side effect, and creates a new variety distinct from any existing variety.

A variety can inherit from one or more parent varieties: `MyVariety = variety(Parent1, Parent2);`.

When you construct an object, you can assert that it belongs to one or more varieties:

```
myobject = {
    isa MyVariety;
    ...
};
```

Note that an `isa` declaration within an object must refer to a user-defined variety, not a built-in variety.

This mechanism is quite simple, and makes no assumptions about what a variety means.
A variety is just a boolean property that can be attached to an object.
It's up to the user to document the meaning of each variety.
