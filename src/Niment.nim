# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import Nimentpkg/submodule


type
  State* = enum
    eAlive
    eDead

  EntId* = int

  Ent* = object
    state: State

type World* = ref object
  ents: seq[Ent]


when isMainModule:
  echo(getWelcomeMessage())
