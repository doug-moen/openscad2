# The Geometry Processing Model

The new language has two subsets:
* A high level, abstract, implementation-independent subset.
  Easy to use and suitable for novices and designers.
* A low level subset, suitable for expert users.
  It provides low level control over the geometry engine.
  It can be used to code new geometric primitives, and provides
  access to the internal representation of objects.
  This part will vary between different OpenSCAD implementations.

As with OpenSCAD, there is a two stage processing model.
* In the first phase, we generate an abstract CSG tree.
* In the second phase, we convert the CSG tree into
  a B-Rep or F-Rep representation, using the geometry kernel API,
  for rendering as a preview or exporting to a file.

The current OpenSCAD implementation of phase 2 generates a mesh from the bottom up.
For the F-Rep implementation, I intend to create different F-Rep
representations of a given abstract object, conditional on what
operations are applied to it higher in the CSG tree.
