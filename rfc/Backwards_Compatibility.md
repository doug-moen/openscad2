# Backwards Compatibility

* Our goal is to maintain backwards compatibility with existing OpenSCAD scripts.
* Nevertheless, the OpenSCAD2 language is not fully backwards compatible with OpenSCAD1.
* To solve this problem, the openscad translator will detect whether a script is OpenSCAD2
  or OpenSCAD1, and it will run OpenSCAD1 scripts using a "backwards compatibility mode".
* There is a tool that upgrades OpenSCAD1 scripts to the OpenSCAD2 syntax.
  You can invoke it from the GUI or from the command line.

## Goal
Our goal is to maintain backward compatibility with all published or archived
OpenSCAD scripts that still work today, so that they continue to run.

By "all", I probably mean 99.95%.
Realistically, each yearly release of OpenSCAD has introduced changes that,
in theory, could break some script, especially given the nature of the language,
where almost everything is legal, and there are virtually no error messages.
So really, my goal for OpenSCAD2 is to not break the world any worse than
a new release is normally expected to break things. We don't worry too much
about the change in behaviour of weird edge cases that no real world script
is expected to encounter. But if 10% of the scripts on thingiverse were to stop working,
then that would be a serious bug.

## Reasons for Incompatibility
Here are the features of OpenSCAD2 that can cause incompatibility:
* Unified Namespace
  (vs 3 namespaces for variables, functions and modules)
* Lexical Scoping
  (vs legacy `include` semantics)
* [Stricter Error Reporting](Error_Reporting.md)
* Composable Modules,
  aka [Lazy Unions](https://github.com/openscad/openscad/wiki/OEP2:-Implicit-Unions)
  (vs the module composability problem)

This list will change as we implement and test OpenSCAD2.

## Backward Compatibility Mode
### Mode Detection
The compiler automatically detects whether a script is OpenSCAD1 or OpenSCAD2:
* If the script uses "old" syntax, then it is interpreted as OpenSCAD1.
* If the script uses "new" syntax, then it is interpreted as OpenSCAD2.
* If a mixture of "old" and "new" syntax is used, an error is reported.
* If neither "old" nor "new" syntax is detected, then
  by default the script is interpreted as OpenSCAD2.

"Old" syntax is any OpenSCAD1 syntax that could lead to functions or
modules being defined, which would lead to more than one namespace being used.
The specific patterns are:
* `function f(...) = ...;`
* `module m(...) ...`
* `include <...>`
* `use <...>`

"New" syntax is any OpenSCAD2 syntax that could result in
binding a name to a function value in the "variable" namespace,
or calling a value as a function.
* `function (params) ...` &mdash; a function literal
* `id(params) = ...;` &mdash; the new function definition syntax
* A function call with one of these forms:
  `M.f(args)`, `a[i](args)`, `(expr)(args)`, `{script}(args)`.
  The common element is that the function expression is not an identifier.
* `use object;`
* `using (names) object;`
* `include object;`
* Object literals used as expressions, outside the context that they
  appear in OpenSCAD1 (which are as statements or module arguments).
  This is because objects can contain function bindings.
* `script(filename)`

If an OpenSCAD1 script contains no "old" syntax,
then it consists of just variable assignments and statements.
There are no function or module definitions or references to external scripts.
Few published or archived scripts are expected to be this simple,
and in any case, such scripts are expected to be upward compatible with OpenSCAD2.
If we discover existing files
with only variable assignments and geometry that nevertheless break in OpenSCAD2,
then we'll fix the problem by adding more triggers for "old" syntax, or by revising the language.

### Semantics of Backward Compatibility Mode
In backwards compatibility mode,
* There are 3 namespaces, for variables, functions and modules.
* We emulate the bugs in `include <file>` as best we can,
  especially the mechanism that lets an including script override parameters
  in the included script.
* As much as possible, fatal error messages are dialed back to non-fatal warnings.
  However, see [Error Reporting](Error_Reporting.md):
  errors will be reported only when it helps the user, not to cause problems or break things.
  So this paragraph overstates the extent to which error messages are
  a problem that needs to be fixed.
* We will emulate the bugs in module call semantics which, eg,
  prevent `for` from being composed with `intersection`.

More generally, OpenSCAD probably has a lot of weird bugs in areas that people haven't
fully explored. Since OpenSCAD2 is a rewrite, we'll probably fix a lot of these bugs,
in many cases without realizing it. There is a fine line between a bug that just needs
to be fixed, and an incompatible change. Our "backward compatibility mode"
isn't going to emulate every bug we fix. For example, it's not clear to me if there
are any scripts that people care about that actually depend on the module composability bug.
Figuring out what bugs do and do not need to be emulated will be an
ongoing process that we'll figure out during testing.

### Semantics of Script Inclusion
An OpenSCAD1 script may include an OpenSCAD2 script, or vice versa.
This generally works, but interoperability problems may arise
if the OpenSCAD1 code relies on the existence of 3 namespaces
to distinguish bindings with the same name but different type.
* For example, an OpenSCAD1 script S might define a variable and a module
  with the same name X. If the OpenSCAD2 script includes S,
  then it will report an error if it tries to use the value of X.

[Look here for implementation details.](Implementation.md#analyzer)

## Upgrade Tool
The upgrade tool will automatically convert a script
from OpenSCAD1 syntax to OpenSCAD2 syntax.
* In the GUI, there's an a command in the Edit menu,
  "Upgrade to OpenSCAD2 syntax", which operates on the text
  in the current text buffer.
* There is also a command line option that outputs OpenSCAD2 syntax
  as an export format.

After performing the conversion, some things may no longer work,
due to semantic changes. So the user needs to test the script
and fix the problems. In the GUI version, we may be able to
automatically detect certain problems and suggest solutions.

Here's what the tool will change:
* Upgrade definition syntax. Convert function and module
  definitions. Convert `include` and `use` statements.
  * Maybe, we can detect the fact that the user is attempting
    to override parameters in an included file, and change that
    to OpenSCAD2 syntax? How commonly is this feature used?
* Insert missing braces if a module argument is a *generator*,
  eg it is a `for` statement.
* Maybe, we insert extra braces to emulate the module composability bug.

This list will change as we implement OpenSCAD2
and test it against existing scripts.
