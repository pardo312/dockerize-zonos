#!/bin/bash

# Zonos Voice Cloning API Deployment Script

set -e

echo "🎤 Zonos Voice Cloning API Deployment"
echo "====================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check for NVIDIA Docker support
if ! docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi &> /dev/null; then
    echo "⚠️  Warning: NVIDIA Docker support not detected."
    echo "   The API will try to run on CPU, which will be much slower."
    echo "   For GPU support, install nvidia-docker2."
    read -p "   Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "🔧 Building Docker image..."
docker-compose build

echo "🚀 Starting the API service..."
docker-compose up -d

echo "⏳ Waiting for the service to start..."
sleep 10

# Wait for the service to be ready
echo "🔍 Checking service health..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo "✅ Service is ready!"
        break
    else
        echo "   Attempt $attempt/$max_attempts - Service not ready yet..."
        sleep 10
        ((attempt++))
    fi
done

if [ $attempt -gt $max_attempts ]; then
    echo "❌ Service failed to start within expected time."
    echo "   Check the logs with: docker-compose logs -f zonos-api"
    exit 1
fi

echo ""
echo "🎉 Zonos Voice Cloning API is now running!"
echo ""
echo "📡 API Endpoints:"
echo "   • Health Check: http://localhost:8000/health"
echo "   • API Docs: http://localhost:8000/docs"
echo "   • Voice Cloning: POST http://localhost:8000/clone-voice"
echo ""
echo "🧪 Test the API:"
echo "   python test_api.py"
echo ""
echo "📊 Monitor logs:"
echo "   docker-compose logs -f zonos-api"
echo ""
echo "🛑 Stop the service:"
echo "   docker-compose down"
echo ""

# Test if Python is available for running the test script
if command -v python3 &> /dev/null; then
    read -p "🧪 Run the test script now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Running test script..."
        python3 test_api.py
    fi
elif command -v python &> /dev/null; then
    read -p "🧪 Run the test script now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Running test script..."
        python test_api.py
    fi
else
    echo "⚠️  Python not found. Install Python to run the test script."
fi

echo ""
echo "🎤 Happy voice cloning!"
