import core

let vm = VMState(
  running: true,
  bytecode: newSeq[byte](0xFFFF),
  pc: 0,
  stack: newSeq[byte](0xFFFF),
  sp: 0,
  callStack: newSeq[uint64](0xFFF),
  memory: newSeq[byte](0xFFFF),
  X: 0, Y: 0, A: 0
)

code vm.bytecode:
  label start

echo vm.run(false)