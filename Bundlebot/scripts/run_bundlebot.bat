@echo off

set SHA1EXT=sha1

set clone=
set FDS_HASH=
set SMV_HASH=
set FDS_TAG=
set SMV_TAG=
set BRANCH_NAME=nightly
set configscript=%userprofile%\.bundle\bundle_config.bat
set logfile=%userprofile%\.bundle\logfile.txt
set upload_bundle=1
set build_apps=1
set clone_repos=1
set emailto=

:: define defaults

if NOT exist %configscript% goto skip_config
  call %configscript%
:skip_config

if EXIST .bundlebot goto endif1
  echo ***error: run_bundlebot.bat must be run in bot/Bundlebot directory
  exit /b 1
:endif1

::*** parse command line arguments
call :getopts %*

if "x%stopscript%" == "x" goto endif2
  exit /b 1
:endif2

set nightly=test
set pub_dir=
if NOT "x%BRANCH_NAME%" == "xrelease" goto skip_branch
  set nightly=rls
  set pub_dir=release
:skip_branch

::*** error checking

set abort=

::--- both or neither fds and smv hashes need to be defined
set bad_hash=
if NOT "x%FDS_HASH%" == "x" goto hash1a
if "x%SMV_HASH%" == "x" goto hash1b
set bad_hash=1
:hash1b
:hash1a

if "x%FDS_HASH%" == "x" goto hash2a
if NOT "x%SMV_HASH%" == "x" goto hash2b
set bad_hash=1
:hash2b
:hash2a

if "x%bad_hash%" == "x" goto badhash
  echo ***error: both or neither fds and smv hashes must be specified.  Only one was found
  set abort=1
:badhash

if "x%abort%" == "x" goto error4
  call :usage
  exit /b 1
:error4

:: make sure we are running in the master branch
set CURDIR=%CD%
cd ..\..\..
set REPOROOT=%CD%

cd %REPOROOT%\bot
set botrepo=%CD%

if exist %REPOROOT%\webpages goto endif4
  echo ***error: the webpages repo does not exist
  cd %CURDIR%
  exit /b 1
:endif4

set email=%botrepo%\Scripts\email_insert.bat
set emailexe=%userprofile%\bin\mailsend.exe
if "x%emailto%" == "x" goto endif5
  if exist %emailexe% goto endif5
    echo ***warning: email program %emailexe% does not exist
    set emailto=
:endif5

cd %REPOROOT%\webpages
set webpagesrepo=%CD%

cd ..
set basedir=%CD%

:: bring the bot repo up to date
echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo updating bot repo
echo.

call :cd_repo %botrepo% master || exit /b 1
git fetch origin master > Nul
git merge origin/master > Nul

:: bring the webpages repo up to date
echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo updating web repo
echo.

call :cd_repo %webpagesrepo% nist-pages || exit /b 1
git fetch origin nist-pages  > Nul
git merge origin/nist-pages  > Nul

cd %CURDIR%

:: create the bundle

set CURDIR=%CD%


if NOT "x%FDS_HASH%" == "x" goto skip_elsehash

  call get_hash_revisions.bat || exit /b 1

  set /p FDS_HASH_BUNDLER=<output\FDS_HASH
  set /p SMV_HASH_BUNDLER=<output\SMV_HASH
  set /p FDS_REVISION_BUNDLER=<output\FDS_REVISION
  set /p SMV_REVISION_BUNDLER=<output\SMV_REVISION

  erase output\FDS_HASH
  erase output\SMV_HASH
  erase output\FDS_REVISION
  erase output\SMV_REVISION
  goto endif_gethash

:skip_elsehash
  set FDS_REVISION_BUNDLER=%FDS_HASH%
  set SMV_REVISION_BUNDLER=%SMV_HASH%
  if "x%FDS_TAG%" == "x" goto endif3
    set FDS_REVISION_BUNDLER=%FDS_TAG%
  :endif3
  if "x%SMV_TAG%" == "x" goto endif4
    set SMV_REVISION_BUNDLER=%SMV_TAG%
  :endif4
  set FDS_HASH_BUNDLER=%FDS_HASH%
  set SMV_HASH_BUNDLER=%SMV_HASH%
:endif_gethash

cd %CURDIR%

echo.                                                         > %logfile%
echo ------------------------------------------------------  >> %logfile%
echo ------------------------------------------------------  >> %logfile%
echo Building bundle using:                                  >> %logfile%
echo.                                                        >> %logfile%
if "x%FDS_REVISION_BUNDLER%" == "x" goto skip_fdsrev
  echo             FDS revision: %FDS_REVISION_BUNDLER%      >> %logfile%
:skip_fdsrev

if "x%FDS_HASH_BUNDLER%" == "x" goto skip_fdshash
echo            FDS repo hash: %FDS_HASH_BUNDLER%            >> %logfile%
:skip_fdshash

if "x%FDS_TAG%" == "x" goto skip_fdstag
echo             FDS repo tag: %FDS_TAG%                     >> %logfile%
:skip_fdstag

if "x%SMV_REVISION_BUNDLER%" == "x" goto skip_smvrev
  echo             smv revision: %SMV_REVISION_BUNDLER%      >> %logfile%
:skip_smvrev

if "x%SMV_HASH_BUNDLER%" == "x" goto skip_smvhash
echo            SMV repo hash: %SMV_HASH_BUNDLER%            >> %logfile%
:skip_smvhash

if "x%SMV_TAG%" == "x" goto skip_smvtag
echo             SMV repo tag: %SMV_TAG%                     >> %logfile%
:skip_smvtag

if NOT "%emailto%" == "" (
  echo                    email: %emailto%                   >> %logfile%
)
echo.                                                        >> %logfile%

type %logfile%

if "x%clone%" == "xclone" goto skip_warning
  echo.
  echo ---------------------------------------------------------------
  echo ---------------------------------------------------------------
  echo You are about to erase and then clone the fds and smv repos.
  echo Press any key to continue or CTRL c to abort.
  echo To avoid this warning, use the -c option on the command line
  echo ---------------------------------------------------------------
  echo ---------------------------------------------------------------
  echo.
  pause >Nul
:skip_warning

if "x%clone_repos%" == "x" goto skip_clone
call clone_repos %FDS_HASH_BUNDLER% %SMV_HASH_BUNDLER% %BRANCH_NAME% %FDS_TAG% %SMV_TAG% || exit /b 1
:skip_clone

:: define revisions if hashes were specified on the command line
if NOT "x%FDS_HASH%" == "x" goto skip_getrevision

  call :cd_repo %basedir%\fds %BRANCH_NAME% || exit /b 1
  git describe --abbrev=7 --dirty --long > temp1
  set /p FDS_REVISION_BUNDLER=<temp1
  erase temp1

  call :cd_repo %basedir%\smv %BRANCH_NAME% || exit /b 1
  git describe --abbrev=7 --dirty --long > temp1
  set /p SMV_REVISION_BUNDLER=<temp1
  erase temp1
:skip_getrevision

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Building apps
echo.

cd %CURDIR%
if "x%build_apps%" == "x" goto skip_build
call make_apps         || exit /b 1
:skip_build

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Copying fds apps
echo.
cd %CURDIR%
call copy_apps fds bot || exit /b 1

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Copying smv apps
echo.

cd %CURDIR%
call copy_apps smv bot || exit /b 1

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Copying fds pubs
echo.

cd %CURDIR%
call copy_pubs firebot  || exit /b 1

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Copying smv pubs
echo.

cd %CURDIR%
call copy_pubs smokebot || exit /b 1

echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo making bundle
echo.

cd %CURDIR%
call make_bundle bot %FDS_REVISION_BUNDLER% %SMV_REVISION_BUNDLER% %nightly%

cd %CURDIR%

if "x%upload_bundle%" == "x" goto skip_upload
  echo.
  echo ------------------------------------------------------
  echo ------------------------------------------------------
  echo uploading bundle
  echo.

  set filelist=%TEMP%\fds_smv_files_win.out
  gh release view %GH_FDS_TAG% -R github.com/%GH_OWNER%/%GH_REPO% | grep FDS | grep SMV | grep win | gawk "{print $2}" > %filelist%
  for /F "tokens=*" %%A in (%filelist%) do gh release delete-asset %GH_FDS_TAG% -R github.com/%GH_OWNER%/%GH_REPO% %%A -y
  erase %filelist%

  set /p basename=<%TEMP%\fds_smv_basename.txt

  set fullfilebase=%userprofile%\.bundle\bundles\%basename%
  echo gh release upload %GH_FDS_TAG% %fullfilebase%.%SHA1EXT% -R github.com/%GH_OWNER%/%GH_REPO% --clobber
       gh release upload %GH_FDS_TAG% %fullfilebase%.%SHA1EXT% -R github.com/%GH_OWNER%/%GH_REPO% --clobber
  
  echo gh release upload %GH_FDS_TAG% %fullfilebase%.exe -R github.com/%GH_OWNER%/%GH_REPO% --clobber
       gh release upload %GH_FDS_TAG% %fullfilebase%.exe -R github.com/%GH_OWNER%/%GH_REPO% --clobber

  echo gh release upload %GH_FDS_TAG% %fullfilebase%.zip -R github.com/%GH_OWNER%/%GH_REPO% --clobber
       gh release upload %GH_FDS_TAG% %fullfilebase%.zip -R github.com/%GH_OWNER%/%GH_REPO% --clobber
:skip_upload

if "x%emailto%" == "x" goto endif6
  call %email% %emailto% "PC bundle %FDS_REVISION_BUNDLER% %SMV_REVISION_BUNDLER% created on %COMPUTERNAME%" %logfile%
:endif6

goto eof


::-----------------------------------------------------------------------
:usage
::-----------------------------------------------------------------------

:usage
echo.
echo run_bundlebot usage
echo.
echo This script builds FDS and Smokeview apps and generates a bundle using either the
echo specified fds and smv repo revisions or revisions from the latest firebot pass.
echo.
echo Options:
echo -b - branch name [default: %BRANCH_NAME%]
echo -c - bundle without warning about cloning/erasing fds and smv repos 
echo -C - get manuals from .bundle/manuals
echo -D - for development, turn off making apps and uploading bundle
echo -F - fds repo hash
echo -h - display this message
echo -m mailtto - send email to mailto
echo -r - same as -b release or -R release
echo -R - branch name [default: %BRANCH_NAME%]
echo -S - smv repo hash
echo -U - do not upload bundle
echo -X fdstag - tag the fds repo using fdstag
echo -Y smvtag - tag the smv repo using smvtag
exit /b 0

::-----------------------------------------------------------------------
:getopts
::-----------------------------------------------------------------------
 set stopscript=
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 if "%1" EQU "-G" (
   set GH_REPO=%2
   set valid=1
   shift
 )
 if "%1" EQU "-b" (
   set BRANCH_NAME=%2
   set valid=1
   shift
 )
 if "%1" EQU "-R" (
   set BRANCH_NAME=%2
   set valid=1
   shift
 )
 if "%1" EQU "-c" (
   set clone=clone
   set valid=1
 )
 if "%1" EQU "-D" (
   set clone_repos=
   set build_apps=
   set upload_bundle=
   set valid=1
 )
 if "%1" EQU "-F" (
   set FDS_HASH=%2
   set valid=1
   shift
 )
 if "%1" EQU "-h" (
   call :usage
   set stopscript=1
   exit /b
 )
 if "%1" EQU "-m" (
   set emailto=%2
   set valid=1
   shift
 )
 if "%1" EQU "-r" (
   set BRANCH_NAME=release
   set valid=1
 )
 if "%1" EQU "-S" (
   set SMV_HASH=%2
   set valid=1
   shift
 )
 if "%1" EQU "-U" (
   set upload_bundle=
   set valid=1
 )
 if "%1" EQU "-X" (
   set FDS_TAG=%2
   set valid=1
   shift
 )
 if "%1" EQU "-Y" (
   set SMV_TAG=%2
   set valid=1
   shift
 )
 shift
 if %valid% == 0 (
   echo.
   echo ***Error: the input argument %arg% is invalid
   echo.
   echo Usage:
   call :usage
   set stopscript=1
   exit /b 1
 )
if not (%1)==() goto getopts
exit /b 0

:: -------------------------------------------------------------
:chk_repo
:: -------------------------------------------------------------

set repodir=%1

if NOT exist %repodir% (
  echo ***error: repo directory %repodir% does not exist
  echo  aborted
  exit /b 1
)
exit /b 0


:: -------------------------------------------------------------
:cd_repo
:: -------------------------------------------------------------

set repodir=%1
set repobranch=%2

call :chk_repo %repodir% || exit /b 1

cd %repodir%
if "%repobranch%" == "" (
  exit /b 0
)
git rev-parse --abbrev-ref HEAD>current_branch.txt
set /p current_branch=<current_branch.txt
erase current_branch.txt
if "%repobranch%" NEQ "%current_branch%" (
  echo ***error: in repo %repodir% found branch %current_branch%
  echo            was expecting branch %repobranch%
  echo  aborted
  exit /b 1
)
exit /b 0

:eof

exit /b 0
