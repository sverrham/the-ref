@echo off
set file=%1

For %%A in ("%file%") do (
    set name=%%~nA
)
@echo on
ghdl -e %name%
ghdl -r %name%