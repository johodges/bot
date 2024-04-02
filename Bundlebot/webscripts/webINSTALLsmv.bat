@echo off
set platform=%1
set buildtype=%2
set nopause=%3

::  batch file to build test or release Smokeview on a Windows, OSX or Linux system

:: setup environment variables (defining where repository resides etc) 

set envfile="%userprofile%"\fds_smv_env.bat
IF EXIST %envfile% GOTO endif_envexist
echo ***Fatal error.  The environment setup file %envfile% does not exist. 
echo Create a file named %envfile% and use smv/scripts/fds_smv_env_template.bat
echo as an example.
echo.
echo Aborting now...
if "x%nopause%" == "xnopause" goto eof
pause>NUL
goto:eof

:endif_envexist

call %envfile%
if "%buildtype%" == "test" (
  echo.
  echo  Updating test %platform% Smokeview
  Title  Updating test %platform% Smokeview
)
if "%buildtype%" == "release" (
  echo.
  echo  Updating release %platform% Smokeview
  Title  Updating release %platform% Smokeview
)

%git_drive%

if "%platform%" == "Windows" (
  cd %userprofile%\.bundle\uploads
  if "%buildtype%" == "test" (
    echo Installer:  %smv_revision%_win.exe
    call %smv_revision%_win.exe
  )
  if "%buildtype%" == "release" (
    echo Installer: %smv_version%_win.exe
    call %smv_version%_win.exe
  )
  echo update complete
  goto eof
)
if "%platform%" == "Linux" (
  if "%buildtype%" == "test" (
    plink %plink_options% %linux_logon% %linux_git_root%/smv/scripts/run_command2.sh $HOME/.bundle/uploads %smv_revision%_lnx.sh y
  )
  if "%buildtype%" == "release" (
    plink %plink_options% %linux_logon% %linux_git_root%/smv/scripts/run_command2.sh $HOME/.bundle/uploads %smv_version%_lnx.sh y
  )
  if "x%nopause%" == "xnopause" goto eof
  pause > Nul
  goto eof
)
if "%platform%" == "OSX" (
  if "%buildtype%" == "test" (
    plink %plink_options% %osx_logon% %linux_git_root%/smv/scripts/run_command2.sh $HOME/.bundle/uploads %smv_revision%_osx.sh y
  )
  if "%buildtype%" == "release" (
    plink %plink_options% %osx_logon% %linux_git_root%/smv/scripts/run_command2.sh $HOME/.bundle/uploads %smv_version%_osx.sh y
  )
  if "x%nopause%" == "xnopause" goto eof
  pause > Nul
  goto eof
)

:eof
