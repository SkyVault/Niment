# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import variant, tables, options, sets

type
  State* = enum
    eDead
    eAlive

  EntId* = int

  Ent* = object
    id: EntId
    state: State
    compSet: Table[TypeId, int]

type
  AbstractCompContainer = ref object of RootObj
  CompContainer* [T] = ref object of AbstractCompContainer
    list: seq[T]

  World* = ref object
    ents: seq[Ent]
    components: Table[TypeId, AbstractCompContainer]

proc makeWorld* (): World =
  result = World(ents: newSeq[Ent](),
                 components: initTable[TypeId, AbstractCompContainer]())

proc findFreeComp [T] (cc: CompContainer[T]): int =
  var index = 0
  for c in cc.list:
    if c == nil: return index
    else: inc index
  cc.list.setLen(cc.list.len() + 1)
  return index

proc findDeadEnt (world: World): EntId =
  var index = 0
  for e in world.ents:
    if e.state == eDead: return index
    inc index
  world.ents.setLen(world.ents.len() + 1)
  return index

proc spawn* (world: World): EntId {.discardable.} =
  let id = findDeadEnt(world)
  world.ents[id].id = id
  world.ents[id].state = eAlive
  world.ents[id].compSet.clear()
  return id

proc kill* (world: World, id: EntId) =
  world.ents[id].state = eDead
  for cid, index in world.ents[id].compSet.pairs:
    cast[CompContainer[nil]](world.components[cid]).list[index] = nil

proc add* [T] (world: World, id: EntId, comp: T): T {.discardable.} =
  result = comp

  const cid = getTypeId(T)
  if not contains(world.components, cid):
    world.components[cid] = CompContainer[T]()

  var index = findFreeComp[T](cast[CompContainer[T]](world.components[cid]))
  cast[CompContainer[T]](world.components[cid]).list[index] = comp
  world.ents[id].compSet[cid] = index

proc get* [T] (world: World, id: EntId): T =
  const cid = getTypeId(T)
  if not world.ents[id].compSet.contains(cid): return nil
  let index = world.ents[id].compSet[cid]
  return cast[CompContainer[T]](world.components[cid]).list[index]

proc has* (world: World, id: EntId, cid: TypeId): bool =
  world.ents[id].compSet.contains(cid)

iterator each* (world: World, comps: varargs[TypeId]): EntId =
  for e in world.ents:
    if e.state == eDead: continue
    var match = true
    for cid in comps:
      if not has(world, e.id, cid):
        match = false
    if match:
      yield e.id

iterator each* (world: World, comps: seq[TypeId]): EntId =
  for e in world.ents:
    if e.state == eDead: continue
    var match = true
    for cid in comps:
      if not has(world, e.id, cid):
        match = false
    if match:
      yield e.id

iterator each* [A](world: World): EntId =
  const cid = getTypeId(A)
  for e in world.ents:
    if e.state == eDead: continue
    if has(world, e.id, cid): yield e.id

proc id* [T] (): TypeId = getTypeId(T)

when isMainModule:
  type B = ref object
    x, y: float

  type P = ref object
    vx, vy: float

  let world = makeWorld()

  let ent = world.spawn()
  add(world, ent, B(x: 32, y: 12))
  add(world, ent, P(vx: 12.3, vy: 1.2))
