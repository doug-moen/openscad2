# Complex Geometry: Materials, Colours and Micro-fine Detail

This is a roadmap for evolving OpenSCAD to solve the following problems:
* Support objects with multiple materials and colours.
* Support complex objects with micro-fine detail (more structure than can
  be feasibly represented by a mesh).

In support of complex objects, we'll add the following functionality:
* Functional geometry: the ability to define geometric objects
  using functions, instead of using a mesh. OpenSCAD will become a
  hybrid system, capable of supporting models using a mixture of these
  two representations (also called F-Rep and B-Rep, for Functional and
  Boundary Representation).
* Voxels: the ability to export a model as a voxel file (like SVX), instead of to
  a mesh file (like STL).

I will also consider what's needed to import and export models as
AMF, 3MF and SVX. All 3 formats support multiple materials and colours,
and SVX is a voxel file format, while the other 2 are mesh formats.

The reason for considering such a large set of changes all at once, is that
it helps us avoid designing ourselves into a corner. If we have a roadmap
for where we are going, we can add new features incrementally without fear
that we'll have to break backward compatibility later when a new problem needs
to be solved.

## Complex Objects with Micro-fine Detail
One promise of 3D printing is that complexity is free.
Sadly, with the mesh representation used by OpenSCAD and STL,
the reality is that more complexity equals more triangles.
Too many triangles, and you can't render or print your model:
* Large meshes are very memory intensive, and past a certain limit (eg, 2 million
  triangles for Shapeways), it becomes impossible to slice and print the model.
* Mesh operations are inherently slow.
  The speed of CSG operations scales non-linearly with the number of triangles.
  Long preview and render times (from minutes to hours) are a well known problem
  with OpenSCAD.

For OpenSCAD, a stop-gap measure is to replace CGAL with a new geometry
engine that uses floating point numbers instead of variable-length rational
numbers. This speeds up CSG operations and reduces memory pressure.
Bob Cousins tried replacing CGAL with the Carve engine, and got a 10x speedup in rendering
times. While this sounds like an impressive improvement, it's not nearly enough.
Sure, it will cut a 2 hour rendering time down to 18 minutes, but we can do much better
with functional geometry, and it doesn't fix the fundamental limitation with STL files,
where the most complex models you might want to print can't be sliced if they are rendered
as STL.

## Functional Geometry
