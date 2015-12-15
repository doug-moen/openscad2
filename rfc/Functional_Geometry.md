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

This paper is a good tutorial on how Functional Geometry works,
and it also presents an original approach, which I'll call OpenFG,
on how functional geometry can be integrated into a modelling language.

I think my approach is more elegant, powerful, and easy to use, than
any other FG system that I've looked at so far. It introduces a single
shape constructor `make_shape`, and implements most of the OpenSCAD geometry
primitives, 2D and 3D, in a few hundred lines of OpenSCAD2 code.

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
`f` represents a sphere of radius `r` in F-Rep.
(Although we use a slightly different definition in practice; see below.)

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
  plus exciting new operations like shell() and perimeter_extrude().
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

The low level API contains utility operations that are used
to define new operations that map shapes onto shapes.
Shapes can be queried at run-time for their distance function
and their bounding box.

`shape.f`
> the distance function of a shape

`shape.bbox`
> the bounding box of a shape

## Weird Shapes
A distance function can express an arbitrary set of points in 3-space,
which could be a 2D surface, a 1D path, an isolated 0D point,
or a [fractal with a non-integer Hausdorff dimension](https://en.wikipedia.org/wiki/List_of_fractals_by_Hausdorff_dimension).
It's not limited to well formed, finite 3D solids.
* The upside is that this is very powerful and expressive. We can make productive use of weird shapes,
  and I haven't explored all of the possibilities yet.
* The downside is that we are giving users the ability to create pathological, malformed distance functions,
  and we have little ability to detect a malformed function and issue an error message.
  So we need to ensure that preview, STL export and SVX export produce some kind of valid result
  even if the distance function is pathological. We can't enter an infinite loop, crash, or export
  a non-manifold STL file.

Infinite space filling patterns are useful. They can be intersected with or subtracted from finite 3D solids.
Existing functional geometry systems make good use of this.
My insight is that we should use the bounding box [[-inf,-inf,-inf],[inf,inf,inf]] if the pattern is infinite in all directions. An infinite cylinder extending along the Z axis, with unit radius, would have bounding box [[-1,-1,-inf],[1,1,inf]]. Following this strategy, the intersection of the X, Y and Z cylinders would have a finite bbox with no special case code. is_finite(shape) tests the bounding box to determine if a shape is finite.

The empty set is a useful pattern. In ImplicitCAD, the bbox for the empty set is [[0,0,0],[0,0,0]], and there is ugly special case code in union to ignore empty shapes when computing the bbox for a union. Perhaps a better bbox for the empty shape is [[inf,inf,inf],[-inf,-inf,-inf]]. This has a height, width and depth of -inf, and may turn out to work correctly in bbox calculations with no special case code. Check and see when the Tutorial is complete. is_empty(shape) returns true if the height, width or depth of the bbox is <= 0.

A 2D object occupying the X-Y plane is directly expressible, without introducing a special type for 2D shapes,
or introducing a "2D subsystem".
```
square(n) = cuboid([n,n,0]);
```
We can test for a 2D object: minz and maxz are 0, width and depth are > 0.
So can we use this representation without any special casing? Do all of the polymorphic shape operators work
correctly on this representation without special casing? I think preview would work.

The PLASM language supports 1D shapes, and these are commonly used. A 3D cylinder is constructed as the cross-product
of a 1D line segment by a 2D circle. This would also work in Functional Geometry.
So this is something to play with in the future. Nothing new needs to be added to support this.

## Examples
In this section, we define a sample collection of high level operations in OpenSCAD2,
to demonstrate how easy it is to define shapes using functional geometry.
(The code for implementing any of these operations using a mesh is far more complex.)
The issue of what the standard high level API will be, and how backwards compatibility works,
is left to a later date.

### Primitive Shapes
Here I'll define 3 primitive shapes: sphere, cuboid and cylinder.
The main lesson will be learning how to write a distance function.

```
sphere(r) = 3dshape(
    f([x,y,z]) = sqrt(x^2 + y^2 + z^2) - r,
    bbox=[[-r,-r,-r],[r,r,r]]);
```

In the F-Rep section, I said that `f([x,y,z]) = x^2 + y^2 + z^2 - r^2`
is a distance function for a sphere, so why did we change it?

There are many different ways to write a distance function that produce the same visible result.
The main requirement is that the isosurface of the distance function at 0
(the set of all points such that f[x,y,z] == 0)
is the boundary of the desired object, and there are infinitely many functions that satisfy this
requirement for any given shape.

But the isosurface at 0 is not the only thing you need to consider.
A distance function defines an infinite family of isosurfaces,
and they are all important, particular when you use the `shell` primitive.
Consider
```
sp = sphere(10);
```
`sp.f` is the distance function. Because of the way we defined `sphere`,
the isosurface of `sp.f` at -1 is a sphere of radius 9, the isosurface at 1
is a sphere of radius 11, and so on. All of the isosurfaces of `sp` are spheres.
As a result, `shell(1) sp` will return a spherical shell with outer radius 10
and inner radius 9. The `shell` operator provides direct access to the other isosurfaces.
(See the Shell section, which is later.)

```
cuboid(sz) = 3dshape(
  f([x,y,z]) = max([abs(x-sz.x/2), abs(y-sz.y/2), abs(z-sz.z/2)]),
  bbox=[ [0,0,0], sz ]);
```
I have similar comments for `cuboid`.
The distance function is designed so that all of the isosurfaces of a given
cuboid are nested cuboids, and `shell` works as expected.

Here's a thought experiment. Consider defining the distance function for `cuboid`
so the the distance to the boundary is measured in millimeters along a vector that points to the centre.
With this definition, only the isosurface at 0 would be a true cuboid. The isosurfaces at positive values
would have increasingly convex sides, so that at large values, the surface would approach a sphere.
The isosurfaces at negative values would have increasingly concave sides.
This behaviour would be visible using `shell`.

Note the use of `max` in the distance function for `cuboid`.
Generally speaking, if your distance function computes the max of a function of `x` and a function of `y`,
then your shape will have a right angle between the X and Y axes.
Read [Olah's essay](https://christopherolah.wordpress.com/2011/11/06/manipulation-of-implicit-functions-with-an-eye-on-cad/) for more discussion of this.

```
cylinder(h,r) = linear_extrude(h=h) circle(r);
```

```
circle(r) = 2dshape(
    f([x,y]) = sqrt(x^2 + y^2) - r,
    bbox=[[-r,-r],[r,r]]);
```

```
linear_extrude(h)(shape) = 3dshape(
    f([x,y,z]) = max(shape.f(x,y), abs(z - h/2) - h/2),
    bbox=[ [shape.bbox[0].x,shape.bbox[0].y,-h/2], [shape.bbox[1].x,shape.bbox[1].y,h/2] ]);
```
> The result of `linear_extrude` is centred.

The distance function for `linear_extrude` computes the max
of a function of x & y with a function of z,
and the result is a right angle between the X/Y plane and the Z axis.
See above.

### Translation
translate(), align(), pack???.
No need for center= options.

### Shell

### Scaling
the effect of non-isotropic scaling on `shell`. Need for `spheroid`.

### CSG Operations
everything, nothing, complement,
union, intersection, difference

meaning of 'max' and 'min' in a distance function

### Rounded edges and Fillets
rcuboid, runion

### Perimeter_extrude

### Unclassified
```
rcuboid(r,sz) = 3dshape(
  f([x,y,z]) = rmax(r, [abs(x-sz.x/2), abs(y-sz.y/2), abs(z-sz.z/2)]),
  bbox=[ [0,0,0], sz ]);
```
> Cuboid with rounded corners (radius=r) from ImplicitCAD.
> All ImplicitCAD primitives that generate sharp corners have a rounding option.
> `rmax` is a utility function for creating rounded corners.

```
union(s1,s2) = 3dshape(
    f(p) = min(s1.f(p), s2.f(p)),
    bbox=[ min(s1.bbox[0],s2.bbox[0]), max(s1.bbox[1],s2.bbox[1]) ]);
```
> Simplest case of a union. ImplicitCAD uses special case code where the
> min and max in the bbox calculation ignore empty bounding boxes, but I've
> omitted that for clarity.

```
runion(r,s1,s2) = 3dshape(
    f(p) = rmin(r, s1.f(p), s2.f(p)),
    bbox=[ min(s1.bbox[0],s2.bbox[0])-r, max(s1.bbox[1],s2.bbox[1])+r ]);
```
> Create fillets! ImplicitCAD rounded union with radius `r`. (Why is the bbox padded by r?)
Example:
  ```
  runion(r=8,
  	cube([40,40,20]),
  	translate([0,0,20]) cube([20,20,30]))
  ```
![rounded union](http://thingiverse-rerender-new.s3.amazonaws.com/renders/47/9e/1c/c8/e2/RoundedUnionCubeExample_preview_featured.jpg)





```
complement(s) = 3dpattern(f(p) = -s.f(p));
```
> Convert a shape or pattern to its inverse: all points inside the object
> are now outside, and vice versa.

### Notes

[The mathematical basis for F-Rep](https://christopherolah.wordpress.com/2011/11/06/manipulation-of-implicit-functions-with-an-eye-on-cad/)
* rounded union of two objects
* shell: constant width shell of an object
* combining two circles to construct a torus

ShapeJS on the abfab3d.com blog:
* 
