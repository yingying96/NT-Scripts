echo off
echo %ESC%[107mFor Information%ESC%[0m
echo Editor: Yao Yingying
echo Version: 1.0 (Aug 2020)
echo Modifications were made to this MSFT script 
echo - Allow users to run this bat file without admin rights
echo - Upload to OneDrive with consent from the user
echo - Prepare email notification to GrpTGO365Support email

@if not defined _echo echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set OUTPUTDIR=%USERPROFILE%\Desktop
set DODUMP=0
set SENDMAIL=1
set RETURNCODE=0
set DecoderKey=
set OneDriveUploadKey=
set ScriptName=%~0

REM Set the CAB file name to include the date and time with
REM underscores substituted for the invalid characters.

set DATETIMESUFFIX=%DATE:/=_%_%TIME::=_%
set CABOUTPUT=OneDriveLogs_%USERNAME%_%DATETIMESUFFIX: =_%.cab

:ParseCommand
if "%~1"=="" goto :ParseDone

if /i "%~1"=="/OutputDir" (
    for %%i in (%2) do set OUTPUTDIR=%%~i
    shift
) else if /i "%~1"=="/OutputFile" (
    for %%i in (%2) do set CABOUTPUT=%%~i
    shift
) else if /i "%~1"=="/NoDump" (
    set DODUMP=0
) else if /i "%~1"=="/SendMail" (
    set SENDMAIL=1
) else if /i "%~1"=="/IncludeDecoderKey" (
    set DecoderKey=Y
) else if /i "%~1"=="/NoDecoderKey" (
    set DecoderKey=N
) else (
    echo %ESC%[107mFor Information%ESC%[0m
    echo Usage: %ScriptName% [Options]
    echo.
    echo     This script collects all the client logs and CABs them up for simple
    echo     upload.  By default, it will drop the CAB file on your Desktop.
    echo.
    echo Options:
    echo.
    echo     /OutputDir outputdirectory   - Set output directory
    echo     /NoDump                      - Don't collect a process dump of OneDrive.exe
    echo     /OutputFile outputFile       - Filename of output file to use
    echo     /SendMail                    - Triggers an email to the given alias with the full path of the file.
    echo     /IncludeDecoderKey           - Do not prompt and include the decoder key with the logs
    echo     /NoDecoderKey                - Do not prompt and do NOT include the decoder key with the logs
    echo.
    goto :Return
)
shift
goto :ParseCommand

:ParseDone

REM -------------------------
REM * CLIENT PATH DISCOVERY *
REM -------------------------

if "%LOCALAPPDATA%"=="" (
    set LOCALAPPDATA=%USERPROFILE%\Local Settings\Application Data
)

set CLIENTPATH=%LOCALAPPDATA%\Microsoft\OneDrive
set MACHINE_SETUP_LOGS_PATH=%PROGRAMDATA%\Microsoft OneDrive

if exist "%CLIENTPATH%" (
    goto :CopyLogs
)

if exist "%MACHINE_SETUP_LOGS_PATH%" (
    goto :CopyLogs
)

REM None of the data folders exist, exit.
echo %ESC%[41mError: No application data exists for OneDrive client.%ESC%[0m
echo.
goto :Return

REM -------------
REM * COPY LOGS *
REM -------------

:CopyLogs

if exist "%CLIENTPATH%" (
    pushd "%CLIENTPATH%"
    REM Changed initial log collection place to Desktop instead of Client Path
    set WORKINGDIR=%USERPROFILE%\Desktop\LogCollection
    REM set WORKINGDIR=%CLIENTPATH%\LogCollection
) else (
    set WORKINGDIR=%TMP%\LogCollection
)

if exist "%WORKINGDIR%" (
    rd /s /q "%WORKINGDIR%"
)

mkdir "%WORKINGDIR%"

echo.
echo %ESC%[44mFrom original MSFT script%ESC%[0m
echo Microsoft values your privacy.
echo.
echo You have been asked to provide logs from your computer that will help support
echo engineers identify and resolve a problem you have been experiencing.
echo.
echo Text such as web addresses (URLs), email addresses, File and Folder names that
echo are in the logs are scrambled so the original text is not visible to engineers
echo investigating your logs.
echo.

if not defined DecoderKey (
    echo Giving support engineers the ability to unscramble your logs will allow
    echo trouble shooting issues you are having with specific files or folders. Without
    echo this ability, you may need to perform additional manual steps to provide
    echo support with information they need to troubleshoot your issue.
    echo.
    echo %ESC%[44mCan support unscramble your logs?%ESC%[0m
    set /p DecoderKey=Enter YES or NO: 
    echo.
)

if /I "%DecoderKey:~0,1%" == "Y" (
  set SyncLogsExclude=
  set SyncSettingsExclude=
  echo You have given support the ability to unscramble your logs.
) else (
  set SyncLogsExclude=/XF ObfuscationStringMap.txt
  set SyncSettingsExclude=/XF *.dat
  echo Support will not be able to unscramble your logs.
  echo.
  echo Microsoft may need you to perform extra steps to troubleshoot your issue.
)
echo.

echo Working directory is %WORKINGDIR%.
echo OutputDir is %OutputDir%
echo OutputFile is %CabOutput%
echo DoDump is %DoDump%
echo SendMail is %SendMail%
echo.
echo Gathering Logs ...
echo.

REM ----------------------------------------------------------------
echo.
    echo %ESC%[107mFor Information%ESC%[0m
echo Extracted logs will be saved in %OutputDir% by default
echo.
echo Please note that your logs will also be uploaded to your OneDrive
echo Please ensure that your OneDrive is already launched before proceeding
echo.

if not defined OneDriveUploadKey (
    echo.
    echo %ESC%[44mAllow OneDrive logs to be uploaded to your OneDrive folder?%ESC%[0m
    set /p OneDriveUploadKey=Enter YES or NO: 
    echo.
)

if /I "%OneDriveUploadKey:~0,1%" == "Y" (
  set OneDriveUploadKey=1
  echo You have given support the ability to perform a onetime upload of your logs to OneDrive folder
  echo Afterwards, please share the logs to our GIC O365 Support member attending to your issue.
) else (
  echo We will not be able to upload your logs to OneDrive
  echo Please let our support know how you would like to proceed.
  echo.
)
echo.

REM ----------------------------------------------------------------


set > "%WORKINGDIR%\env.txt"
REM TaskList and SystemInfo are not available on XP Home.
REM /v makes tasklist.exe really slow when not running elevated so don't use it
tasklist.exe > "%WORKINGDIR%\tasklist.txt"
systeminfo.exe > "%WORKINGDIR%\systeminfo.txt"

REM Capture list of running services.
net.exe start > "%WORKINGDIR%\services.txt"

REM OneDrive
set /p CRLF=Copying OneDrive logs <NUL

set WORKINGDIRONEDRIVE=%WORKINGDIR%\OneDrive
mkdir "%WORKINGDIRONEDRIVE%"

if exist "%CLIENTPATH%" (
    dir /S "%CLIENTPATH%" > "%WORKINGDIRONEDRIVE%\tree.txt"
    REM Issues with TraceArchive.etl as user will not have permission
    mkdir %USERPROFILE%\Desktop\LogCollection\OneDrive\logs
    copy %LOCALAPPDATA%\Microsoft\OneDrive\logs\Business1 %USERPROFILE%\Desktop\LogCollection\OneDrive\logs
    REM robocopy.exe "%CLIENTPATH%\logs" "%WORKINGDIRONEDRIVE%\logs" /S %SyncLogsExclude%
    robocopy.exe "%CLIENTPATH%\settings" "%WORKINGDIRONEDRIVE%\settings" /S %SyncSettingsExclude%
    robocopy.exe "%CLIENTPATH%\setup\logs" "%WORKINGDIRONEDRIVE%\setup\logs" /S
)

if exist "%MACHINE_SETUP_LOGS_PATH%" (
    robocopy.exe "%MACHINE_SETUP_LOGS_PATH%\setup\logs" "%WORKINGDIRONEDRIVE%\MachineSetupLogs\setup\logs" /S
    robocopy.exe "%MACHINE_SETUP_LOGS_PATH%\StandaloneUpdater\logs" "%WORKINGDIRONEDRIVE%\MachineSetupLogs\StandaloneUpdater\logs" /S
    robocopy.exe "%MACHINE_SETUP_LOGS_PATH%\UpdaterService\logs" "%WORKINGDIRONEDRIVE%\MachineSetupLogs\UpdaterService\logs" /S
    robocopy.exe "%MACHINE_SETUP_LOGS_PATH%\FileSyncHelper\logs" "%WORKINGDIRONEDRIVE%\MachineSetupLogs\FileSyncHelper\logs" /S
)

set PERMACHINECLIENTPATH86=%PROGRAMFILES(X86)%\Microsoft OneDrive
if exist "%PERMACHINECLIENTPATH86%" (
    dir /S "%PERMACHINECLIENTPATH86%" > "%WORKINGDIRONEDRIVE%\PerMachine86Tree.txt"
)

set PERMACHINECLIENTPATH=%PROGRAMFILES%\Microsoft OneDrive
if exist "%PERMACHINECLIENTPATH%" (
    dir /S "%PERMACHINECLIENTPATH86%" > "%WORKINGDIRONEDRIVE%\PerMachineTree.txt"
)

REM Collect list of overlay handlers
reg.exe query HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers /S > "%WORKINGDIRONEDRIVE%\overlayHandlers.txt" 2>&1
reg.exe query HKCU\Software\Microsoft\Windows\CurrentVersion\Run /S > "%WORKINGDIRONEDRIVE%\RunKey.txt" 2>&1
reg.exe query HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce /S > "%WORKINGDIRONEDRIVE%\RunOnceKey.txt" 2>&1
reg.exe query HKCU\software\microsoft\onedrive /s > "%WORKINGDIRONEDRIVE%\OneDriveRegKeys.txt" 2>&1
reg.exe query HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers /S > "%WORKINGDIRONEDRIVE%\AutoplayHandlers.txt" 2>&1
reg.exe query HKLM\software\microsoft\onedrive /s > "%WORKINGDIRONEDRIVE%\OneDriveMachineRegKeys.txt" 2>&1
reg.exe query HKLM\software\wow6432node\microsoft\onedrive /s > "%WORKINGDIRONEDRIVE%\OneDriveMachine32RegKeys.txt" 2>&1
reg.exe query HKCU\Software\SyncEngines\Providers\OneDrive /s > "%WORKINGDIRONEDRIVE%\SyncEngineProviders.txt" 2>&1
reg.exe query HKCR\odopen /s > "%WORKINGDIRONEDRIVE%\ODOpen.txt" 2>&1
reg.exe query HKLM\Software\Policies\Microsoft\OneDrive /s > "%WORKINGDIRONEDRIVE%\OneDrivePoliciesLocalMachine.txt" 2>&1
reg.exe query HKCU\Software\Policies\Microsoft\OneDrive /s > "%WORKINGDIRONEDRIVE%\OneDrivePoliciesCurrentUser.txt" 2>&1
reg.exe query HKCU\Software\Microsoft\Common\Groove > "%WORKINGDIRONEDRIVE%\GrooveKeys.txt" 2>&1
reg.exe query "HKCU\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" > "%WORKINGDIRONEDRIVE%\WinlogonUser.txt" 2>&1
reg.exe query "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" > "%WORKINGDIRONEDRIVE%\WinlogonMachine.txt" 2>&1

REM Check if OneDrive is elevated
powershell -Command "& {get-process onedrive | add-member -Name Elevated -MemberType ScriptProperty -Value {if ($this.Name -in @('Idle','System')) {$null} else {-not $this.Path -and -not $this.Handle} } -PassThru | Format-Table Name,Elevated}" > "%WORKINGDIRONEDRIVE%\OneDriveElevated.txt" 2>&1

REM -------------
REM * Export Event logs *
REM -------------
echo.
echo %ESC%[42mExporting event logs...%ESC%[0m
wevtutil.exe export-log Application "%WORKINGDIR%\Application.evtx"
wevtutil.exe export-log System "%WORKINGDIR%\System.evtx"
wevtutil.exe export-log Setup "%WORKINGDIR%\Setup.evtx"
wevtutil.exe export-log Microsoft-Windows-Bits-Client/Operational "%WORKINGDIR%\Bits.evtx"
wevtutil.exe export-log Microsoft-Windows-TaskScheduler/Operational "%WORKINGDIR%\TaskScheduler.evtx"


REM -------------
REM * Export OneDrive Standalone Update Task information *
REM -------------
echo.
echo %ESC%[42mExporting OneDrive Standalone Update Task information...%ESC%[0m
schtasks.exe /query /TN "OneDrive Standalone Update Task" /XML > %WORKINGDIR%\OneDriveStandaloneUpdateTask.xml 2>&1
schtasks.exe /query /TN "OneDrive Standalone Update Task v2" /XML > %WORKINGDIR%\OneDriveStandaloneUpdateTaskV2.xml 2>&1
schtasks.exe /query /TN "OneDrive Per-Machine Standalone Update Task" /XML > %WORKINGDIR%\OneDrivePerMachineStandaloneUpdateTask.xml 2>&1

for /f "skip=6 tokens=2" %%i IN ('whoami /user') do set SID=%%i
schtasks.exe /query /TN "OneDrive Standalone Update Task-%SID%" /XML > %WORKINGDIR%\OneDriveStandaloneUpdateTaskSID.xml 2>&1

echo.
echo.


REM Copy complete.  CAB up files.

echo %ESC%[42mWriting CAB file to %CABOUTPUT%...%ESC%[0m

call :CABIT "%WORKINGDIR%"
echo After CABIT..

if "%OUTPUTDIR%"=="%USERPROFILE%\Desktop" (
    set SHFOLDER_REGISTRY_KEY="HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    for /f "tokens=2*" %%i in (
        'reg.exe QUERY !SHFOLDER_REGISTRY_KEY! /v Desktop'
    ) do (
        call set OUTPUTDIR=%%~j
    )
)

if not exist "%OUTPUTDIR%\" (
    echo Error! %OUTPUTDIR% does not exist.
    move /y "%WORKINGDIR%\%CABOUTPUT%" %USERPROFILE%\Desktop\. 2>&1>NUL
    set RETURNCODE=1
    goto :Return    
)

move /y "%WORKINGDIR%\%CABOUTPUT%" "%OUTPUTDIR%\." 2>&1>NUL

if ERRORLEVEL 1 (
    echo error level 1
    move /y "%WORKINGDIR%\%CABOUTPUT%" %USERPROFILE%\Desktop\. 2>&1>NUL
    set RETURNCODE=1
)


rd /s /q "%WORKINGDIR%"

echo.
echo %ESC%[42mLog collection complete.  Please upload the following file:%ESC%[0m
echo.
echo     %OUTPUTDIR%\%CABOUTPUT%
echo.

if "%OneDriveUploadKey%"=="1" (
    echo %ESC%[42mUploading file to OneDrive now...%ESC%[0m
    call :OneDriveUpload
)
goto :Return

if "%SENDMAIL%"=="1" (
    echo %ESC%[42mPreparing email notify GIC O365 support on completion...%ESC%[0m
    
    call :SendMail
)
goto :Return

REM -----------
REM * CAB IT! *
REM -----------
:CABIT
set DIRECTIVEFILE=%TEMP%\Schema.ddf
set TARGET=%1
set TEMPFILE=%TEMP%\TEMP-%RANDOM%.tmp

if not exist %TARGET% (
    echo %TARGET% does not exist.
    goto :Return
)

pushd %TARGET%

echo. > %DIRECTIVEFILE%
echo .set CabinetNameTemplate=%CABOUTPUT% >> %DIRECTIVEFILE%
echo .set DiskDirectoryTemplate= >> %DIRECTIVEFILE%
echo .set InfFileName=%TEMPFILE% >> %DIRECTIVEFILE%
echo .set RptFileName=%TEMPFILE% >> %DIRECTIVEFILE%
echo .set MaxDiskSize=0 >> %DIRECTIVEFILE%
echo .set CompressionType=LZX >> %DIRECTIVEFILE%

del /f %TEMPFILE% 2>NUL

call :CAB_DIR .

makecab.exe /f %DIRECTIVEFILE%

del /f %DIRECTIVEFILE% 2>NUL
del /f %TEMPFILE% 2>NUL

popd
goto :Return

REM CAB Helper
:CAB_DIR
echo .set DestinationDir=%1 >> %DIRECTIVEFILE%
for /f "tokens=*" %%i in ('dir /b /a:-d %1') do (
    echo "%~1\%%i" >> %DIRECTIVEFILE%
)
for /f "tokens=*" %%i in ('dir /b /a:d %1') do (
    call :CAB_DIR "%~1\%%i"
)
goto :Return

:OneDriveUpload
xcopy  "%OUTPUTDIR%\%CABOUTPUT%" "%ONEDRIVE%"
msg %USERNAME% OneDrive Log Collection completed. Please go to your OneDrive folder and share %CABOUTPUT% with our support team now.
goto :Return

:SendMail
start mailto:yaoyingying@gic.com.sg?subject=[OneDrive%%20Issue%%20Logs]%%20New%%20logs%%20from%%20%computername%^&body=A%%20new%%20set%%20of%%20logs%%20have%%20been%%20collected%%20from%%20device%%20%computername%.%%20The%%20logs%%20can%%20be%%20found%%20here:%%0D%%0A%%20%CabOutput%%%20and%%20OneDrive%%0D%%0A%%0D%%0AYou%%20can%%20choose%%20to%%20send%%20this%%20notification%%20email%%20to%%20our%%20support%%20group%%20for%%20O365.%%20Thank%%20you"
goto :Return

:Return
exit /b %RETURNCODE%
