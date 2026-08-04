import std/macros

type
  VMState* = ref object
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

proc run*(state: VMState) =
  while state.running:
    let opcode = fetch[uint8](state)
    cast[proc(state: VMState) {.nimcall.}](dispatch[opcode])(state)

proc replaceState(n: NimNode, sym: NimNode): NimNode =
  if n.kind == nnkIdent and $n == "state":
    return sym

  result = copyNimTree(n)
  for i in 0..<n.len:
    result[i] = replaceState(n[i], sym)

macro register(name, body: untyped): untyped =
  let procName = ident("handle_" & $name)
  let stateSym = genSym(nskParam, "state")

  let newBody = replaceState(body, stateSym)

  result = quote do:
    proc `procName`(`stateSym`: VMState) {.nimcall.} =
      {.push checks: off.}
      `newBody`
      {.pop.}

    let `name`* = uint8(opcodeCounter)
    opcodeCounter.inc
    dispatch[`name`] = cast[pointer](`procName`)

register RET:
  state.running = false

register PUSH:
  push[int64](state, fetch[int64](state))

register ADD:
  let b = pop[int64](state)
  push[int64](state, pop[int64](state) + b)

register SUB:
  let b = pop[int64](state)
  push[int64](state, pop[int64](state) - b)

register MUL:
  let b = pop[int64](state)
  push[int64](state, pop[int64](state) * b)

register DIV:
  let b = pop[int64](state)
  push[int64](state, pop[int64](state) div b)

register MOD:
  let b = pop[int64](state)
  push[int64](state, pop[int64](state) mod b)

register GT:
  let b = pop[int64](state)
  push[bool](state, pop[int64](state) > b)

register LT:
  let b = pop[int64](state)
  push[bool](state, pop[int64](state) < b)

register GTE:
  let b = pop[int64](state)
  push[bool](state, pop[int64](state) >= b)

register LTE:
  let b = pop[int64](state)
  push[bool](state, pop[int64](state) <= b)

register EQ:
  let b = pop[int64](state)
  push[bool](state, pop[int64](state) == b)

register NEQ:
  let b = pop[int64](state)
  push[bool](state, pop[int64](state) != b)

register STI:
  let offset = fetch[uint64](state)
  write[int64](state.memory, offset, pop[int64](state))

register LDI:
  let offset = fetch[uint64](state)
  push[int64](state, read[int64](state.memory, offset))

macro code*(name: untyped, body: untyped): untyped =
  var res = newStmtList()
  var pos = 0
  
  for stmt in body:
    if stmt.kind != nnkCommand or stmt[0].kind != nnkIdent or $stmt[0] != "emit":
      error("Expected 'emit type, value'", stmt)
      
    let typ = stmt[1]
    let val = stmt[2]
    
    res.add quote do:
      write[`typ`](`name`, `pos`.uint64, `val`)
    
    pos += sizeof(`typ`)
  
  res