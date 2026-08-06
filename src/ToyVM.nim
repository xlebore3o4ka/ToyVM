import core

let vm = VMState(
  running: true,
  bytecode: newSeq[byte](0xFFFF),
  pc: 0,
  stack: newSeq[byte](0xFF),
  sp: 0,
  memory: newSeq[byte](0xFFFF),
  X: 0, Y: 0, A: 0
)

code vm.bytecode:
  inst I_IA; imm 10
  inst I_MULA; imm 5

echo vm.run, 's'

echo vm.A