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

  test "RET":
    code vm.bytecode:
      emit uint8, I_RET
    
    run(vm)
    
    check vm.running == false

  test "PUSH 10":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_RET
    
    run(vm)

    let res = read[int64](vm.stack, 0)
    check res == 10

  test "ADD consts":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_PUSH
      emit int64, 20
      emit uint8, I_ADD
      emit uint8, I_RET
    
    run(vm)

    let res = read[int64](vm.stack, 0)
    check res == 30

  test "SUB consts":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 15
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_SUB
      emit uint8, I_RET
    
    run(vm)

    let res = read[int64](vm.stack, 0)
    check res == 5

  test "MUL consts":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 15
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_MUL
      emit uint8, I_RET
    
    run(vm)

    let res = read[int64](vm.stack, 0)
    check res == 150

  test "DIV consts":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 30
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_DIV
      emit uint8, I_RET
    
    run(vm)

    let res = read[int64](vm.stack, 0)
    check res == 3

  test "DIV consts non-integer":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 43
      emit uint8, I_PUSH
      emit int64, 3
      emit uint8, I_DIV
      emit uint8, I_RET
    
    run(vm)

    let res = read[int64](vm.stack, 0)
    check res == 14

  test "MOD consts":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 42
      emit uint8, I_PUSH
      emit int64, 3
      emit uint8, I_MOD
      emit uint8, I_RET
    
    run(vm)

    let res = read[int64](vm.stack, 0)
    check res == 0

  test "MOD consts non-zero":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 23
      emit uint8, I_PUSH
      emit int64, 8
      emit uint8, I_MOD
      emit uint8, I_RET
    
    run(vm)

    let res = read[int64](vm.stack, 0)
    check res == 7

  test "ADD consts overflow":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, int64.high
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_ADD
      emit uint8, I_RET
    
    run(vm)

    let res = read[int64](vm.stack, 0)
    check res == 8 - int64.high

  test "SUB consts overflow":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, int64.low
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_SUB
      emit uint8, I_RET
    
    run(vm)

    let res = read[int64](vm.stack, 0)
    check res == int64.high - 9

  test "MUL consts overflow":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, int64.high
      emit uint8, I_PUSH
      emit int64, 2
      emit uint8, I_MUL
      emit uint8, I_RET
    
    run(vm)

    let res = read[int64](vm.stack, 0)
    check res == -2