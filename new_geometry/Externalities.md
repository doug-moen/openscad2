# External Considerations

I'm designing this 3D solid modelling language and geometry engine,
based on OpenSCAD and F-Rep.

It would be nice to implement it for maximum flexibility,
so that it can be packaged in a variety of different ways.
So, what language do I implement it in, and what APIs do I expose?

## Traditional OpenSCAD Packaging
OpenSCAD is written in C++ and Qt.
That seems fine, and C++ is also the native language for LLVM,
which I'd like to use. I'm also interested in using the Vulkan
GPU API, when that becomes available: C++ will also work for that.

A possible alternative is to implement the modeling language
and geometry kernel as a Rust library, with an external C interface.
Rust has some benefits over C++:
* memory safety
* safe multi-thread programming
* the ability to safely kill a thread: it would be nice to have
  a kill button to terminate a runaway graphics computation

## Embedding in another language or tool
There should be a way of embedding the system in a language like Python.
So you use Python to construct geometric objects, then render them.

There should be a way of embedding the system in other CAD/modeling tools,
so that they can parse the modeling language and then render the model
using the tool's geometry kernel.

## Ease of Use and GUI Stuff

It ought to be possible to create a web based front end.
I imagine the geometry kernel running on the server, and
sending polygons or a GLSL script or an STL file to the client.

There ought to be a cloud based library of user-submitted material
(cool shapes and libraries), with a nice web based interface,
and also integration of this library into the client, also with a
nice UI.

You can browse the global repository, add stuff you like to your personal
cloud based shape and operation library, then access the stuff you
installed within the GUI. Maybe there's a tinkercad-like library bar
from which you drag and drop prototypical shapes, then use direct
manipulation to edit the shapes.

The OpenSCAD2 concept of a geometric object, extended with "customizer" metadata,
is essentially the same thing as a TinkerCAD library shape or an Antimony "node".
It's a prototypical shape with some parameters you can tweak, optionally using a GUI
and direct manipulation.

An algebraic constraint solver is a fine thing to have in a CAD gui.
The Antimony approach seems like a good fit with everything else.

[Brett Victor's Learnable Programming](http://worrydream.com/LearnableProgramming/)
