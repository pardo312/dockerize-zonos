@echo off
setlocal enabledelayedexpansion

echo 🎤 Zonos Voice Cloning API Deployment
echo =====================================

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not installed. Please install Docker Desktop first.
    pause
    exit /b 1
)

REM Check if Docker Compose is installed
docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker Compose is not installed. Please install Docker Compose first.
    pause
    exit /b 1
)

echo 🔧 Building Docker image...
docker-compose build
if errorlevel 1 (
    echo ❌ Failed to build Docker image.
    pause
    exit /b 1
)

echo 🚀 Starting the API service...
docker-compose up -d
if errorlevel 1 (
    echo ❌ Failed to start the service.
    pause
    exit /b 1
)

echo ⏳ Waiting for the service to start...
timeout /t 10 /nobreak >nul

echo 🔍 Checking service health...
set max_attempts=30
set attempt=1

:check_health
curl -s http://localhost:8000/health >nul 2>&1
if errorlevel 1 (
    echo    Attempt !attempt!/!max_attempts! - Service not ready yet...
    timeout /t 10 /nobreak >nul
    set /a attempt+=1
    if !attempt! leq !max_attempts! goto check_health
    
    echo ❌ Service failed to start within expected time.
    echo    Check the logs with: docker-compose logs -f zonos-api
    pause
    exit /b 1
)

echo ✅ Service is ready!
echo.
echo 🎉 Zonos Voice Cloning API is now running!
echo.
echo 📡 API Endpoints:
echo    • Health Check: http://localhost:8000/health
echo    • API Docs: http://localhost:8000/docs
echo    • Voice Cloning: POST http://localhost:8000/clone-voice
echo.
echo 🧪 Test the API:
echo    python test_api.py
echo.
echo 📊 Monitor logs:
echo    docker-compose logs -f zonos-api
echo.
echo 🛑 Stop the service:
echo    docker-compose down
echo.

REM Check if Python is available
python --version >nul 2>&1
if not errorlevel 1 (
    set /p run_test="🧪 Run the test script now? (y/N): "
    if /i "!run_test!"=="y" (
        echo Running test script...
        python test_api.py
    )
) else (
    echo ⚠️  Python not found. Install Python to run the test script.
)

echo.
echo 🎤 Happy voice cloning!
pause
