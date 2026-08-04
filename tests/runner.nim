import os

for file in walkFiles("tests/*.nim"):
  if file != "tests/runner.nim":
    echo "Running ", file
    discard execShellCmd("nim r " & file)