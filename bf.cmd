@ECHO off
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
rem Глобальные переменные
rem Набор выводимых символов. Символы, вывод которых вызывал ошибки исполнения cmd заменены символом "."
set char=".#$...'()*+,-./0123456789.....?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]._`abcdefghijklmnopqrstuvwxyz{.}~_"
rem Размер maxmem можно поставить 30000 ячеек памяти, но тогда инициализация идет очень долго.
set maxmem=100

echo Brainfuck Interpreter
echo.

IF "%1" NEQ "" GOTO :init
echo Usage: %~nx0 file.bf
goto :eof

:init
rem Инициализируем память.
set /a __maxindex=%maxmem% - 1
for /l %%i in (0,1,%__maxindex%) do set mem_%%i=0
set mp=0
set sp=0
set cp=0

rem читаем программу в память
set work_file=%1
set bf_prog=
FOR /F "eol=c delims=*" %%I IN (%work_file%) DO SET bf_prog=!bf_prog!%%I
rem узнаем длину программы
Echo.%bf_prog%>"%TEMP%\%~n0.tmp"
For %%i In ("%TEMP%\%~n0.tmp") Do Set /A bf_len=%%~zi-2
rem Выводим тест, что программа работает, а не зависла.
echo Executing programm
echo %bf_prog%
echo.

rem рабочий цикл
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
) else if "%cop%" == ")" (
  set /a mp +=1
  if !mp! == %maxmem% set mp=0
) else if "%cop%" == "(" (
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
    if "%cp%" LSS "0" (
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
rem Не реализованно
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
for /l %%i in (0,1,%__maxindex%) do echo !mem_%%i! >>memory.dmp
exit /b 0
rem ==========================================================================

:exit
set /a __maxindex=%maxmem% - 1
if exist memory.dmp del memory.dmp
for /l %%i in (0,1,%__maxindex%) do echo !mem_%%i! >>memory.dmp
echo.
ENDLOCAL