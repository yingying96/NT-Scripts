cd "%~dp0"

@echo off
rem ############Closing OneDrive############
Taskkill /IM "OneDrive*" /F

rem ############Uninstalling OneDrive############
%SystemRoot%\SysWOW64\OneDriveSetup.exe /uninstall

rem ############Installing OneDrive############
C:\Users\yaoying3\Downloads\OneDriveSetup.exe /quiet
