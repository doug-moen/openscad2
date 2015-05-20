# First Class Values

In OpenSCAD2, every thing that can be referenced or manipulated by OpenSCAD code is a first class value.
This means:
* It can be passed as an argument to a function.
* It can be returned as a result from a function.
* It can be an element of a list.
* It can be written as a literal expression.
  This means we have anonymous function literals.
* It can be printed as a valid OpenSCAD expression using `echo`.
* It can be given a name using definition syntax: `name = value;`.
