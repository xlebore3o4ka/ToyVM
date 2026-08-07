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
  inst I_IJMP; addr start

  label add

  inst I_PUSHX
  inst I_PUSHY
  inst I_PUSHA

  inst I_PEEKY; ptr 4
  inst I_PEEKX; ptr 5
  inst I_ADD
  inst I_POKEA; ptr 5

  inst I_POPA
  inst I_POPY
  inst I_POPX
  inst I_POP

  inst I_RET

  label start

  inst I_IPUSH; imm 10
  inst I_IPUSH; imm 20
  inst I_CALL; addr add

echo vm.run(true)

echo vm.stack[0]