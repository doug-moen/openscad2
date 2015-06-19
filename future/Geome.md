# The GEOME geometry library

## Standard Shapes
The standard shapes are customizeable objects.
You can literally write `cube;` as your first GEOME program,
and you'll get a standard size cube. The first 8 shapes are
also the primitive shapes from
[Conway's polyhedron notation](https://en.wikipedia.org/wiki/Conway_polyhedron_notation).
* `tetrahedron` (== `pyramid(3)`)
* `cube` (== `prism(4)`)
* `octahedron`
* `dodecahedron`
* `icosahedron`
* `prism(n)` // prism whose base is a regular n-gon
* `antiprism(n)`
* `pyramid(n)` // base is a regular n-gon
* `cone`
* `cylinder`
* `geodesic(v)` // an order-v geodesic sphere. `geodesic(1) == isosahedron`.

## Affine Transformations
An affine transformation T is a function that maps a shape to a shape.
But also, you can compose affine transformations using T1 * T2.
* `move(x,y,z)`
* `rotate(x,y,z)`
* `scale(x,y,z)`
* `mirror(x,y,z)`
* ...

## Arrangement Operators
The arrangement operators position objects relative to one another,
or relative to the axes.
There's no `center` argument to `cube`. Instead, you can use `align`
to align it relative to the x,y,z axes.
Details TBD.

## Conway Transformations
All of [Conway's operations](https://en.wikipedia.org/wiki/Conway_polyhedron_notation)
on convex regular polyhedra are included.
The domain of these operators may have to be restricted to convex regular polyhedra. We'll see.

## Other Shape Transformations
* `wireframe(shape)` // convert any polyhedron to a wireframe
* `tubify(shape)` // works on prisms and cylinders

## Parametric Shape Constructors
Use parametric functions to construct shapes. TBD.
