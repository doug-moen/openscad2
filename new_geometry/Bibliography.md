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
that is much faster, and which supports "feature detection" (an experimental feature
that you need to enable using a checkbox in the GUI).
It uses either regular marching cubes, or extended marching cubes when feature detection enabled.

There is plenty of research which acknowledges the problem
of reproducing sharp edges when generating a mesh,
and explains how to fix it.

Despite ImplicitCAD and Antimony using older algorithms,
the winner on the internet seems to be Dual Contouring:
* [Dual Contouring of Hermite Data](http://www.frankpetterson.com/publications/dualcontour/dualcontour.pdf) 2002 <br>
  This method seems popular. Lots of implementations and open source. One blog claims it is simpler to implement
  than marching cubes. The data structure is a voxel array, or octree, or ADF, augmented with surface normals
  and QEFs (quadratic error functions), all of which can be constructed from a distance function.
  The design optionally supports multiple materials: a material index is stored in each voxel,
  and a polyhedral boundary is created at the interface between two different materials. Which is what's
  needed for multi-material AMF export.
  * The Upvoid Engine uses this: [part1](https://upvoid.com/devblog/2013/05/terrain-engine-part-1-dual-contouring/),
    [part2](https://upvoid.com/devblog/2013/07/terrain-engine-part-2-volume-generation-and-the-csg-tree/).

Other research:
* [A Complete Distance Field Representation]() 2001 <br>
* [Feature-sensitive surface extraction from volume data](https://www.graphics.rwth-aachen.de/media/papers/feature1.pdf) 2001 <br>
  This is "Extended marching cubes". Used by Antimony. Dual Contouring claims to be a refinement of this.
* [Feature Preserving Distance Fields](http://www3.cs.stonybrook.edu/~mueller/papers/qu_volvis04.pdf) 2004 <br>

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

