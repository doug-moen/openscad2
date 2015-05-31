# Backwards Compatibility

Our goal is to maintain backward compatibility with all published or archived
OpenSCAD scripts that still work today, so that they continue to run.

By "all", I probably mean 99.95%.
Realistically, each yearly release of OpenSCAD has introduced changes that,
in theory, could break some script, especially given the nature of the language,
where almost everything is legal, and there are virtually no error messages.
So really, my goal for OpenSCAD2 is to not break the world any worse than
a new release is normally expected to break things. We don't worry too much
about the change in behaviour of weird edge cases that no real world script
is expected to probe. But if 10% of the scripts on thingiverse stop working,
then that is a showstopper.

The main challenges to backward compatibility:
* three namespaces
* module composability problem

## Three Namespaces
In OpenSCAD2, everything is a first class value, including functions and modules.
In order for this to work, we can't segregate names by type, as OpenSCAD1 does,
with different namespaces for value, functions and modules. But we know that
there are existing scripts where the same name is used for a function and a module,
or for a module and a variable.

So we have 1 namespace for new OpenSCAD2 programs that take full advantage of
the new language features, but we have 3 namespaces for legacy OpenSCAD scripts.
The compiler analyzes each script, and uses a heuristic to determine whether the
script is "legacy", and has 3 namespaces, or "modern", and has 1 namespace.

The heuristic works like this.
OpenSCAD2 introduces new syntax for defining functions and modules.
If the new syntax is consistently used within a script, then that script is "modern".
If the old syntax is consistently used, then that script is "legacy".
It's an error to mix the two definition syntaxes within the same script.

Once this is determined, legacy scripts are compiled and interpreted according to legacy
rules, while modern scripts are compiled and interpreted according to modern rules.

It is legal for a legacy script to include or use a modern script,
and vice versa. Each script is analyzed in isolation, independent of who uses it
or who it uses.

## Lexical Scoping
OpenSCAD2 has lexical scoping. A variable or parameter may only be referenced within the block
where it is defined. Also, the scope of a definition extends from the following statement to the
end of the containing block, *except that* forward references are legal within a function or module
body: this makes recursive definitions possible.

OpenSCAD1 has weird rules and behaviour which conflict with the OpenSCAD2 semantics.
The question is the extent to which published and archived scripts depend on this
weird behaviour. Which bugs can we fix without breaking the world, and which bugs do
we have to emulate in "backward compatibility mode" within legacy scripts?

In OpenSCAD2 it is illegal to define the same variable twice within the same scope.
You get a duplicate definition error. I assume this is a safe change: probably no
existing scripts depend on this.


