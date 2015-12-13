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

A common layer height for consumer 3D printers is 0.1mm. Consider a 100mm cube, partitioned into
"voxels" that are 0.1mm cubes, which represent the smallest printable detail.
That's a total of 1 billion voxels.
Consider models with complex internal structure all the way down to the printer's resolution:
this would require billions of triangles, if represented by a mesh.
That's far beyond the capacity of either OpenSCAD, or of a slicer working on an STL file.

Models of this complexity are being designed and printed, just not with a mesh/STL based toolchain.
* [An ultrastiff, ultralight 3D printed material](http://news.mit.edu/2014/new-ultrastiff-ultralight-material-developed-0619)
* [MIT OpenFab project](http://openfab.mit.edu/)

Meanwhile, designers using STL based tools are running into the limits:
* ["At Shapeways we are starting to see a bunch more data exhibits this type of density. Scanned data, digital fabrics and fractal art all push the limits of what triangle formats can comfortably express."](http://abfab3d.com/2015/02/27/voxels-versus-triangles/)

To solve this problem, we need to extend our modelling toolchain so that we have an alternative
to the mesh for representing complex models. The proposed alternative is:
* For the in-memory representation of a rendered model, use functional representation (F-Rep)
  instead of CGAL-style boundary representation (B-Rep).
* To export a rendered model to a file, to be consumed by a slicer for 3D printing,
  use SVX, which is a voxel file format.

## Functional Geometry

## Multiple Materials

## Multiple Colours
