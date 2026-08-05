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
  emit int64, 0

echo vm.run, 's'

echo read[int64](vm.stack, 0)