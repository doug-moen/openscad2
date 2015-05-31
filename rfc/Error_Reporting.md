# Error Reporting

OpenSCAD1 reports virtually no error messages about bad code,
beyond a few syntax errors detected by the lexer and parser.
This has two negative consequences:
1. Ease of use. Common mistakes made by beginners,
   such as typing `cube(x,y,z)` instead of `cube([x,y,z])`,
   are not reported. It is frustrating to figure out what
   went wrong in your script when OpenSCAD provides no assistance.
2. Our ability to extend the language with new features suffers
   if everything is legal. For example, we are extending the `center=`
   parameter of `cube` to accept a vector of booleans.
   But according to the wiki, `[true,false,false]` is already
   a perfectly valid Boolean value that is equivalent to `true`,
   so in principle, we can't make this change without breaking
   a legal program. If some programs were illegal, and if this was
   enforced by error messages, then we could safely extend the language
   by reinterpreting illegal programs as legal ones.

For these reasons, OpenSCAD2 has stricter error reporting.
