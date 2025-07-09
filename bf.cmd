@ECHO off
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
rem Глобальные переменные
rem Набор выводимых символов. Символы, вывод которых вызывал ошибки исполнения cmd заменены символом "."
set char=".#$...'()*+,-./0123456789.....?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]._`abcdefghijklmnopqrstuvwxyz{.}~_"
rem Размер maxmem можно поставить 30000 ячеек памяти, но тогда инициализация идет очень долго.
set maxmem=100

echo Brainfuck Interpreter
echo.

set show_program=0
set dump_memory=0
set file_name=

:parse_args
if "%~1"=="" goto :args_parsed
if /i "%~1"=="-l" (
    set show_program=1
    shift
    goto :parse_args
)
if /i "%~1"=="-d" (
    set dump_memory=1
    shift
    goto :parse_args
)
set file_name=%~1
shift
goto :parse_args

:args_parsed
IF NOT DEFINED file_name (
    echo Usage: %~nx0 [-l] [-d] file.bf
    echo   -l  Show program before execution
    echo   -d  Dump memory to memory.dmp after execution
    goto :eof
)

:init
rem Инициализация памяти
set /a __maxindex=%maxmem% - 1
for /l %%i in (0,1,%__maxindex%) do set mem_%%i=0
set mp=0
set sp=0
set cp=0

rem Чтение программы
set bf_prog=
FOR /F "usebackq delims=" %%I IN ("%file_name%") DO (
    set "line=%%I"
    set "line=!line:<=^<!"
    set "line=!line:>=^>!"
    set bf_prog=!bf_prog!!line!
)

rem Получение длины программы
set bf_len=0
:get_length
if "!bf_prog:~%bf_len%,1!" NEQ "" (
    set /a bf_len+=1
    goto :get_length
)

rem Вывод программы если указан ключ -l
if %show_program% EQU 1 (
    echo Program:
    setlocal DISABLEDELAYEDEXPANSION
    type %file_name%
    endlocal
    echo.
)

echo Executing program...
echo.

rem Рабочий цикл
:work
set cop=!bf_prog:~%cp%,1!
rem call :debug

if "%cop%" == "+" (
    set tmp=!mem_%mp%!
    set /a tmp += 1
    if !tmp!==256 set tmp=0
    set mem_%mp%=!tmp!
) else if "%cop%" == "-" (
    set tmp=!mem_%mp%!
    set /a tmp -= 1
    if !tmp! LSS 0 set tmp=255
    set mem_%mp%=!tmp!
) else if "%cop%" == ">" (
    set /a mp +=1
    if !mp! == %maxmem% set mp=0
) else if "%cop%" == "<" (
    set /a mp -=1
    if !mp! == -1 set /a mp=%maxmem% - 1
) else if "%cop%" == "," (
    call :comma
) else if "%cop%" == "." (
    set tmp=!mem_%mp%!
    call :Echochr !tmp!
) else if "%cop%" == "[" (
    set tmp=!mem_%mp%!
    if !tmp!==0 (
        call :skip1
    )
) else if "%cop%" == "]" (
    set tmp=!mem_%mp%!
    if !tmp! NEQ 0 (
        call :skip2
    )
)

set /a cp += 1
if %cp% GEQ %bf_len% goto :exit
goto :work

:skip1
:w11
    set /a cp += 1
    if %cp% == %bf_len% (
      call :err_print "] not found"
      exit /b 0
    )
    set cop=!bf_prog:~%cp%,1!
    if "%cop%" == "[" (set /a sp +=1)
    if "%cop%" == "]" if %sp% NEQ 0 (set /a sp -=1) else (goto :w12)
    goto :w11
:w12
exit /b 0

:skip2
:w21
    set /a cp -= 1
    if %cp% LSS 0 (
      call :err_print "[ not found"
      exit /b 0
    )
    set cop=!bf_prog:~%cp%,1!
    if "%cop%" == "]" (set /a sp +=1)
    if "%cop%" == "[" if %sp% NEQ 0 (set /a sp -=1) else (goto :w22)
    goto :w21
:w22
exit /b 0

:comma
rem Не реализовано
exit /b 0

rem ==========================================================================
rem Процедура echochr
rem Эмуляция функции chr()
rem ==========================================================================
:echochr
if %1==10 echo.
if %1==13 echo.
if %1==32 <nul set /p strTemp="_"
if %1 GTR 32 (
set /a code=%1 - 32
for /f %%t in ('cmd /c "echo %%char:~!code!,1%%"') do <nul set /p strTemp="%%t"
)
exit /b 0

rem ==========================================================================
rem Процедура debug
rem Печать состояния переменных и памяти
rem ==========================================================================
:debug
set tmp=!mem_%mp%!
echo cp=%cp%, mp=%mp%, cop=%cop%, mem[mp]=%tmp%
exit /b 0
rem ==========================================================================

rem ==========================================================================
rem Процедура EchoWithoutCrLf
rem %1 : текст для вывода.
rem ==========================================================================
:EchoWithoutCrLf
<nul set /p strTemp="%~1"
exit /b 0
rem ==========================================================================

rem ==========================================================================
rem Процедура err_print
rem Печать кода ошибки. Создание дампов работы.
rem ==========================================================================
:err_print
echo Error on %cp% position.
echo %1
echo.
echo cp: %cp% >register.dmp
echo mp: %mp% >>register.dmp
echo sp: %sp% >>register.dmp
set /a __maxindex=%maxmem% - 1
if exist memory.dmp del memory.dmp
for /l %%i in (0,1,%__maxindex%) do (
    rem Форматирование адреса в 4 цифры с ведущими нулями
    set "addr=000%%i"
    set "addr=!addr:~-4!"
    echo !addr!: !mem_%%i! >>memory.dmp
)
exit /b 0
rem ==========================================================================

:exit
set /a __maxindex=%maxmem% - 1

if %dump_memory% EQU 1 (
    if exist memory.dmp del memory.dmp
    for /l %%i in (0,1,%__maxindex%) do (
        rem Форматирование адреса в 4 цифры с ведущими нулями
        set "addr=000%%i"
        set "addr=!addr:~-4!"
        echo !addr!: !mem_%%i! >>memory.dmp
    )
    echo.
    echo Memory dumped to memory.dmp
)

ENDLOCAL
