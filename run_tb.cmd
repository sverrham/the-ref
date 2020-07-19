@echo off
set filename=%1
set folder=%2
set task=%3

for /F "tokens=2,3 delims=\" %%A in ("%folder%") do (
    set f1="%%A"
    set f2="%%B"
) 

set lib="work"
if %f1% == "lib" (
    set lib=%f2%
)

if %task% == 1 (
    goto run_tb
)

@echo on
ghdl -a --std=08 --work=%lib% %filename%
@echo off
goto:eof

:run_tb
@echo on
ghdl -e --std=08 --work=%lib% %filename%
ghdl -r --std=08 --work=%lib% %filename% --vcd=wave.vcd
