@echo off
setlocal EnableDelayedExpansion
title OpenClaw Gateway

echo ========================================
echo   OpenClaw Gateway - Windows Version
echo ========================================
echo.

cd /d "%~dp0"

echo [1/5] Checking environment...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js not found. Please install Node.js first.
    pause
    exit /b 1
)
node --version
echo.

echo [2/5] Checking dependencies...
if not exist "node_modules" (
    echo [INFO] Installing dependencies...
    call npm install
    if errorlevel 1 (
        echo [ERROR] Dependency installation failed
        pause
        exit /b 1
    )
) else (
    echo [OK] Dependencies ready
)
echo.

echo [3/5] Checking UI assets...
if exist "dist\control-ui\index.html" (
    echo [OK] UI assets ready
) else (
    echo [INFO] Building UI assets...
    call pnpm ui:build
    if errorlevel 1 (
        echo [ERROR] UI build failed
        pause
        exit /b 1
    )
    echo [OK] UI built successfully
)
echo.

echo [4/5] Getting Token...
set TOKEN_FILE=%USERPROFILE%\.openclaw\openclaw.json
if exist "%TOKEN_FILE%" (
    for /f "usebackq tokens=4 delims=:," %%a in (`findstr /C:"gateway" /C:"auth" /C:"token" "%TOKEN_FILE%"`) do (
        set TOKEN=%%a
        set TOKEN=!TOKEN:"=!
        set TOKEN=!TOKEN:,=!
        set TOKEN=!TOKEN: =!
        if not "!TOKEN!"=="" (
            if not "!TOKEN!"=="gateway" (
                if not "!TOKEN!"=="auth" (
                    if not "!TOKEN!"=="token" (
                        goto :token_done
                    )
                )
            )
        )
    )
) else (
    echo [WARN] Config file not found
)

:token_done
if defined TOKEN (
    echo [OK] Token: !TOKEN!
) else (
    echo [WARN] Token not found
)
echo.

echo [5/5] Cleaning up previous processes...
taskkill /F /IM node.exe /T >nul 2>&1
echo [OK] Processes cleaned
echo.

if defined TOKEN (
    set GATEWAY_URL=http://127.0.0.1:18789/#token=!TOKEN!
) else (
    set GATEWAY_URL=http://127.0.0.1:18789/
)

echo ========================================
echo.
echo Access URL: !GATEWAY_URL!
echo !GATEWAY_URL! | clip
echo [INFO] URL copied to clipboard
echo.
echo [TIP] Browser will open in 3 seconds...
echo.
echo IMPORTANT: Keep this window OPEN
echo Closing this window will STOP the server.
echo Press Ctrl+C to stop.
echo.
echo ========================================
echo.

start /B cmd /c "ping 127.0.0.1 -n 4 >nul 2>&1 && start !GATEWAY_URL!"

echo [Starting] OpenClaw Gateway...
echo.
node openclaw.mjs gateway run

echo.
echo [INFO] Server stopped.
pause
endlocal
