import std/macros

type
  VMState = ref object
    bytecode: seq[byte]
    pc: uint64

    stack: seq[byte]
    sp: uint64

template read[T](container: seq[byte], offset: uint64): T =
  (cast[ptr T](container[offset].unsafeAddr))[]

template write[T](container: seq[byte], offset: uint64, value: T) =
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
      `newBody`

    let `name` = opcodeCounter
    opcodeCounter.inc
    dispatch[`name`] = cast[pointer](`procName`)

register PUSH:
  push[int64](state, fetch[int64](state))

register ADD:
  let b = pop[int64](state)
  push[int64](state, pop[int64](state) + b)

when isMainModule:
  let vm = VMState(
    bytecode: newSeq[byte](19),
    stack: newSeq[byte](1024)
  )
  
  write(vm.bytecode, 0, PUSH.uint8)
  write(vm.bytecode, 1, 10'i64)
  write(vm.bytecode, 9, PUSH.uint8)
  write(vm.bytecode, 10, 20'i64)
  write(vm.bytecode, 18, ADD.uint8)
  
  while vm.pc < uint64(vm.bytecode.len):
    let op = vm.bytecode[vm.pc].int
    vm.pc += 1
    cast[proc(vm: VMState) {.nimcall.}](dispatch[op])(vm)
  
  echo pop[int64](vm)