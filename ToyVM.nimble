# Package

version       = "0.1.0"
author        = "xlebore3o4ka"
description   = "Toy virtual machine"
license       = "LGPL-3.0-only"
srcDir        = "src"
binDir        = "bin"
bin           = @["ToyVM"]


# Dependencies

requires "nim >= 2.2.10"

task test, "Run all tests from tests folder":
  exec "nim r tests/runner.nim"