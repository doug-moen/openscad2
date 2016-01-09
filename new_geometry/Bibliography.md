# F-Rep Bibliography

## Fundamentals
### R-Functions
[Analytic geometry](https://en.wikipedia.org/wiki/Analytic_geometry)
gives us the ability to visualize a geometric shape that corresponds to a function.
The equation for a circle has been known for centuries.
In the early 1960's, V. L. Rvachev was trying to find the equation for a rectangle.
In doing so, he created a system that solves *the inverse problem of
analytic geometry*: constructing equations for given geometric objects.
This is the theory of R-Functions, and it's the basis of F-Rep.

[Semi-Analytic Geometry with R-Functions,
Vadim Shapiro](ftp://ftp.cs.wisc.edu/pub/users/prem/rfuns.pdf)

### Distance Fields
* [Abstract 3D Distance Fields: A Survey of Techniques and Applications](http://www.ann.jussieu.fr/~frey/papers/divers/Jones%20M.W.,%203d%20distance%20fields,%20a%20survey.pdf) 2006 <br>
  A distance field is a representation where at each point within the field we know the distance from that point to the closest point on any object within the domain. In addition to distance, other properties may be derived from the distance field, such as the direction to the surface, and when the distance field is signed, we may also determine if the point is internal or external to objects within the domain. The distance field has been found to be a useful construction within the areas of Computer Vision, Physics and Computer Graphics. This paper serves as an exposition of methods for the production of distance fields, and a review of alternative representations and applications of distance fields. In the course of this paper we present various methods from all three of the above areas, and we answer pertinent questions such as How accurate are these methods compared to each other?, How simple are they to implement? and What is the complexity and run-time of such methods?

## Mesh Generation
ImplicitCAD uses a naive distance field representation.
It uses marching cubes to generate STL, which has two problems:
* very slow (N^3 algorithm)
* doesn't reproduce sharp edges in the model,
  which is a significant quality issue.

Antimony added a new STL generator in May 2015
that is much faster, and which supports "edge detection" (an experimental feature
that you need to enable using a checkbox in the GUI).
No idea how that works, yet.

There is plenty of research which acknowledges the problem
of reproducing sharp edges when generating a mesh,
and explains how to fix it.

* [A Complete Distance Field Representation]() 2001 <br>
* [Dual Contouring of Hermite Data]() 2002 <br>
  * [blog entry describing an implementation](https://upvoid.com/devblog/2013/05/terrain-engine-part-1-dual-contouring/)
* [Feature-sensitive surface extraction from volume data]() 2001 <br>
* [Feature Preserving Distance Fields](http://www3.cs.stonybrook.edu/~mueller/papers/qu_volvis04.pdf) 2004 <br>
  We present two distance field representations which can preserve
  sharp features in original geometric models: the offset distance
  field (ODF) and the unified distance field (UDF). The ODF is sampled
  on a special curvilinear grid named an offset grid. The sample
  points of the ODF are not on a regular grid and they can float in the
  cells of a regular base grid. The ODF can naturally adapt to curvature
  variations in the original mesh and can preserve sharp features.
  We describe an energy minimization approach to convert geometric
  models to ODFs. The UDF integrates multiple distance field representations
  into one data structure. By adaptively using different
  representations for different parts of a shape, the UDF can provide
  high fidelity surface representation with compact storage and fast
  rendering speed.
  * How to perform CSG operations on these 2 representations is "future research".

## F-Rep Modeling Tools
* [ShapeShop](http://www.shapeshop3d.com/) 2006 </br>
  A simple interactive solid modeling tool for "blobby" shapes:
  see also metablob/metaball modeling. Quite good for cartoon animals.
  The main primitives seem to be linear_extrude of polygons with rounded endcaps,
  rotate_extrude, and rounded union (aka blending).
  Free download for Windows. Not open source. Abandoned 2008.
  [Msc Thesis](http://www.shapeshop3d.com/downloads/ShapeShopMScThesis.pdf).

## User Interface
### Web Technology
The Web UI will have a text editor on the left, a preview window on the right.
* text editor: Ace. https://ace.c9.io/#nav=embedding
* preview window: renders preview using WebGL and ray-marching. https://www.shadertoy.com/

### Plumbing
"Flux" is a methodology for structuring complex UIs so that it is easy to reason
about their behaviour. An escape from callback hell, but it works with current web UI
technology. https://facebook.github.io/flux/docs/overview.html#content

### UI Design
In the future, I'd like to explore advanced direct manipulation UIs for
interacting with code and models. Better tools for visualizing the structure and relationships
in the code and the model,
debugging it, visualizing program evaluation, etc. Multi-user collaboration too.
* Jonathan Edwards has done some cool, cutting edge research.
  He won't share his code, but he describes his approach online.
  http://alarmingdevelopment.org/
* Brett Victor's Learnable Programming: http://worrydream.com/LearnableProgramming/

