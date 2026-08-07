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
  inst I_IPUSH; imm 0
  inst I_IPUSH; imm 0
  inst I_IPOKE; ptr 1; imm 10
  inst I_PEEKX; ptr 1
  inst I_ADDX; imm 6
  inst I_POKEX; ptr 1

echo vm.run()

echo vm.X