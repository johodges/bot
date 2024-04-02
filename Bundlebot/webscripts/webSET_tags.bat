@echo off

:: batch file used to update Windows, Linux and OSX GIT repos

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

:: location of batch files used to set up Intel compilation environment

call %envfile%

echo.
echo ---------------------------*** fds ***--------------------------------
%git_drive%
cd %git_root%\fds
echo Windows
git checkout master
if x"%fds_tags%" == "x" goto skip_fds_tag
if "%fds_tags%" == "latest" goto skip_fds_tag
git branch -d release > Nul 2> Nul
git checkout %fds_tag% -b release
:skip_fds_tag

set scriptdir=%linux_git_root%/bot/Scripts/
set linux_fdsdir=%linux_git_root%

echo.
echo Linux
plink %plink_options% %linux_logon% %scriptdir%/set_releasetag.sh  %linux_git_root%/fds %fds_tag%
echo.

echo OSX
plink %plink_options% %osx_logon% %scriptdir%/set_releasetag.sh  %linux_git_root%/fds %fds_tag%


echo.
echo ---------------------------*** smv ***--------------------------------
cd %git_root%\smv
echo Windows
git checkout master

if x"%smv_tags%" == "x" goto skip_smv_tag
if "%smv_tags%" == "latest" goto skip_smv_tag
git branch -d release  > Nul 2> Nul
git checkout %smv_tag% -b release
:skip_smv_tag

echo.
echo Linux
plink %plink_options% %linux_logon% %scriptdir%/set_releasetag.sh  %linux_git_root%/smv %smv_tag%

echo.
echo OSX
plink %plink_options% %osx_logon% %scriptdir%/set_releasetag.sh  %linux_git_root%/smv %smv_tag%

echo.
pause
