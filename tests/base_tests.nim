import unittest
import core

var vm: VMState

proc newVM(): VMState = VMState(
      running: true,
      bytecode: newSeq[byte](0xFFFF),
      pc: 0,
      stack: newSeq[byte](0xFF),
      sp: 0,
      memory: newSeq[byte](0xFFFF)
    )

suite "ToyVM Base tests":

  setup:
    vm = newVM()

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

suite "ToyVM Base tests: ALU":
  
  setup:
    vm = newVM()

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

suite "ToyVM Base tests: extreme cases":
  
  setup:
    vm = newVM()

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

suite "ToyVM Base tests: comparisons":
  
  setup:
    vm = newVM()

  test "EQ consts true":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_EQ
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check res

  test "EQ consts false":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_PUSH
      emit int64, 20
      emit uint8, I_EQ
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check not res

  test "NEQ consts true":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_PUSH
      emit int64, 20
      emit uint8, I_NEQ
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check res

  test "NEQ consts false":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_NEQ
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check not res

  test "GT consts true":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 20
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_GT
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check res

  test "GT consts false":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_PUSH
      emit int64, 20
      emit uint8, I_GT
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check not res

  test "LT consts true":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_PUSH
      emit int64, 20
      emit uint8, I_LT
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check res

  test "LT consts false":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 20
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_LT
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check not res

  test "GTE consts true":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 20
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_GTE
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check res

  test "GTE consts false":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_PUSH
      emit int64, 20
      emit uint8, I_GTE
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check not res

  test "LTE consts true":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_PUSH
      emit int64, 20
      emit uint8, I_LTE
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check res

  test "LTE consts false":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 20
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_LTE
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check not res

suite "ToyVM Base tests: comparison in extreme cases":

  setup:
    vm = newVM()

  test "EQ both zero":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 0
      emit uint8, I_PUSH
      emit int64, 0
      emit uint8, I_EQ
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check res

  test "NEQ both zero":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 0
      emit uint8, I_PUSH
      emit int64, 0
      emit uint8, I_NEQ
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check not res

  test "GT both equal positive":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 42
      emit uint8, I_PUSH
      emit int64, 42
      emit uint8, I_GT
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check not res

  test "LT both equal positive":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 42
      emit uint8, I_PUSH
      emit int64, 42
      emit uint8, I_LT
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check not res

  test "GTE both equal positive":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 42
      emit uint8, I_PUSH
      emit int64, 42
      emit uint8, I_GTE
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check res

  test "LTE both equal positive":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 42
      emit uint8, I_PUSH
      emit int64, 42
      emit uint8, I_LTE
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check res

  test "GT both equal negative":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, -42
      emit uint8, I_PUSH
      emit int64, -42
      emit uint8, I_GT
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check not res

  test "LT both equal negative":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, -42
      emit uint8, I_PUSH
      emit int64, -42
      emit uint8, I_LT
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check not res

  test "GTE both equal negative":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, -42
      emit uint8, I_PUSH
      emit int64, -42
      emit uint8, I_GTE
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check res

  test "LTE both equal negative":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, -42
      emit uint8, I_PUSH
      emit int64, -42
      emit uint8, I_LTE
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check res

  test "GT max int64 vs min int64":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, int.high
      emit uint8, I_PUSH
      emit int64, int.low
      emit uint8, I_GT
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check res

  test "LT max int64 vs min int64":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, int.high
      emit uint8, I_PUSH
      emit int64, int.low
      emit uint8, I_LT
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check not res

  test "GTE max int64 vs min int64":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, int.high
      emit uint8, I_PUSH
      emit int64, int.low
      emit uint8, I_GTE
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check res

  test "LTE max int64 vs min int64":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, int.high
      emit uint8, I_PUSH
      emit int64, int.low
      emit uint8, I_LTE
      emit uint8, I_RET

    run(vm)

    let res = read[bool](vm.stack, 0)
    check not res