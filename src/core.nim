import std/[macros, times]

type
  VMState* {.acyclic.} = ref object
    running*: bool

    bytecode*: seq[byte]
    pc*: uint64

    stack*: seq[byte]
    sp*: uint64

    memory*: seq[byte]

template read*[T](container: seq[byte], offset: uint64): T =
  (cast[ptr T](container[offset].unsafeAddr))[]

template write*[T](container: seq[byte], offset: uint64, value: T) =
  (cast[ptr T](container[offset].unsafeAddr))[] = value

template fetch[T](state: VMState): T =
  let pc = state.pc
  state.pc += uint64(sizeof(T))
  (cast[ptr T](state.bytecode[pc].unsafeAddr))[]

proc push[T](state: VMState, value: T) {.inline.} =
  let size = sizeof(T)
  let len = state.stack.len
  if state.sp + uint64(size) > uint64(len):
    state.stack.setLen(len * 2)
  (cast[ptr T](state.stack[state.sp].unsafeAddr))[] = value
  state.sp += uint64(size)

template pop[T](state: VMState): T =
  state.sp -= uint64(sizeof(T))
  (cast[ptr T](state.stack[state.sp].unsafeAddr))[]

var dispatch: array[256, pointer]
var opcodeCounter {.compileTime.} = 0

proc run*(state: VMState): float =
  let start = cpuTime()
  while state.running:
    let opcode = fetch[uint8](state)
    cast[proc(state: VMState) {.nimcall.}](dispatch[opcode])(state)
  return cpuTime() - start

proc replaceState(n: NimNode, sym: NimNode): NimNode =
  if n.kind == nnkIdent and $n == "state":
    return sym

  result = copyNimTree(n)
  for i in 0..<n.len:
    result[i] = replaceState(n[i], sym)

macro register(name, body: untyped): untyped =
  let procName = ident("handle_" & $name)
  let stateSym = genSym(nskParam, "state")
  let constName = ident("I_" & $name)

  let newBody = replaceState(body, stateSym)

  result = quote do:
    proc `procName`(`stateSym`: VMState) {.nimcall.} =
      {.push checks: off.}
      `newBody`
      {.pop.}

    let `constName`* = uint8(opcodeCounter)
    opcodeCounter.inc
    dispatch[`constName`] = cast[pointer](`procName`)

macro registerBitnessFamily*(name, body: untyped): untyped =
  result = newStmtList()

  let suffixes = ["B", "W", "D", "Q"]
  let types = [
    ident("uint8"),
    ident("int16"),
    ident("int32"),
    ident("int64")
  ]

  for i in 0..<suffixes.len:
    let opcode = ident($name & suffixes[i])
    let T = types[i]

    result.add quote do:
      register `opcode`:
        type T {.inject.} = `T`

        `body`

register RET:
  state.running = false

registerBitnessFamily PUSH:
  push[T](state, fetch[T](state))

registerBitnessFamily ADD:
  let rhs = pop[T](state)
  let lhs = pop[T](state)
  push[T](state, lhs + rhs)

registerBitnessFamily SUB:
  let rhs = pop[T](state)
  let lhs = pop[T](state)
  push[T](state, lhs - rhs)

registerBitnessFamily MUL:
  let rhs = pop[T](state)
  let lhs = pop[T](state)
  push[T](state, lhs * rhs)

registerBitnessFamily DIV:
  let rhs = pop[T](state)
  let lhs = pop[T](state)
  push[T](state, lhs div rhs)

macro instMODHELPER_shiftForType(T: typedesc): untyped =
  let typeNode = T.getType()
  let typeSize = typeNode.getSize()
  
  let shiftValue = typeSize * 8 - 1
  
  result = newLit(shiftValue)

registerBitnessFamily MOD:
  let rhs = pop[T](state)
  let lhs = pop[T](state)
  let m = lhs mod rhs
  let mask = m shr (instMODHELPER_shiftForType(T))
  push[T](state, m + (rhs and mask))

macro code*(name: untyped, body: untyped): untyped =
  var res = newStmtList()
  let pos = genSym(nskVar, "pos")

  res.add quote do:
    var `pos` = 0

  for stmt in body:
    if stmt.kind != nnkCommand or stmt[0].kind != nnkIdent or $stmt[0] != "emit":
      error("Expected 'emit type, value'", stmt)
      
    let typ = stmt[1]
    let val = stmt[2]
    
    res.add quote do:
      write[`typ`](`name`, `pos`.uint64, `val`)
      `pos` += sizeof(`typ`)

  res
