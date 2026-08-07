import core
import std/random

let vm = VMState(
  running: true,
  bytecode: newSeq[byte](0xFFFF),
  pc: 0,
  stack: newSeq[byte](0xFF),
  sp: 0,
  memory: newSeq[byte](0xFFFF),
  X: 0, Y: 0, A: 0
)
randomize()
let seed = rand(1000)
code vm.bytecode:
  inst I_IX; imm 1000000
  inst I_IY; imm seed

  label loop
  inst I_ADD
  inst I_TYA
  inst I_TAX
  inst I_IX; imm 10
  inst I_XSTY
  inst I_TXA
  inst I_LOOPX; addr loop

echo vm.run()

echo vm.Y