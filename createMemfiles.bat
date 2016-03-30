@ECHO OFF

:: File: createMemfiles.bat
:: 
:: Description: Creates the memory initialization files for program and reset (bootcode) memory.
:: 	It defaults to operating on the code in the MIPSfpga\ExamplePrograms\C_Example directory.
::
::	The memory initialization files are used for simulation and synthesis of the 
::	MIPSfpga core on the FPGA boards.
::
:: Date:   7-FEB-2015


SETLOCAL
SETLOCAL enabledelayedexpansion


:::::::::::::::::::::::::::::::::::::::::::
set indir=%1%
if "%indir%"=="" (
  @echo ERROR: You must enter the program directory. & @echo. & @echo Example: & @echo createMemfiles.bat ..\C_Example & exit /b
) else ( 
	set indir=%indir%\
)

set outputdir=%indir%MemoryFiles\
CALL :createMemoryFiles

GOTO :END
:::::::::::::::::::::::::::::::::::::::::::



:::::::::::::::::::::::::::::::::::::::::::
:createMemoryFiles
set outputAddr=1

IF EXIST %outputdir% (
	@echo %outputdir% directory exists
) ELSE (
	@echo mkdir %outputdir%
	mkdir %outputdir%
)

set infile=%indir%FPGA_Ram_modelsim.txt

:: memory initialization file for reset ram
set outfile_boot="%outputdir%ram_reset_init.txt"

:: memory initialization file for program ram
set outfile_program="%outputdir%ram_program_init.txt"

set outfile_bootmif="%outputdir%ram_reset_init.mif"
set outfile_programmif="%outputdir%ram_program_init.mif"


call :makeProgram
call :initMemFiles
call :parseInit
EXIT /B

:::::::::::::::::::::::::::::::::::::::::::
:parseInit
:: skip first 5 lines of file, parse on ":"
FOR /F "tokens=1,2 skip=5 delims=:" %%A IN (%infile%) DO CALL :parseAddrInstr "%%A" "%%B"
EXIT /B


::::::::::::::::::::::::::::::::::::::::::::
:parseAddrInstr
set addr=%1%
set instrline=%2%

set addr=%addr:~1,8%

:: test if addr is an 8-digit hex value:
if not defined addr EXIT /B
set "test=!addr!"
for %%C in (0 1 2 3 4 5 6 7 8 9 A B C D E F) do if defined test set "test=!test:%%C=!"
if defined test (
::  echo Not an instruction address.
  EXIT /B
)
IF defined addr IF "%addr:~7,1%"=="" (
::	echo 7 or less characters
	EXIT /B
)



IF %instrline%=="" (
	set outputAddr=1
	EXIT /B
) 

FOR /F "tokens=* delims= " %%A IN (%instrline%) DO CALL :outputMemFiles %%A %%B %%C %%D

EXIT /B


::::::::::::::::::::::::::::::::::::::::::::
:outputMemFiles
set instr1=%1%
set instr2=%2%
set instr3=%3%
set instr4=%4%

set segnum=%addr:~,1%

IF !segnum! EQU 9 (
	CALL :printOutfile %outfile_boot% %outfile_bootmif%
) ELSE (
	CALL :printOutfile %outfile_program% %outfile_programmif%
)
EXIT /B


::::::::::::::::::::::::::::::::::::::::::::
:printOutfile
set outfile=%1%
set outfile_mif=%2%


:: include only low 5 hex digits of the address
set addr=%addr:~3,5%

set /a addrDec=0x%addr%
set /a addrDiv4=addrDec/4
for /f "delims=" %%i in ('cscript //nologo hex.vbs %addrDiv4%') do set addrDiv4Hex=%%i

IF !outputAddr! EQU 1 (
	set outputAddr=0
	@echo @%addrDiv4Hex% >> %outfile%	
)

;: output instruction(s) to memory files
set continue=1
IF "%instr1%" NEQ "" CALL :testInstr %instr1%
CALL :incrementAddr
IF "%instr2%" NEQ "" IF !continue! EQU 1 ( CALL :testInstr %instr2% ) ELSE ( EXIT /B )
CALL :incrementAddr
IF "%instr3%" NEQ "" IF !continue! EQU 1 ( CALL :testInstr %instr3% ) ELSE ( EXIT /B )
CALL :incrementAddr
IF "%instr4%" NEQ "" IF !continue! EQU 1 ( CALL :testInstr %instr4% ) ELSE ( EXIT /B )

EXIT /B


::::::::::::::::::::::::::::::::::::::::::::
:testInstr
set instr=%1%

:: test instruction length
    set "s=%instr%"
    set "len=1"
    for %%P in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
        if "!s:~%%P,1!" NEQ "" ( 
            set /a "len+=%%P"
            set "s=!s:~%%P!"
        )
    )
)
IF !len! NEQ 8 (
	set continue=0;
	EXIT /B
)

:: check for hex instruction
set "test=!instr!"
for %%C in (0 1 2 3 4 5 6 7 8 9 A B C D E F) do if defined test set "test=!test:%%C=!"
if defined test (
	set continue=0;
	EXIT /B
)

echo %instr% >> %outfile%	
echo %addrDiv4Hex% : %instr%; >> %outfile_mif%


EXIT /B


::::::::::::::::::::::::::::::::::::::::::::
:incrementAddr
set /a addrDiv4=%addrDiv4%+1
for /f "delims=" %%i in ('cscript //nologo hex.vbs %addrDiv4%') do set addrDiv4Hex=%%i

EXIT /B


::::::::::::::::::::::::::::::::::::::::::::
:initMemFiles
IF EXIST %outfile_boot% (rm %outfile_boot%)
IF EXIST %outfile_program% (rm %outfile_program%)

@echo WIDTH = 32; > %outfile_bootmif%
@echo DEPTH = 32768; >> %outfile_bootmif%
@echo ADDRESS_RADIX = HEX; >> %outfile_bootmif%
@echo DATA_RADIX = HEX; >> %outfile_bootmif%
@echo CONTENT BEGIN >> %outfile_bootmif%

@echo WIDTH = 32; > %outfile_programmif%
@echo DEPTH = 65536; >> %outfile_programmif%
@echo ADDRESS_RADIX = HEX; >> %outfile_programmif%
@echo DATA_RADIX = HEX; >> %outfile_programmif%
@echo CONTENT BEGIN >> %outfile_programmif%

EXIT /B

::::::::::::::::::::::::::::::::::::::::::::
:makeProgram
start /wait cmd.exe /C "cd /d %indir% && make"



:END
@echo END; >> %outfile_bootmif%
@echo END; >> %outfile_programmif%

EXIT /B 1

:EOF		