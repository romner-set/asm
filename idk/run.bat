@echo off
echo assembling...
echo.
nasm -f win64 idk.asm
echo linking...
echo.
link /entry:start /subsystem:console idk.obj kernel32.lib
echo running...
echo.
idk.exe