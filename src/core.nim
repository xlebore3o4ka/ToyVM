import std/[macros, times]

type
  VMState* {.acyclic.} = ref object
    running*: bool

    bytecode*: seq[byte]
    pc*: uint64

    stack*: seq[byte]
    sp*: uint64

    memory*: seq[byte]

    X*: int64
    Y*: int64
    A*: int64

template read*[T](container: seq[byte], offset: uint64): T =
  (cast[ptr T](container[offset].unsafeAddr))[]

template write*[T](container: seq[byte], offset: uint64, value: T) =
  (cast[ptr T](container[offset].unsafeAddr))[] = value

template fetch[T](state: VMState): T =
  let pc = state.pc
  state.pc += uint64(sizeof(T))
  (cast[ptr T](state.bytecode[pc].unsafeAddr))[]

template fetchImm*(state: VMState): int64 =
  fetch[int64](state)

template fetchPtr*(state: VMState): uint64 =
  fetch[uint64](state) * 8

template fetchAddr*(state: VMState): uint64 =
  fetch[uint64](state)

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

register RET:
  state.running = false

register IX:
  state.X = state.fetchImm()

register IY:
  state.Y = state.fetchImm()

register IA:
  state.A = state.fetchImm()

register TXY:
  state.X = state.Y

register TYX:
  state.Y = state.X

register TXA:
  state.X = state.A

register TYA:
  state.Y = state.A

register TAX:
  state.A = state.X

register TAY:
  state.A = state.Y

register SWAPXY:
  swap state.X, state.Y

register SWAPXA:
  swap state.X, state.A

register SWAPYA:
  swap state.Y, state.A

register ADD:
  state.A = state.X + state.Y

register SUB:
  state.A = state.X - state.Y

register MUL:
  state.A = state.X * state.Y

register DIV:
  state.A = state.X div state.Y

register MOD:
  state.A = state.X mod state.Y

register AND:
  state.A = state.X and state.Y

register OR:
  state.A = state.X or state.Y

register XOR:
  state.A = state.X xor state.Y

register SHL:
  state.A = state.X shl (state.Y and 63)

register SHR:
  state.A = state.X shr (state.Y and 63)

register GT:
  state.A = int64(state.X > state.Y)

register LT:
  state.A = int64(state.X < state.Y)

register GE:
  state.A = int64(state.X >= state.Y)

register LE:
  state.A = int64(state.X <= state.Y)

register EQ:
  state.A = int64(state.X == state.Y)

register NE:
  state.A = int64(state.X != state.Y)

proc replaceRegister(n: NimNode, rsym: NimNode): NimNode =
  if n.kind == nnkIdent and $n == "R":
    return rsym

  result = copyNimTree(n)
  for i in 0..<n.len:
    result[i] = replaceRegister(n[i], rsym)

macro registerRegFamily(name, body: untyped): untyped =
  let registerSet = ["X", "Y", "A"]

  result = newStmtList()

  for r in registerSet:
    let newName = ident($name & r)
    let rsym = genSym(nskParam, r)
    let newBody = replaceRegister(body, rsym)

    result.add quote do:
      register `newName`:
        `newBody`

registerRegFamily ADD:
  state.R = state.R + state.fetchImm()

registerRegFamily SUB:
  state.R = state.R - state.fetchImm()

registerRegFamily MUL:
  state.R = state.R * state.fetchImm()

registerRegFamily DIV:
  state.R = state.R div state.fetchImm()

registerRegFamily MOD:
  state.R = state.R mod state.fetchImm()

registerRegFamily AND:
  state.R = state.R and state.fetchImm()

registerRegFamily OR:
  state.R = state.R or state.fetchImm()

registerRegFamily XOR:
  state.R = state.R xor state.fetchImm()

registerRegFamily SHL:
  state.R = state.R shl (state.fetchImm() and 63)

registerRegFamily SHR:
  state.R = state.R shr (state.fetchImm() and 63)

registerRegFamily GT:
  state.R = int64(state.R > state.fetchImm())

registerRegFamily LT:
  state.R = int64(state.R < state.fetchImm())

registerRegFamily GE:
  state.R = int64(state.R >= state.fetchImm())

registerRegFamily LE:
  state.R = int64(state.R <= state.fetchImm())

registerRegFamily EQ:
  state.R = int64(state.R == state.fetchImm())

registerRegFamily NE:
  state.R = int64(state.R != state.fetchImm())

registerRegFamily NOT:
  state.R = not state.R

registerRegFamily BNOT:
  state.R = int64(state.R == 0)

registerRegFamily ABS:
  state.R = abs(state.R)

registerRegFamily NEG:
  state.R = -state.R

registerRegFamily JMP:
  state.pc = uint64(state.R)

macro code*(name: untyped, body: untyped): untyped =
  var res = newStmtList()
  let pos = genSym(nskVar, "pos")

  res.add quote do:
    var `pos` = 0

  for stmt in body:
    if stmt.kind != nnkCommand or stmt[0].kind != nnkIdent:
      error("Expected 'inst', 'imm', 'ptr' or 'addr'", stmt)
    
    let val = stmt[1]
    var typ: NimNode

    if $stmt[0] == "inst":
      typ = bindSym("uint8")
    elif $stmt[0] == "imm":
      typ = bindSym("int64")
    elif $stmt[0] == "ptr" or $stmt[0] == "addr":
      typ = bindSym("uint64")
    else:
      error("Expected 'inst', 'imm', 'ptr' or 'addr'", stmt)
    
    res.add quote do:
      write[`typ`](`name`, `pos`.uint64, `val`)
      `pos` += sizeof(`typ`)

  res
