@echo off
echo ========================================
echo     Quarto Installation Helper
echo ========================================
echo.

echo Checking if Quarto is already installed...
quarto --version >nul 2>&1
if %errorlevel% == 0 (
    echo Quarto is already installed!
    quarto --version
    goto :check_tinytex
) else (
    echo Quarto is not installed.
    echo.
    echo Please follow these steps:
    echo 1. Go to https://quarto.org/docs/get-started/
    echo 2. Download the Windows installer
    echo 3. Run it as administrator
    echo 4. Restart this script
    echo.
    pause
    exit /b 1
)

:check_tinytex
echo.
echo Checking TinyTeX installation...
quarto check 2>&1 | findstr "tinytex" >nul
if %errorlevel% == 0 (
    echo TinyTeX appears to be installed.
) else (
    echo Installing TinyTeX for PDF support...
    quarto install tinytex
)

echo.
echo Running Quarto system check...
quarto check

echo.
echo ========================================
echo Installation complete!
echo You can now render your Quarto documents to PDF.
echo.
echo Try: quarto render document.qmd --to pdf
echo ========================================
pause
