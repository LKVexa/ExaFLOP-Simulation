@echo off
setlocal EnableExtensions EnableDelayedExpansion
title ExaFLOP Simulation - GitHub Publisher FIXED

cd /d "%~dp0"

set "REPO_URL=https://github.com/LKVexa/ExaFLOP-Simulation.git"
set "BRANCH=main"
set "LOG=%~dp0GITHUB_PUBLISH.log"

> "%LOG%" echo ============================================================
>>"%LOG%" echo ExaFLOP Simulation - GitHub Publisher FIXED
>>"%LOG%" echo Started: %DATE% %TIME%
>>"%LOG%" echo Root: %CD%
>>"%LOG%" echo Remote: %REPO_URL%
>>"%LOG%" echo ============================================================

echo ============================================================
echo  ExaFLOP Simulation - GitHub Publisher FIXED
echo ============================================================
echo.
echo Repository root:
echo   %CD%
echo.
echo GitHub repository:
echo   %REPO_URL%
echo.
echo This script changes repository-local Git settings only.
echo It does NOT change global Git identity.
echo ============================================================
echo.

where git >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git was not found in PATH.
    echo Install Git for Windows, then run this file again.
    >>"%LOG%" echo [ERROR] git.exe not found in PATH.
    goto :FAIL
)

for /f "delims=" %%V in ('git --version 2^>nul') do set "GIT_VERSION=%%V"
echo [OK] !GIT_VERSION!
>>"%LOG%" echo [OK] !GIT_VERSION!

echo.
if not exist ".git\" (
    echo [1/8] Initializing local Git repository...
    git init >>"%LOG%" 2>&1
    if errorlevel 1 (
        echo [ERROR] git init failed.
        goto :FAIL
    )
) else (
    echo [1/8] Existing .git repository detected.
)

echo.
echo [2/8] Configuring repository-local commit identity...

set "GIT_NAME="
for /f "usebackq delims=" %%A in (`git config --local user.name 2^>nul`) do set "GIT_NAME=%%A"

if not defined GIT_NAME goto :ASK_NAME
echo [OK] Existing author name: !GIT_NAME!
goto :NAME_READY

:ASK_NAME
echo.
echo Git needs a commit author name for THIS repository.
set /p "GIT_NAME=Git author name: "
if not defined GIT_NAME (
    echo [ERROR] Author name cannot be empty.
    goto :FAIL
)
git config --local user.name "!GIT_NAME!" >>"%LOG%" 2>&1
if errorlevel 1 (
    echo [ERROR] Could not save repository-local author name.
    goto :FAIL
)
echo [OK] Saved author name: !GIT_NAME!

:NAME_READY
set "GIT_EMAIL="
for /f "usebackq delims=" %%A in (`git config --local user.email 2^>nul`) do set "GIT_EMAIL=%%A"

if not defined GIT_EMAIL goto :ASK_EMAIL
echo [OK] Existing author email: !GIT_EMAIL!
goto :EMAIL_READY

:ASK_EMAIL
echo.
echo Git needs a commit author email for THIS repository.
echo You may use your GitHub noreply address if preferred.
set /p "GIT_EMAIL=Git author email: "
if not defined GIT_EMAIL (
    echo [ERROR] Author email cannot be empty.
    goto :FAIL
)
git config --local user.email "!GIT_EMAIL!" >>"%LOG%" 2>&1
if errorlevel 1 (
    echo [ERROR] Could not save repository-local author email.
    goto :FAIL
)
echo [OK] Saved author email: !GIT_EMAIL!

:EMAIL_READY

echo.
echo [3/8] Verifying repository-local identity...
for /f "usebackq delims=" %%A in (`git config --local user.name 2^>nul`) do set "VERIFY_NAME=%%A"
for /f "usebackq delims=" %%A in (`git config --local user.email 2^>nul`) do set "VERIFY_EMAIL=%%A"

if not defined VERIFY_NAME (
    echo [ERROR] Repository-local user.name is still empty.
    goto :FAIL
)
if not defined VERIFY_EMAIL (
    echo [ERROR] Repository-local user.email is still empty.
    goto :FAIL
)

echo [OK] user.name  = !VERIFY_NAME!
echo [OK] user.email = !VERIFY_EMAIL!
>>"%LOG%" echo [OK] user.name=!VERIFY_NAME!
>>"%LOG%" echo [OK] user.email=!VERIFY_EMAIL!

echo.
echo [4/8] Setting branch to %BRANCH%...
git branch -M "%BRANCH%" >>"%LOG%" 2>&1
if errorlevel 1 (
    echo [ERROR] Could not set branch to %BRANCH%.
    goto :FAIL
)

echo.
echo [5/8] Configuring origin...
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    git remote add origin "%REPO_URL%" >>"%LOG%" 2>&1
) else (
    git remote set-url origin "%REPO_URL%" >>"%LOG%" 2>&1
)
if errorlevel 1 (
    echo [ERROR] Could not configure origin.
    goto :FAIL
)

for /f "delims=" %%R in ('git remote get-url origin 2^>nul') do set "ACTIVE_REMOTE=%%R"
echo [OK] origin = !ACTIVE_REMOTE!
>>"%LOG%" echo [OK] origin=!ACTIVE_REMOTE!

echo.
echo [6/8] Staging all repository files and folders...
git add -A >>"%LOG%" 2>&1
if errorlevel 1 (
    echo [ERROR] git add failed.
    goto :FAIL
)

echo.
echo [7/8] Creating commit if needed...
git diff --cached --quiet >nul 2>&1
if errorlevel 1 (
    git commit -m "Publish Lunar127 ExaFLOP simulation" >>"%LOG%" 2>&1
    if errorlevel 1 (
        echo [ERROR] Commit failed.
        echo.
        echo Last Git output:
        powershell -NoProfile -Command "Get-Content -LiteralPath '%LOG%' -Tail 25" 2>nul
        goto :FAIL
    )
    echo [OK] Commit created.
) else (
    git rev-parse --verify HEAD >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Nothing is staged and this repository has no commit.
        echo Make sure this .cmd is inside the repository folder you want to publish.
        goto :FAIL
    )
    echo [OK] No new local changes to commit.
)

echo.
echo [8/8] Pushing %BRANCH% to GitHub...
echo Git Credential Manager may open a browser for authentication.
echo.

git push -u origin "%BRANCH%"
set "PUSH_RC=!ERRORLEVEL!"
>>"%LOG%" echo git push exit code: !PUSH_RC!

if not "!PUSH_RC!"=="0" (
    echo.
    echo [ERROR] GitHub push failed with exit code !PUSH_RC!.
    echo.
    echo Common causes:
    echo   - GitHub authentication was cancelled or expired
    echo   - A file exceeds GitHub's per-file size limit
    echo   - Network access to github.com is blocked
    echo   - The remote branch already contains unrelated history
    echo.
    echo Full log:
    echo   "%LOG%"
    goto :FAIL
)

echo.
echo ============================================================
echo  PUBLISH SUCCESS
echo ============================================================
echo.
echo Repository:
echo   https://github.com/LKVexa/ExaFLOP-Simulation
echo.
echo Branch:
echo   %BRANCH%
echo.
echo Log:
echo   "%LOG%"
echo.
>>"%LOG%" echo [SUCCESS] Published to %REPO_URL% branch %BRANCH%.
pause
exit /b 0

:FAIL
echo.
echo ============================================================
echo  PUBLISH FAILED
echo ============================================================
echo.
echo Review:
echo   "%LOG%"
echo.
pause
exit /b 1
