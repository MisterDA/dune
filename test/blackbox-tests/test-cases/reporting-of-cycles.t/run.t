These tests is a regression test for the detection of dynamic cycles.

In all tests, we have a cycle that only becomes apparent after we
start running things. In the past, the error was only reported during
the second run of dune.

  $ dune build @package-cycle
  Error: Dependency cycle between the following files:
     alias a/.a-files
  -> alias b/.b-files
  -> alias a/.a-files
  [1]

  $ dune build @simple-repro-case
  Error: Dependency cycle between the following files:
     _build/default/x
  -> _build/default/y
  -> _build/default/x
  [1]

  $ dune build x1
  Error: Dependency cycle between the following files:
     _build/default/x2
  -> _build/default/x3
  -> _build/default/x2
  [1]

  $ dune build @complex-repro-case
  Error: Dependency cycle between the following files:
     _build/default/cd1
  -> _build/default/cd4
  -> _build/default/cd3
  -> _build/default/cd2
  -> _build/default/cd1
  [1]

In some cases the dependencies are indirect (#666, #2818).
They can make the error message worse.

For the simple case, dependencies are enough to detect a cycle with a nice
error message.

  $ echo 'val x : unit' > indirect/c.mli
  $ dune build @indirect-deps
  File "indirect/dune", line 6, characters 0-43:
  6 | (alias
  7 |  (name indirect-deps)
  8 |  (deps a.exe))
  Error: dependency cycle between modules in _build/default/indirect:
     A
  -> C
  -> A
  [1]

But when the cycle is due to the cmi files themselves, the message becomes
cryptic and can involve unrelated files:

  $ echo 'val xx : B.t' >> indirect/c.mli
  $ dune build @indirect-deps
  Error: Dependency cycle between the following files:
     _build/default/indirect/.a.eobjs/a.impl.all-deps
  -> _build/default/indirect/.a.eobjs/b.impl.all-deps
  -> _build/default/indirect/.a.eobjs/c.intf.all-deps
  -> _build/default/indirect/.a.eobjs/a.impl.all-deps
  [1]
