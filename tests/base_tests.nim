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