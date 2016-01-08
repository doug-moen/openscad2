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

## F-Rep Modeling Tools

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

