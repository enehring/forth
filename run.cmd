@echo off

set os_bin="hello.img"

REM Clean
del %os_bin%

REM Build
set nasm="C:\Users\evand\AppData\Local\bin\NASM\nasm.exe"
%nasm% -o boot_i386.img boot_i386.asm
%nasm% -o payload_i386.img payload_i386.asm

type boot_i386.img payload_i386.img > %os_bin%

REM Run
set qemu_i386="C:\Program Files\qemu\qemu-system-i386.exe"
%qemu_i386% -hda %os_bin%
