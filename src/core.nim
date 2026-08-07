import std/[macros, tables, monotimes, times]
export tables

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

template skipAddr*(state: VMState) =
  state.pc += uint64(sizeof(uint64))

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
var opcodeToName*: seq[string]
opcodeToName.setLen(256)

proc run*(state: VMState, debug: static[bool] = false): Duration =
  let start = getMonoTime()
  var tact: uint64 = 0

  while state.running:
    let pc = state.pc
    state.pc += uint64(sizeof(uint8))
    let opcode = (cast[ptr uint8](state.bytecode[pc].unsafeAddr))[]
    cast[proc(state: VMState) {.nimcall.}](dispatch[opcode])(state)
    
    when debug:
      echo "tact: ", tact, " pc=", pc, " inst=", opcodeToName[opcode], " sp=", state.sp, " X=", state.X, " Y=", state.Y, " A=", state.A
      tact.inc

  return getMonoTime() - start

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
    opcodeToName[opcodeCounter] = astToStr(`constName`)
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

proc replaceIdent(n: NimNode, newSym: NimNode, oldName: string = "R"): NimNode =
  if n.kind == nnkIdent and $n == oldName:
    return newSym

  result = copyNimTree(n)
  for i in 0..<n.len:
    result[i] = replaceIdent(n[i], newSym, oldName)

macro registerRegFamily(name, body: untyped): untyped =
  let registerSet = ["X", "Y", "A"]

  result = newStmtList()

  for r in registerSet:
    let newName = ident($name & r)
    let rsym = genSym(nskParam, r)
    let newBody = replaceIdent(body, rsym)

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

register IJMP:
  state.pc = state.fetchAddr()

registerRegFamily IJT:
  if bool(state.R): state.pc = state.fetchAddr()
  else: state.skipAddr()

registerRegFamily IJF:
  if not bool(state.R): state.pc = state.fetchAddr()
  else: state.skipAddr()

registerRegFamily INC:
  state.R.inc

registerRegFamily DEC:
  state.R.dec

macro registerRegPair(name, body: untyped): untyped =
  let registers = ["X", "Y", "A"]
  result = newStmtList()

  for destR in registers:
    for srcR in registers:
      if destR != srcR:
        let destSym = genSym(nskParam, destR)
        let srcSym = genSym(nskParam, srcR)
        let instName = ident(destR & $name & srcR)
        
        var newBody = body
        newBody = replaceIdent(newBody, destSym, "destR")
        newBody = replaceIdent(newBody, srcSym, "srcR")
        
        result.add quote do:
          register `instName`:
            `newBody`

registerRegPair LD:
  state.destR = read[int64](state.memory, uint64(state.srcR))

registerRegPair ST:
  write[int64](state.memory, uint(state.destR), int64(state.srcR))

registerRegFamily LOOP:
  if bool(state.R):
    state.R.dec
    state.pc = state.fetchAddr()
  else: state.skipAddr()

macro code*(name: untyped, body: untyped): untyped =

  var res = newStmtList()
  let pos = genSym(nskVar, "pos")
  var labelTable: Table[string, NimNode]

  res.add quote do:
    var `pos`: uint64 = 0

  for stmt in body:
    var typ: NimNode
    var val: NimNode

    if stmt.kind == nnkCommand:
      let cmd = stmt[0]
      val = stmt[1]

      if $cmd == "inst":
        typ = bindSym("uint8")
      elif $cmd == "imm":
        typ = bindSym("int64")
      elif $cmd == "addr":
        typ = bindSym("uint64")
      elif $cmd == "label":
        let lbl = genSym(nskLet, $val)
        res.add quote do:
          let `lbl` = `pos`
        labelTable[$val] = lbl
        continue
      else:
        error("Expected 'inst', 'imm', 'ptr', 'addr' or 'label'", stmt)
    
    elif stmt.kind == nnkPtrTy:
      typ = bindSym("uint64")
      val = stmt[0]
    
    else:
      error("Expected 'inst', 'imm', 'ptr', 'addr' or 'label'", stmt)
      
    if val.kind in {nnkIdent, nnkSym} and $val in labelTable:
      typ = ident("uint64")
    
    res.add quote do:
      `pos` += uint(sizeof(`typ`))

  res.add quote do:
    `pos` = 0

  for stmt in body:
    var typ: NimNode
    var val: NimNode

    if stmt.kind == nnkCommand:
      let cmd = stmt[0]
      val = stmt[1]

      if $cmd == "inst":
        typ = bindSym("uint8")
      elif $cmd == "imm":
        typ = bindSym("int64")
      elif $cmd == "addr":
        typ = bindSym("uint64")
      elif $cmd == "label":
        continue
      else:
        error("Expected 'inst', 'imm', 'ptr', 'addr' or 'label'", stmt)
    
    elif stmt.kind == nnkPtrTy:
      typ = bindSym("uint64")
      val = stmt[0]
    
    else:
      error("Expected 'inst', 'imm', 'ptr', 'addr' or 'label'", stmt)
      
    if val.kind in {nnkIdent, nnkSym} and $val in labelTable:
      let lblSym = labelTable[$val]
      val = lblSym
    
    res.add quote do:
      write[`typ`](`name`, `pos`.uint64, `val`)
      `pos` += uint(sizeof(`typ`))

  res