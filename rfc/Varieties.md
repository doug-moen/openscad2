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
  * 3DShape
* Variety

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

This mechanism is bare-bones, and relies on documentation to establish what the contract for a variety is.
Typically, the object is required to define certain fields, and those fields must obey some axioms
or implement some contract.

A fancier system would declare the names of required fields within the variety,
and the system would check for the existence of these fields in the object.
But this wouldn't capture the full essence of most varieties.
At this point, the complexity of the design could take off as we bring in all of
the mechanisms of a type system to describe the contract of a variety and
automatically check this contract. But that's massive overkill for OpenSCAD.

The bare-bones variety mechanism is acceptably simple, but we even for this,
we still need to establish a need for it.
