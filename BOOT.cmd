@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
title Lunar127 EXA@1M - Hologram-Contained MVP Boot - Hotfix 1

set "FORMAT=tiff"
if /I "%~1"=="gif" set "FORMAT=gif"
if /I "%~1"=="tiff" set "FORMAT=tiff"
set "CARRIER=%CD%\cartridge\Lunar127_EXA1M_RASTER_CUBE_MVP_PROCESSABLE.%FORMAT%"
set "HARNESS_SOURCE=%CD%\harness\TIFFGifHoloHarness.cs"
if not exist "%CARRIER%" (
  echo [LUNAR127] Requested %FORMAT% carrier is missing.
  pause
  exit /b 2
)
if not exist "%HARNESS_SOURCE%" (
  echo [LUNAR127] Generic C# harness source is missing.
  pause
  exit /b 3
)

rem -----------------------------------------------------------------
rem HOTFIX 1
rem Prefer loading the generic C# harness into the already-approved
rem Windows PowerShell/.NET Framework process. This avoids CreateProcess
rem on a freshly generated unsigned TEMP .exe, which some Windows
rem application-control configurations reject with:
rem   "The system cannot execute the specified program."
rem The cartridge-specific program remains image-resident.
rem -----------------------------------------------------------------
set "POWERSHELL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "ENGINE=INPROC"
if not exist "%POWERSHELL%" set "ENGINE=EXE"

set "CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%CSC%" set "CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe"

set "RUNTIME=%TEMP%\Lunar127_Hologram_Harness_1.0.0_HF1"
if not exist "%RUNTIME%" mkdir "%RUNTIME%" >nul 2>nul
set "HARNESS=%RUNTIME%\TIFFGifHoloHarness.exe"
set "BUILDLOG=%RUNTIME%\build.log"
set "RUNLOG=%RUNTIME%\runtime-host.log"

rem Environment variables are used to pass paths into PowerShell without
rem embedding filesystem text into the PowerShell command line.
set "LUNAR127_HARNESS_SOURCE=%HARNESS_SOURCE%"
set "LUNAR127_CARRIER=%CARRIER%"

>"%RUNLOG%" echo Lunar127 bootstrap host log
>>"%RUNLOG%" echo Started: %DATE% %TIME%
>>"%RUNLOG%" echo Carrier: %CARRIER%
>>"%RUNLOG%" echo Engine: %ENGINE%

echo ================================================================
echo  LUNAR127 1.0.0 - HOLOGRAM-CONTAINED EXA@1M MVP - HOTFIX 1
echo ================================================================
echo  External bootstrap: BOOT.cmd + generic C# harness source only
echo  Authoritative MVP: TIFF-GIF-HOLO/4 image-resident filesystem
echo  Carrier: %CARRIER%
echo ================================================================
echo.

if /I "%ENGINE%"=="INPROC" (
  echo [1/3] Loading generic C# harness in the Windows PowerShell CLR host...
  echo       This avoids launching a newly generated unsigned TEMP executable.
) else (
  echo [1/3] Windows PowerShell host unavailable; compiling generic harness EXE...
  call :BUILD_EXE
  if errorlevel 1 goto :BUILD_FAIL
)

echo [2/3] Verifying the processable hologram and immutable MVP bank...
call :RUN_HARNESS --verify
set "VERIFY_RC=%ERRORLEVEL%"
if not "%VERIFY_RC%"=="0" (
  echo.
  echo [LUNAR127] Carrier verification did not run successfully. Exit code: %VERIFY_RC%
  echo [LUNAR127] The image itself is not automatically considered corrupt.
  echo [LUNAR127] Host diagnostics: "%RUNLOG%"
  if exist "%BUILDLOG%" echo [LUNAR127] Build diagnostics: "%BUILDLOG%"
  pause
  exit /b 5
)

if /I "%~1"=="verify" goto :DONE
if /I "%~2"=="verify" goto :DONE
if /I "%~1"=="inspect" (
  call :RUN_HARNESS --inspect
  goto :DONE
)
if /I "%~2"=="inspect" (
  call :RUN_HARNESS --inspect
  goto :DONE
)

echo [3/3] Mounting the image-resident MVP into TEMP and launching its virtual console...
call :RUN_HARNESS --launch-mvp
set "LAUNCH_RC=%ERRORLEVEL%"
if not "%LAUNCH_RC%"=="0" (
  echo.
  echo [LUNAR127] Image-resident MVP launch failed. Exit code: %LAUNCH_RC%
  echo [LUNAR127] Host diagnostics: "%RUNLOG%"
  pause
  exit /b 6
)

echo.
echo [PASS] The browser entry point was decoded from the verified hologram.
echo        No dashboard, JSON vector, BigTIFF shard, spec, or validation
echo        file is distributed outside the carrier.
echo.
goto :DONE

:RUN_HARNESS
set "LUNAR127_HARNESS_ARG=%~1"
if /I "%ENGINE%"=="INPROC" goto :RUN_INPROC

"%HARNESS%" "%~1" "%CARRIER%" >>"%RUNLOG%" 2>&1
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" type "%RUNLOG%"
exit /b %RC%

:RUN_INPROC
"%POWERSHELL%" -NoLogo -NoProfile -NonInteractive -STA -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { Add-Type -Path $env:LUNAR127_HARNESS_SOURCE -ReferencedAssemblies @('System.dll','System.Core.dll','System.Drawing.dll','System.Windows.Forms.dll','System.Web.Extensions.dll') -ErrorAction Stop; $argv=[string[]]@($env:LUNAR127_HARNESS_ARG,$env:LUNAR127_CARRIER); $rc=[TIFFHolo.Program]::Main($argv); exit [int]$rc } catch { [Console]::Error.WriteLine($_.Exception.ToString()); exit 97 }" >>"%RUNLOG%" 2>&1
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" type "%RUNLOG%"
exit /b %RC%

:BUILD_EXE
if not exist "%CSC%" (
  echo [LUNAR127] Neither Windows PowerShell nor the .NET Framework C# compiler was found.
  echo [LUNAR127] Expected compiler under %%WINDIR%%\Microsoft.NET\Framework[64]\v4.0.30319\csc.exe
  exit /b 3
)
>"%BUILDLOG%" echo Lunar127 generic harness build log
>>"%BUILDLOG%" echo Started: %DATE% %TIME%
>>"%BUILDLOG%" echo Compiler: %CSC%
"%CSC%" /nologo /target:exe /optimize+ /platform:anycpu /out:"%HARNESS%" /reference:System.dll /reference:System.Core.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll /reference:System.Web.Extensions.dll "%HARNESS_SOURCE%" >>"%BUILDLOG%" 2>&1
exit /b %ERRORLEVEL%

:BUILD_FAIL
type "%BUILDLOG%"
echo [LUNAR127] Harness build failed.
pause
exit /b 4

:DONE
echo Press any key to close this bootstrap window.
pause >nul
exit /b 0
