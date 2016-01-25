# The Geometry Processing Model

## Geometric Representations

The primary representation used by the RHg geometry engine is functional.
Every shape contains a distance function, which computes the signed distance
to the nearest surface from any [x,y,z] point in space.
This functional representation is used for fast preview (it takes the place
of OpenCSG). STL export by default occurs by constructing a mesh from the
functional representation (this requires a complex algorithm).
Export to volumetric file formats, including voxel formats like SVX,
is also supported, and this is easier starting from a functional representation
than it is with a mesh.

A shape may optionally contain other representations.
A polyhedral shape may contain a mesh representation.
If the mesh is available, that's what's used for STL export.

B-Spline representations can also be supported in this way.

Colour and material information also has a functional representation.
A shape may optionally have one or more attribute functions,
which map every point in the shape's interior and surface onto
attribute values, which are then mapped onto colour and material
specifications during export, in whatever manner is appropriate,
based on the capabilities of the 3D printer being used.

This is a very general model: it permits an arbitrary number of user defined
numeric attributes to be defined at each point within the printed shape.
This generality is needed to support future 3D printing technology,
such as HP's Multi-Jet Fusion technlogy:

> The long-term vision for HP Multi Jet Fusion technology is to create parts with controllably variable—even quite
> different—mechanical and physical properties within a single part or among separate parts processed simultaneously in
> the working area. This is accomplished by controlling the interaction of the fusing and detailing agents with each other,
> with the material to be fused, and with additional transforming agents.
>
> Examples of controllably variable properties that are potentially achievable
> with HP Multi Jet Fusion technology include:
> * Accuracy and detail
> * Opacity or translucency (for plastics)
> * Surface roughness, textures, and friction
> * Strength, elasticity, and other material characteristics
> * Color (surface and embedded)
> * Electrical and thermal conductivity


## Modeling Language

The new modeling language has two subsets:
* A high level, abstract, implementation-independent subset.
  Easy to use and suitable for novices and designers.
  The high level API is designed to support efficient preview,
  which means it imposes some restrictions not present in OpenSCAD.
  The high level API hides the implementation: you don't write code
  that assumes a mesh implementation. You don't write `cylinder(r,$fn=6)`
  to construct a hexagonal prism.
* A low level subset, suitable for expert users.
  It provides low level control over the geometry engine.
  It can be used to code new geometric primitives, and provides
  full access to the internal representation of geometric objects.
  This part will vary between different OpenSCAD implementations.

As with OpenSCAD, there is a two stage processing model.
* In the first "evaluation" phase, we generate an abstract CSG tree.
* In the second geometry or "efiguration" phase, we convert the CSG tree into
  a geometric representation: B-Rep or F-Rep, which is then used
  for rendering as a preview or exporting to a file.

The F-Rep version of the scene will contain functions that were originally
defined by OpenSCAD code. These functions will be called many times during rendering,
which is performance sensitive. These F-Rep functions will either be compiled into
GLSL (the OpenGL shader language), or compiled into optimized machine code
using LLVM. My current intention is to use a subset of the modeling language
for specifying F-Rep functions, rather than introducing a different, incompatible
language for this purpose.

The current OpenSCAD implementation of phase 2 generates a mesh from the bottom up.
For the F-Rep implementation, I intend to create different F-Rep
representations of a given abstract object, conditional on what
operations are applied to it higher in the CSG tree.
This design is one of the unique contributions of this project:
it's needed to preserve the abstraction of the high level API,
and avoid bugs in ImplicitCAD and Antimony that are caused by
their bottom-up F-Rep architecture.

During efiguration, geometric information is propagated in two directions along
the CSG tree: bottom up and top down. This is like the distinction
between inherited and synthesized attributes in attribute grammars.
To make this work, we'll need "geometric attributes".

These are high level, synthesized attributes
that can be queried during evaluation using the high level API:
* `is_polytope`: this is only true for objects that are actual polygons
  or polyhedra in the abstract model, like a square, cube or pyramid.
  It is false for any object with curved surfaces, like a sphere.
  If is_polytope is true, then the vertexes and faces can be efficiently queried
  during evaluation, which means it is false for the output of CSG operations.
* `is_convex_polytope`: I'd like to support the Conway polyhedron operators,
  which mostly only make sense for convex polyhedra. This attribute permits
  type checking and error reporting for bad arguments.
* `has_bounding_box`: This is true for any shape for which a precise bounding box
  can be efficiently computed at preview time. It's true for cubes and spheres,
  true for the output of union and intersection, false for the output of difference.
  If true, then the bounding box can be queried during evaluation.

In order to implement F-Rep both *abstractly* and *correctly*,
some geometric primitives must choose between several different implementations,
based on what operators are applied to their output higher in the tree.
None of the open source F-Rep solid modelers that I have looked at so far do this:
they either produce incorrect output, or they force users to be aware of these
weird implementation details and manually select the correct implementation.
My design fixes these problems using inherited attributes, which are not
exposed by the high level API.
