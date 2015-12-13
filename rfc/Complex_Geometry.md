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
that we'll have to break backward compatibility later when the next problem needs
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

To solve this problem, we need to extend OpenSCAD and our downstream toolchain
so that we have an alternative to the mesh for representing complex models. The proposed alternative is:
* For the in-memory representation of a rendered model, support functional representation (F-Rep)
  in addition to CGAL-style boundary representation (B-Rep).
* To export a rendered model to a file, to be consumed by a slicer for 3D printing,
  support SVX, which is a voxel file format, in addition to STL.

F-Rep is much faster and much more memory efficient than B-Rep (meshes).
* The memory requirement for F-Rep is within a constant factor of the memory requirement
  for the CSG tree. Rendering does *not* cause an explosion of memory consumption.
* During rendering (conversion of the CSG tree to F-Rep),
  the CSG operations run in constant time (or, proportional to the number of arguments).
* Preview is extremely fast, from what I've seen of existing F-Rep modelling tools.
  The cost of rendering the preview pane is proportional to the number of primitives in the CSG tree.
  And this operation can be made highly parallel. IceSL implements preview entirely in the FPU.

There are a few expensive operations in F-Rep. The trick is to design your model so that you don't need them.
* Conversion from F-Rep to B-Rep is expensive. This is acceptable if it is only invoked while exporting to STL
  or another mesh format. It's bad if the conversion occurs repeatedly during preview (see below).
* Convex hull and Minkowski sum can't be efficiently implemented for F-Rep. You have to convert to B-Rep first
  (see above), then run the operations on B-Rep. Fortunately, it seems (so far) that functional geometry provides
  good alternatives to these operations, covering the standard use cases seen in OpenSCAD.
* If your CSG tree contains millions of nodes, then yeah, you'll use a lot of memory and preview will be slow.
  But there's an alternative to this style of programming.
  If you can put the algorithm that generates all of this complexity into the function in an F-Rep node,
  then you can solve this problem.

The good news is that if you avoid the expensive stuff, then a model too complex to be rendered as a mesh
by OpenSCAD can be rendered and previewed in a fraction of a second using F-Rep.

The SVX voxel file format is the best alternative to STL that I can find for representing models
too complex for a mesh.
* It completely avoids mesh representation.
* It is an incredibly simple format (compared to the byzantine complexity of AMF or 3MF),
  and is easy to implement.
* It is fairly easy to slice, as the representation is fairly slow level: it's already organized into slices.
* An SVX file is on average half the size of the equivalent binary STL file.
  [[Shapeways, 2015](http://abfab3d.com/2015/02/27/voxels-versus-triangles/)]
* You don't have to load the entire model into memory at once, in order to slice it and convert it
  to g-code. This is the most important part. You only need to load one slice at a time.
  You do one pass to construct a depth map, used to generate support,
  then you do a second pass to generate g-code.
* The conversion from F-Rep to voxels is very simple, fast and memory efficient, compared to generating STL.

The downside of SVX is that so far, only Shapeways supports it.
So part of this project is to join an open source project like Cura and add SVX support.
Fortunately, we get a lot of benefits from F-Rep even if SVX support is missing.

## Functional Geometry

## Multiple Materials

## Multiple Colours
