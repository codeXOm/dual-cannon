@echo off
echo ============================================================
echo   DUAL CANNON: PUSH TO GITHUB (codeXOm)
echo ============================================================
echo.
echo 1. Ensure you have created the empty repository on GitHub:
echo    https://github.com/new
echo    Repository Name: dual-cannon
echo.
echo Press any key once the repository is created...
pause > nul
echo.
echo Pushing project to https://github.com/codeXOm/dual-cannon.git ...
git push -u origin main
echo.
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Project successfully uploaded to https://github.com/codeXOm/dual-cannon !
) else (
    echo [NOTE] If push was canceled or failed, check your browser for the GitHub login prompt.
)
echo.
pause
