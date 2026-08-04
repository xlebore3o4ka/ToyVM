import unittest
import core

var vm: VMState

suite "ToyVM Base tests":
  setup:
    vm = VMState(
      running: true,
      bytecode: newSeq[byte](0xFFFF),
      pc: 0,
      stack: newSeq[byte](0xFF),
      sp: 0,
      memory: newSeq[byte](0xFFFF)
    )

  test "PUSH 10":
    code vm.bytecode:
      emit uint8, PUSH
      emit int64, 10
      emit uint8, RET
    
    run(vm)
    
    check vm.sp == 8
    let res = read[int64](vm.stack, 0)
    check res == 10
    check vm.running == false