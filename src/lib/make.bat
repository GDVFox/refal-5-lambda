@echo off
if not exist ..\..\lib\nul (
  mkdir ..\..\lib
  mkdir ..\..\lib\src
)

setlocal
  set LIBRARIES=Library Hash LibraryEx GetOpt Platform

  copy LICENSE ..\..\lib
  for %%s in (%LIBRARIES%) do copy %%s.ref ..\..\lib\src

  call :PREPARE_COMMON
  call :COMPILE_SCRATCH
  call :COMPILE_REFERENCES
  call :COMPILE_SLIM
endlocal
goto :EOF

:COMPILE_SEPARATED
setlocal
  set TARGET="%~1"
  set LIBS=%~2

  mkdir %TARGET%\x
  rmdir %TARGET%\x

  for %%s in (%LIBS%) do (
    ..\..\bin\srefc-core -C %SREFC_FLAGS% %%s -d common
    ..\..\bin\srefc-core --no-sources -R -o inco.bin --incorporated=%%~ns
    find "//FROM" < %%s.ref > %TARGET%\%%s.rasl.froms
    if exist %%s.cpp move %%s.cpp %TARGET%
    copy /b %%s.rasl+inco.bin %TARGET%\%%s.rasl
    erase %%s.rasl inco.bin
  )
endlocal
goto :EOF

:COMPILE_SCRATCH
  set SCRATCHDIR=..\..\lib\scratch
  call :COMPILE_SEPARATED "%SCRATCHDIR%\exe" "LibraryEx Hash GetOpt"
  mkdir %SCRATCHDIR%\debug\exe\x
  rmdir %SCRATCHDIR%\debug\exe\x

  set SCRATCHDIR=..\..\lib\scratch-rt
  call :COMPILE_SEPARATED "%SCRATCHDIR%\exe" "Library Platform"

  for /d %%d in (. platform-* exe platform-Windows\lib platform-POSIX\lib) do (
    if not exist %SCRATCHDIR%\%%d\NUL (
      mkdir %SCRATCHDIR%\%%d
    )
    copy %%d\*.h %SCRATCHDIR%\%%d
    copy %%d\*.cpp %SCRATCHDIR%\%%d
    if exist %%d\*.def copy %%d\*.def %SCRATCHDIR%\%%d
  )

  for /F %%c in ('dir /b /s %SCRATCHDIR%\*.cpp') do (
    if not exist %%~dpnc.rasl copy nul %%~dpnc.rasl
  )

  for %%d in (diagnostic-initializer debugger) do (
    move ..\..\lib\scratch-rt\refalrts-%%d.* ..\..\lib\scratch\debug\exe
  )
goto :EOF

:COMPILE_SLIM
setlocal
  set SLIMDIR=..\..\lib\slim
  mkdir %SLIMDIR%\exe\x
  rmdir %SLIMDIR%\exe\x

  set SREFC_FLAGS=%SREFC_FLAGS% -Od-
  call :COMPILE_SEPARATED "%SLIMDIR%\exe" "LibraryEx GetOpt"
endlocal
goto :EOF

:PREPARE_COMMON
  xcopy /e /i /y common ..\..\lib\common
goto :EOF

:COMPILE_REFERENCES
setlocal
  mkdir ..\..\lib\references

  for %%s in (%LIBRARIES%) do (
    ..\..\bin\srefc-core --no-sources -R ^
       -o ..\..\lib\references\%%s.rasl --reference=%%s
  )
endlocal
goto :EOF
