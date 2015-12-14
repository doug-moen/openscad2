# Complex Geometry: Materials, Colours and Micro-fine Detail

This is a roadmap for evolving OpenSCAD to solve the following problems:
* Support objects with multiple materials and colours.
* Support complex objects with micro-fine detail (more structure than can
  be feasibly represented by a mesh).
* Better support for curved objects and organic shapes.

In support of complex objects, we'll add the following functionality:
* Functional geometry: the ability to define geometric objects
  using functions, instead of using a mesh. OpenSCAD will become a
  hybrid system, capable of supporting models using a mixture of these
  two representations (also called F-Rep and B-Rep, for Functional and
  Boundary Representation).
* Voxels: the ability to export a model as a voxel file (like SVX), instead of to
  a mesh file (like STL).

Functional geometry is also a better way to construct curved objects.

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
this could require billions of triangles, if represented by a mesh.
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
* Currently, curved objects are implemented using polygonal approximations. `$fn` controls the resolution:
  the higher the resolution, the more memory is consumed and the longer you wait for a preview.
  With functional geometry, curved objects are represented analytically, and previewed
  at effectively infinite resolution (`$fn = ∞`) for free.

There are a few expensive operations in F-Rep. The trick is to design your model so that you don't need them.
* Conversion from F-Rep to B-Rep is expensive. This is acceptable if it is only invoked while exporting to STL
  or another mesh format. It's bad if the conversion occurs repeatedly during preview (see below).
* Convex hull and Minkowski sum can't be efficiently implemented for F-Rep. You have to convert to B-Rep first
  (see above), then run the operations on B-Rep. Fortunately, it seems (so far) that functional geometry provides
  good alternatives to these operations, covering the standard use cases seen in OpenSCAD.
* If your CSG tree contains millions of nodes, then you'll use a lot of memory and preview will be slow.
  But there's an alternative:
  put the algorithm that generates all of this complexity into the functions of a small number of F-Rep nodes.

The good news is that if you avoid the expensive stuff, then a model too complex to be rendered as a mesh
by OpenSCAD can be rendered and previewed in a fraction of a second using F-Rep.

The SVX voxel file format is the best alternative to STL that I can find for representing models
too complex for a mesh.
* It completely avoids mesh representation.
* It is a simple format (compared to the byzantine complexity of AMF or 3MF),
  and is easy to implement.
* It is easy to slice, as the representation is close to the g-code: it's already organized into slices.
* The combination of SVX and F-Rep can give designers low-level control over each voxel the printer prints.
* An SVX file is on average half the size of the equivalent binary STL file
  [[Shapeways, 2015](http://abfab3d.com/2015/02/27/voxels-versus-triangles/)].
  This does mean that SVX files for models too complex for STL could be gigabytes in size.
* You don't have to load the entire model into memory at once, in order to slice it and convert it
  to g-code. This is the most important part. You only need to load one slice at a time.
  You do one pass to construct a depth map, used to generate support,
  then you do a second pass to generate g-code.
* The conversion from F-Rep to voxels is simple, fast and memory efficient, compared to generating STL.

The downside of SVX is that so far, only Shapeways supports it.
So part of this project is to join an open source project like Cura and add SVX support.
Fortunately, we get a lot of benefits from F-Rep even if SVX support is missing.

## Functional Geometry

Functional geometry is the techne of defining geometric objects using functions.
These functions map each point [x,y,z] in space onto some property of the object.
The underlying representation is called F-Rep (functional representation),
in contrast to the B-Rep (boundary representation) currently used by OpenSCAD.

Functional geometry is awesome because
* Curved objects are represented exactly, rather than as polygonal approximations.
  Therefore, they don't lose resolution when they are scaled or transformed.
* Functional Geometry APIs are a simple and elegant way to solve many modelling problems,
  especially when modelling curved surfaces and organic shapes.
* Plus all of the speed and efficiency benefits described earlier.

Functional geometry is gaining in popularity within the 3D printing community.
Here are some of the 3D modelling tools that use it:
* [ImplicitCAD](http://www.implicitcad.org/) 2011
* [ShapeJS](http://shapejs.shapeways.com/) 2013
* [IceSL](http://www.loria.fr/~slefebvr/icesl/) 2013
* [Antimony](http://www.mattkeeter.com/projects/antimony/3/) 2014

### Functional Representation (F-Rep)

The mathematical equation for a sphere of radius `r` is `x^2 + y^2 + z^2 = r^2`.

We can rewrite this as `x^2 + y^2 + z^2 - r^2 = 0`.

The above is an *implicit equation*,
from which we can derive the *implicit function*
```
f[x,y,z] = x^2 + y^2 + z^2 - r^2
```

`f[x,y,z]` is:
* zero if the point [x,y,z] is on the boundary of the sphere
* negative if the point is inside the sphere
* positive if the point is outside the sphere

More generally, `f[x,y,z]` is the distance of the point from the sphere's boundary,
and `f` is called a *signed distance function*, a *distance function*, or a *distance field*.
The 3D surface defined by `f[x,y,z]=0` is an *isosurface*.
`f` is how a sphere of radius `r` is represented in F-Rep.

There's one more wrinkle.
In F-Rep, a distance function maps every point in 3D space onto a signed distance.
This representation is not restricted to representing finite geometrical objects.
It can also represent infinite space-filling patterns.
For examples, try a Google image search on
[k3dsurf periodic lattice](https://www.google.ca/search?q=k3dsurf+periodic+lattice&tbm=isch).
These infinite patterns are useful in 3D modelling:
you can intersect them or subtract them from a finite 3D object.

An essay on
[the mathematical basis of F-Rep](https://christopherolah.wordpress.com/2011/11/06/manipulation-of-implicit-functions-with-an-eye-on-cad/)
by Christopher Olah, inventor of ImplicitCAD.

### Low Level API
In OpenSCAD2, functional geometry has both a low-level and a high-level API.
* The high level API includes familiar operations like sphere(), translate() and intersection(),
  plus additional operations and options made possible by F-Rep.
* The low level API allows users to directly define new primitive operations
  using distance functions, and is perhaps the analogue of polyhedron() for B-Rep.

`3dshape(f([x,y,z])=..., bbox=[[x1,y1,z1],[x2,y2,z2]])`
> Returns a functional 3D shape, specified by a distance function.
> The bounding box is required for implementation reasons: there is
> no cheap way to compute it from `f`. The bounding box can be larger
> than necessary, but any tendrils of the shape that extend beyond
> the bounding box will be truncated.

`3dpattern(f([x,y,z])=...)`
> Returns a potentially infinite, space filling 3D pattern.
> You can intersect this with a 3D shape, or subtract it from a 3D shape,
> which yields another finite 3D shape. But you can't export a 3D pattern
> to an STL file.

`2dshape` and `2dpattern` are the 2 dimensional analogues of the above.

The low level API also contains utility operations that are used
to define new operations that map shapes onto shapes.
Shapes can be queried at run-time for their distance function
and their bounding box.

### High Level API
In this section, we define a collection of high level operations in OpenSCAD2,
in order to show what is possible using functional geometry.
The issue of backwards compatibility is left to a later date.

```
sphere(r) = 3dshape(
    f([x,y,z]) = x^2 + y^2 + z^2 - r^2,
    bbox=[[-r,-r,-r],[r,r,r]]);
```

```
circle(r) = 2dshape(
    f([x,y]) = x^2 + y^2 - r^2,
    bbox=[[-r,-r],[r,r]]);
```


### Notes

Functional geometry works like this: ...
high level and low level APIs

[The mathematical basis for F-Rep](https://christopherolah.wordpress.com/2011/11/06/manipulation-of-implicit-functions-with-an-eye-on-cad/)
* rounded union of two objects
* shell: constant width shell of an object
* combining two circles to construct a torus

ShapeJS on the abfab3d.com blog:
* 

## Multiple Materials

## Multiple Colours
