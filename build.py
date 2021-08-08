import sys
import subprocess
import os

def compile(lib, filename, compile_folder):
	cmd = "ghdl -a --std=08 --workdir={} --work={} {}".format(compile_folder, lib, filename)
	# print(cmd)
	subprocess.run(cmd)

def run_tb(lib, filename, compile_folder):
	cmd = "ghdl -e --std=08 --workdir={} --work={} {}".format(compile_folder, lib, filename)
	# print(cmd)
	subprocess.run(cmd)
	cmd = "ghdl -r --std=08 --workdir={} --work={} {} --vcd={}.vcd".format(compile_folder, lib, filename, filename)
	# print(cmd)
	subprocess.run(cmd)


# for i in range(len(sys.argv)):
# 	print(sys.argv[i])

filename = sys.argv[1]
path = sys.argv[2]
cmd = sys.argv[3]
compile_folder = sys.argv[4] + "\\build"

if not os.path.exists(compile_folder):
	os.makedirs(compile_folder)


library = "work"
for folder in path.split("\\"):
	#print(folder)
	if "_lib" in folder:
		library = folder

# print(library)


if cmd == "compile":
	compile(library, filename, compile_folder)
elif cmd == "run_tb":
	run_tb(library, filename, compile_folder)