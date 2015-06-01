# Standard Libraries

## Redefining all of the Geometric Primitives

A frequently asked question about OpenSCAD2 is:
are you going to redefine how all of the geometric primitives work?

My responses to this are:
* How would we maintain backward compatibility?
* I'd rather not take the lead on this myself.
  OpenSCAD2 is already a giant project, with its main focus
  on making everything into a first class value.
* An important goal of OpenSCAD2 is to make it into a more
  powerful programming language, *specifically because* this
  will provide more power to people who are writing libraries.
  I believe that OpenSCAD2 is powerful enough that we can
  experiment with redefining all the geometric primitives
  by just writing library code.
  If there are any features missing from OpenSCAD2 that
  are needed to make this possible,
  then those features would be in scope for OpenSCAD2.

So let's imagine a new addition to MCAD called `MCAD/geometry.scad`.
This will redefine all of the existing geometric primitives,
with a cleaner, more powerful, and more consistent API.

Are there any features needed from OpenSCAD2 in order to make this possible?
I've come up with a few ideas:
* `global` is a builtin object containing all of the names in the global scope.
  It is a reserved word, not an identifier, so that you can't redefine or shadow it.
  For example, if `MCAD/geometry.scad` has redefined `cube`,
  then the original definition is available using `global.cube`.
* `bounding_box(shape)` renders the shape and returns its bounding box.
