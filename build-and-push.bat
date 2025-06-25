@echo off
echo ===================================
echo Building and Pushing Zonos API Docker Image
echo ===================================

REM Set variables
set DOCKER_USERNAME=jiufen
set IMAGE_NAME=zonos-api
set TAG=latest

echo.
echo Building Docker image: %DOCKER_USERNAME%/%IMAGE_NAME%:%TAG%
echo.

REM Build the Docker image
docker build -t %DOCKER_USERNAME%/%IMAGE_NAME%:%TAG% .

IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo Error: Docker build failed!
    exit /b %ERRORLEVEL%
)

echo.
echo Docker image built successfully!
echo.

REM Log in to Docker Hub
echo Logging in to Docker Hub as %DOCKER_USERNAME%
echo Please enter your Docker Hub password when prompted:
docker login -u %DOCKER_USERNAME%

IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo Error: Docker login failed!
    exit /b %ERRORLEVEL%
)

echo.
echo Pushing image to Docker Hub: %DOCKER_USERNAME%/%IMAGE_NAME%:%TAG%
echo.

REM Push the Docker image
docker push %DOCKER_USERNAME%/%IMAGE_NAME%:%TAG%

IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo Error: Docker push failed!
    exit /b %ERRORLEVEL%
)

echo.
echo ===================================
echo Success! Docker image has been built and pushed to Docker Hub.
echo Image: %DOCKER_USERNAME%/%IMAGE_NAME%:%TAG%
echo ===================================

REM Log out from Docker Hub
docker logout

echo.
echo Press any key to exit...
pause > nul
