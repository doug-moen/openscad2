# New Geometry System

Proposal: change the OpenSCAD language and geometry kernel
to support the following goals:
* faster, more memory efficient preview and rendering
* more powerful and expressive modeling primitives
* better support for curved surfaces and organic looking shapes
* very complex objects with micro-fine detail
* multiple colours and materials

OpenSCAD is currently based on triangular meshes.
Although we can get some improvements by replacing CGAL with a more
efficient mesh-based geometry engine, this design still places
serious limits on what kinds of models are possible.
By switching to a hybrid geometry engine that also supports
F-Rep (functional representation), we gain access to a lot of
new modelling primitives, and the ability to design highly
complex and detailed models that are impractical to create
using a mesh engine.

F-Rep modeling systems have some interesting abilities:
* Excellent support for curved surfaces.
  They provide a powerful set of primitives.
  Internally, curved surfaces are represented exactly
  (as mathematical equations), rather than as mesh based
  approximations that accumulate errors as they are transformed.
  Curved surfaces are previewed as curved surfaces, rather than as meshes.
* The model can be compiled into code that is executed directly
  by the GPU, for fast preview.
* Complex models with large amounts of procedurally generated detail
  can be previewed quickly with modest amounts of memory.
  For example, a level 5 Menger Sponge can be rendered instantaneously,
  with very little memory required. (Not possible with OpenSCAD.)
* Volumetric support for multiple colours and materials, including
  the ability to alternate between different materials at printer
  resolution to create "meta-materials" with software defined properties.

Here are some barriers to achieving these goals:
 1. The OpenSCAD language is not abstract enough to allow models
    to be independent of whether they are rendered using a mesh
    or F-Rep engine. For example, an N-sided prism is encoded as `cylinder(r=R, $fn=N)`.
 2. The STL file format may be a barrier to printing super complex models,
    like the order 5 Menger Sponge, because the number of triangles required
    (> 100,000,000 in this case) will overload the slicer.
    To overcome this problem, I'd like to support the
    export of volumetric file formats (like SVX), and also contribute code
    to Cura and other open source projects to support slicing of these formats.

Here's a proposal for moving forward:
* Build a prototype system that is similar to OpenSCAD, but based on F-Rep.
* Based on lessons learned from this prototype, design an improved modelling language containing a large common subset
  that is portable between OpenSCAD and the F-Rep based prototype.
* Extend the prototype into a full featured, hybrid F-Rep/mesh system with multi colour/material support.
* Write whatever code is necessary so that I can render an order 5 Menger Sponge 
  and print it using Cura.

There are already several solid modeling systems that support the OpenSCAD syntax.
It might be cool to coordinate a language standard that provides portability of
models across OpenSCAD implementations.
