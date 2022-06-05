@echo off
if exist ".\build" (
    echo [90mINFO: [37mbuild dir found[31m
) else (
    echo [90mINFO: [37mcreating build dir...[31m
    mkdir build
)
echo [90mINFO: [37massembling code into object file...[31m
nasm -f win64 src/main.asm -o build\main.obj
echo [90mINFO: [37mlinking object file into executable...[91m
link /largeaddressaware /wx /nologo /entry:start /subsystem:console "%~dp0build\main.obj" kernel32.lib /out:"%~dp0build\main.exe"

if %errorlevel%==0 (
    echo|set /p=[90mINFO: [37mbuild [32mfinished[37m successfully[0m
) else echo|set /p=[90mINFO: [37mbuild [31mfailed[37m, error encountered[0m