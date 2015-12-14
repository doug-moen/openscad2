# Functional Geometry

Functional geometry is the techne of defining geometric objects using functions.
These functions map each point [x,y,z] in space onto some property of the object.
The underlying representation is called F-Rep (functional representation),
in contrast to the B-Rep (boundary representation) currently used by OpenSCAD.

Functional geometry is awesome because
* Curved objects are represented exactly, rather than as polygonal approximations.
  Therefore, they don't lose resolution when they are scaled or transformed.
* Functional Geometry APIs are a simple and elegant way to solve many modelling problems,
  especially when modelling curved surfaces and organic shapes.
* Plus all of the speed and efficiency benefits described by [Efficient Geometry](Efficient_Geometry.md).

Functional geometry is gaining in popularity within the 3D printing community.
Here are some of the 3D modelling tools that use it:
* [ImplicitCAD](http://www.implicitcad.org/) 2011
* [ShapeJS](http://shapejs.shapeways.com/) 2013
* [IceSL](http://www.loria.fr/~slefebvr/icesl/) 2013
* [Antimony](http://www.mattkeeter.com/projects/antimony/3/) 2014

## Functional Representation (F-Rep)

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
The 3D surface defined by `f[x,y,z]==0` is an *isosurface*.
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

## Low Level API
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

## High Level API
In this section, we define a collection of high level operations in OpenSCAD2,
in order to show what is possible using functional geometry.
The issue of what the standard operations will be, and how backwards compatibility works,
is left to a later date.

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
