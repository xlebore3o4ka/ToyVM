import core

let vm = VMState(
  running: true,
  bytecode: newSeq[byte](0xFFFF),
  pc: 0,
  stack: newSeq[byte](0xFF),
  sp: 0,
  memory: newSeq[byte](0xFFFF)
)

code vm.bytecode:
  emit uint8, I_PUSH
  emit int64, 1
  emit uint8, I_PUSH
  emit int64, 0
  emit uint8, I_DIV

vm.run