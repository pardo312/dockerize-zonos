# Use NVIDIA CUDA base image with Python
FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

# Set working directory
WORKDIR /app

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    git \
    espeak-ng \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

# Create directories for uploads and generated audio
RUN mkdir -p /app/uploads /app/generated

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip3 install --no-cache-dir -U pip setuptools wheel
RUN pip3 install --no-cache-dir -r requirements.txt

# Install Zonos from GitHub
RUN git clone https://github.com/Zyphra/Zonos.git /tmp/Zonos \
    && cd /tmp/Zonos \
    && pip3 install -e . \
    && cd /app \
    && rm -rf /tmp/Zonos/.git

# Copy application code
COPY . .

# Expose port
EXPOSE 8000

# Command to run the application
CMD ["python3", "main.py"]
