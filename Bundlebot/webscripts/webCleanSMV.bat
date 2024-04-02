@echo off
setlocal EnableDelayedExpansion
set platform=%1

:: batch file to install the FDS-SMV bundle on Windows, Linux or OSX systems

:: setup environment variables (defining where repository resides etc) 

set envfile="%userprofile%"\fds_smv_env.bat
IF EXIST %envfile% GOTO endif_envexist
echo ***Fatal error.  The environment setup file %envfile% does not exist. 
echo Create a file named %envfile% and use smv/scripts/fds_smv_env_template.bat
echo as an example.
echo.
echo Aborting now...
pause>NUL
goto:eof

:endif_envexist

call %envfile%
%git_drive%
echo.

echo cleaning smokeview build directories

if NOT "%platform%" == "Windows" goto skip_windows
echo *** windows
cd %git_root%\smv\Build\smokeview\intel_win_64
git clean -dxf
:skip_windows

if NOT "%platform%" == "Linux" goto skip_linux
echo.
echo *** linux
plink %plink_options% %linux_logon% %linux_git_root%/smv/scripts/clean.sh       smv/Build/smokeview/intel_linux_64
plink %plink_options% %linux_logon% %linux_git_root%/smv/scripts/clean.sh       smv/Build/smokeview/gnu_linux_64 
:skip_linux

if NOT "%platform%" == "OSX" goto skip_osx
echo.
echo *** osx
plink %plink_options% %osx_logon% %linux_git_root%/smv/scripts/clean.sh       smv/Build/smokeview/intel_osx_64
plink %plink_options% %osx_logon% %linux_git_root%/smv/scripts/clean.sh       smv/Build/smokeview/intel_osx_q_64 
plink %plink_options% %osx_logon% %linux_git_root%/smv/scripts/clean.sh       smv/Build/smokeview/gnu_osx_64 
:skip_osx

:eof
echo.
pause
