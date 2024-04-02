@echo off
:: platform is windows, linux or osx
set platform=%1

:: build type is test or release
set buildtype=%2

set nopause=nopause

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

set type=
if "%buildtype%" == "test" (
   set type=test
   set version=%smv_revision%
)
if "%buildtype%" == "release" (
   set type=
   set version=%smv_version%
)

echo.
echo  Bundling %type% Smokeview for %platform%
Title Bundling %type% Smokeview for %platform%

:: windows

if "%platform%" == "Windows" (
  call %git_root%\bot\Bundlebot\smv\scripts\make_%type%bundle
  goto eof
)

cd %git_root%\smv\scripts

set scriptdir=%linux_git_root%/bot/Bundlebot/smv
set bundledir=.bundle/uploads
set todir=%userprofile%\.bundle
set uploaddir=%todir%\uploads

if NOT exist %todir% mkdir     %todir%
if NOT exist %uploaddir% mkdir %uploaddir%

:: linux

if "%platform%" == "Linux" (

  echo.
  echo --- making 64 bit Linux Smokeview installer ---
  echo.
  plink %plink_options% %linux_logon% %scriptdir%/scripts/make_bundle.sh %buildtype% %version% %linux_git_root%
  goto eof
)

:: osx

if "%platform%" == "OSX" (
  echo.
  echo --- making 64 bit OSX Smokeview installer ---
  echo.
  plink %plink_options% %osx_logon% %scriptdir%/scripts/make_bundle.sh %buildtype% %version% %linux_git_root%
  goto eof
)

:eof
if "x%nopause%" == "xnopause" goto eof2
echo.
echo Bundle build complete
pause
:eof2
