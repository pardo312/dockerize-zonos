@echo off
setlocal enabledelayedexpansion

echo 🐳 Docker Build and Push to DockerHub
echo ======================================

REM Configuration - Update these variables
set DOCKERHUB_USERNAME=jiufen
set IMAGE_NAME=zonos-voice-cloning-api
set IMAGE_TAG=latest

echo 📝 Current Configuration:
echo    DockerHub Username: %DOCKERHUB_USERNAME%
echo    Image Name: %IMAGE_NAME%
echo    Image Tag: %IMAGE_TAG%
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not installed. Please install Docker Desktop first.
    pause
    exit /b 1
)

REM Prompt for DockerHub username if not set
if "%DOCKERHUB_USERNAME%"=="your-dockerhub-username" (
    set /p DOCKERHUB_USERNAME="Enter your DockerHub username: "
    if "!DOCKERHUB_USERNAME!"=="" (
        echo ❌ DockerHub username is required.
        pause
        exit /b 1
    )
)

REM Full image name
set FULL_IMAGE_NAME=%DOCKERHUB_USERNAME%/%IMAGE_NAME%:%IMAGE_TAG%

echo.
echo 🔐 Logging into DockerHub...
echo Please enter your DockerHub credentials when prompted.
docker login
if errorlevel 1 (
    echo ❌ Failed to login to DockerHub.
    pause
    exit /b 1
)

echo.
echo 🔧 Building Docker image: %FULL_IMAGE_NAME%
docker build -t %FULL_IMAGE_NAME% .
if errorlevel 1 (
    echo ❌ Failed to build Docker image.
    pause
    exit /b 1
)

echo.
echo 📤 Pushing image to DockerHub: %FULL_IMAGE_NAME%
docker push %FULL_IMAGE_NAME%
if errorlevel 1 (
    echo ❌ Failed to push image to DockerHub.
    pause
    exit /b 1
)

echo.
echo ✅ Successfully built and pushed image!
echo.
echo 📋 Image Details:
echo    Full Name: %FULL_IMAGE_NAME%
echo    DockerHub URL: https://hub.docker.com/r/%DOCKERHUB_USERNAME%/%IMAGE_NAME%
echo.
echo 🚀 To run the image:
echo    docker run --gpus all -p 8000:8000 %FULL_IMAGE_NAME%
echo.
echo 📝 To update docker-compose.yml with this image:
echo    Replace 'build: .' with 'image: %FULL_IMAGE_NAME%'
echo.

REM Ask if user wants to create a docker-compose-hub.yml file
set /p create_compose="📦 Create docker-compose-hub.yml for DockerHub image? (y/N): "
if /i "!create_compose!"=="y" (
    echo Creating docker-compose-hub.yml...
    (
        echo version: '3.8'
        echo.
        echo services:
        echo   zonos-api:
        echo     image: %FULL_IMAGE_NAME%
        echo     ports:
        echo       - "8000:8000"
        echo     volumes:
        echo       - ./generated:/app/generated
        echo       - ./uploads:/app/uploads
        echo     environment:
        echo       - CUDA_VISIBLE_DEVICES=0
        echo     deploy:
        echo       resources:
        echo         reservations:
        echo           devices:
        echo             - driver: nvidia
        echo               count: 1
        echo               capabilities: [gpu]
        echo     restart: unless-stopped
        echo     healthcheck:
        echo       test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
        echo       interval: 30s
        echo       timeout: 10s
        echo       retries: 3
        echo       start_period: 60s
    ) > docker-compose-hub.yml
    echo ✅ Created docker-compose-hub.yml
    echo    Use: docker-compose -f docker-compose-hub.yml up
)

echo.
echo 🎉 Build and push completed successfully!
pause
