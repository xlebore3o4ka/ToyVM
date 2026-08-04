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

suite "ToyVM Memory tests - STI operations":

  setup:
    vm = newVM()

  test "STI simple value":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 42
      emit uint8, I_STI
      emit uint64, 100

    run(vm)

    let res = read[int64](vm.memory, 100)
    check res == 42

  test "STI negative value":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, -100
      emit uint8, I_STI
      emit uint64, 200

    run(vm)

    let res = read[int64](vm.memory, 200)
    check res == -100

  test "STI zero":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 0
      emit uint8, I_STI
      emit uint64, 300

    run(vm)

    let res = read[int64](vm.memory, 300)
    check res == 0

  test "STI overwrite memory":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_STI
      emit uint64, 400
      emit uint8, I_PUSH
      emit int64, 20
      emit uint8, I_STI
      emit uint64, 400

    run(vm)

    let res = read[int64](vm.memory, 400)
    check res == 20

  test "STI different addresses":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 100
      emit uint8, I_STI
      emit uint64, 500
      emit uint8, I_PUSH
      emit int64, 200
      emit uint8, I_STI
      emit uint64, 600

    run(vm)

    let res1 = read[int64](vm.memory, 500)
    let res2 = read[int64](vm.memory, 600)
    check res1 == 100
    check res2 == 200

  test "STI max int64":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, int.high
      emit uint8, I_STI
      emit uint64, 800

    run(vm)

    let res = read[int64](vm.memory, 800)
    check res == int.high

  test "STI min int64":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, int.low
      emit uint8, I_STI
      emit uint64, 900

    run(vm)

    let res = read[int64](vm.memory, 900)
    check res == int.low

suite "ToyVM Memory tests - LDI operations":

  setup:
    vm = newVM()

  test "LDI simple value":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 42
      emit uint8, I_STI
      emit uint64, 100
      emit uint8, I_LDI
      emit uint64, 100
      emit uint8, I_RET

    run(vm)

    let res = read[int64](vm.stack, 0)
    check res == 42

  test "LDI negative value":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, -100
      emit uint8, I_STI
      emit uint64, 200
      emit uint8, I_LDI
      emit uint64, 200
      emit uint8, I_RET

    run(vm)

    let res = read[int64](vm.stack, 0)
    check res == -100

  test "LDI zero":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 0
      emit uint8, I_STI
      emit uint64, 300
      emit uint8, I_LDI
      emit uint64, 300
      emit uint8, I_RET

    run(vm)

    let res = read[int64](vm.stack, 0)
    check res == 0

  test "LDI after overwrite":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 10
      emit uint8, I_STI
      emit uint64, 400
      emit uint8, I_PUSH
      emit int64, 20
      emit uint8, I_STI
      emit uint64, 400
      emit uint8, I_LDI
      emit uint64, 400
      emit uint8, I_RET

    run(vm)

    let res = read[int64](vm.stack, 0)
    check res == 20

  test "LDI from different addresses":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, 100
      emit uint8, I_STI
      emit uint64, 500
      emit uint8, I_PUSH
      emit int64, 200
      emit uint8, I_STI
      emit uint64, 600
      emit uint8, I_LDI
      emit uint64, 500
      emit uint8, I_RET

    run(vm)

    let res = read[int64](vm.stack, 0)
    check res == 100

  test "LDI max int64":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, int.high
      emit uint8, I_STI
      emit uint64, 800
      emit uint8, I_LDI
      emit uint64, 800
      emit uint8, I_RET

    run(vm)

    let res = read[int64](vm.stack, 0)
    check res == int.high

  test "LDI min int64":
    code vm.bytecode:
      emit uint8, I_PUSH
      emit int64, int.low
      emit uint8, I_STI
      emit uint64, 900
      emit uint8, I_LDI
      emit uint64, 900
      emit uint8, I_RET

    run(vm)

    let res = read[int64](vm.stack, 0)
    check res == int.low