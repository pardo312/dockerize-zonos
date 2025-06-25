FROM pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel

# Install system dependencies
RUN apt update && \
    apt install -y espeak-ng ffmpeg git && \
    rm -rf /var/lib/apt/lists/*

# Install uv for faster Python package management
RUN pip install uv

# Set working directory
WORKDIR /app

# Clone and install Zonos
RUN git clone https://github.com/Zyphra/Zonos.git /tmp/zonos && \
    cd /tmp/zonos && \
    uv pip install --system -e . && \
    uv pip install --system -e .[compile] && \
    cd /app && \
    cp -r /tmp/zonos/zonos ./zonos/ && \
    cp /tmp/zonos/pyproject.toml ./ && \
    rm -rf /tmp/zonos

# Install FastAPI and additional dependencies
RUN uv pip install --system fastapi uvicorn python-multipart aiofiles

# Copy application files
COPY . .

# Create directories for uploads and generated audio
RUN mkdir -p uploads generated

# Expose port
EXPOSE 8000

# Run the FastAPI server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
