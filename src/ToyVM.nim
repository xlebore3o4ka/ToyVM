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
  inst I_IX; imm 10
  inst I_MULX; imm 5
  inst I_IA; ptr 10
  inst I_ASTX

echo vm.run, 's'

echo vm.memory[0..15]