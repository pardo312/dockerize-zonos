# Zonos Voice Cloning API

A FastAPI-based REST API for voice cloning using the Zonos TTS model by Zyphra. This service allows you to clone voices by providing reference audio and generate speech with the cloned voice.

## Features

- 🎤 **Voice Cloning**: Clone any voice with just a few seconds of reference audio
- 🌍 **Multilingual Support**: English, Japanese, Chinese, French, and German
- 🎛️ **Fine Control**: Adjust temperature, top-p, and other generation parameters
- 🚀 **Fast Generation**: Real-time factor of ~2x on RTX 4090
- 🐳 **Docker Ready**: Easy deployment with Docker and Docker Compose
- 📡 **REST API**: Simple HTTP endpoints for integration
- 🔄 **Auto Cleanup**: Automatic cleanup of temporary files

## System Requirements

- **GPU**: 6GB+ VRAM (NVIDIA GPU recommended)
- **RAM**: 8GB+ system RAM
- **Storage**: ~10GB for Docker image and models
- **Docker**: Docker with NVIDIA GPU support

## Quick Start

### 1. Clone and Build

```bash
git clone <your-repo>
cd <your-repo>

# Build and start the service
docker-compose up --build
```

### 2. Wait for Model Loading

The first startup will take several minutes as it downloads the Zonos model (~2GB). Watch the logs:

```bash
docker-compose logs -f zonos-api
```

Look for: `Model loaded successfully on device: cuda:0`

### 3. Test the API

```bash
# Check if the service is ready
curl http://localhost:8000/health

# Test voice cloning (using the provided test script)
python test_api.py
```

## API Endpoints

### Health Check
```http
GET /health
```

Returns the service status and model loading state.

### Voice Cloning
```http
POST /clone-voice
```

**Parameters:**
- `text` (required): Text to synthesize (max 1000 characters)
- `reference_audio` (required): Audio file for voice cloning (mp3, wav, m4a)
- `language` (optional): Language code (default: "en-us")
  - Supported: `en-us`, `ja`, `zh`, `fr`, `de`
- `temperature` (optional): Sampling temperature 0.1-2.0 (default: 1.0)
- `top_p` (optional): Top-p sampling 0.1-1.0 (default: 0.9)

**Response:**
```json
{
  "audio_url": "/audio/generated_12345.wav",
  "filename": "generated_12345.wav",
  "duration": 3.2,
  "text": "Hello, world!",
  "language": "en-us",
  "sampling_rate": 44100,
  "parameters": {
    "temperature": 1.0,
    "top_p": 0.9
  }
}
```

### Download Audio
```http
GET /audio/{filename}
```

Downloads the generated audio file.

### Delete Audio
```http
DELETE /audio/{filename}
```

Deletes a generated audio file.

## Usage Examples

### cURL Example

```bash
curl -X POST "http://localhost:8000/clone-voice" \
  -F "text=Hello! This is my cloned voice speaking." \
  -F "reference_audio=@path/to/reference.wav" \
  -F "language=en-us" \
  -F "temperature=1.0"
```

### Python Example

```python
import requests

# Voice cloning request
files = {'reference_audio': open('reference.wav', 'rb')}
data = {
    'text': 'Hello! This is my cloned voice.',
    'language': 'en-us',
    'temperature': 1.0,
    'top_p': 0.9
}

response = requests.post('http://localhost:8000/clone-voice', 
                        files=files, data=data)

if response.status_code == 200:
    result = response.json()
    audio_url = f"http://localhost:8000{result['audio_url']}"
    print(f"Generated audio: {audio_url}")
    
    # Download the audio
    audio_response = requests.get(audio_url)
    with open('generated_voice.wav', 'wb') as f:
        f.write(audio_response.content)
```

### JavaScript Example

```javascript
const formData = new FormData();
formData.append('text', 'Hello! This is my cloned voice.');
formData.append('reference_audio', audioFile); // File object
formData.append('language', 'en-us');

fetch('http://localhost:8000/clone-voice', {
    method: 'POST',
    body: formData
})
.then(response => response.json())
.then(data => {
    console.log('Generated audio URL:', data.audio_url);
    // Use the audio_url to play or download the audio
});
```

## Configuration

### Environment Variables

- `CUDA_VISIBLE_DEVICES`: GPU device to use (default: 0)

### Model Selection

By default, the API uses the transformer model (`Zyphra/Zonos-v0.1-transformer`). To use the hybrid model, modify `main.py`:

```python
# Change this line in main.py
model = Zonos.from_pretrained("Zyphra/Zonos-v0.1-hybrid", device=device)
```

Note: The hybrid model requires more VRAM and additional dependencies.

## Development

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Install Zonos
git clone https://github.com/Zyphra/Zonos.git
cd Zonos
pip install -e .
cd ..

# Run the API
python main.py
```

### Docker Development

```bash
# Build the image
docker build -t zonos-api .

# Run with GPU support
docker run --gpus all -p 8000:8000 -v $(pwd)/generated:/app/generated zonos-api
```

## Troubleshooting

### Common Issues

1. **Model Loading Fails**
   - Ensure you have enough VRAM (6GB+)
   - Check CUDA installation: `nvidia-smi`
   - Verify Docker GPU support: `docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi`

2. **Audio Processing Errors**
   - Ensure reference audio is valid (mp3, wav, m4a)
   - Check audio file size (recommended: 10-30 seconds)
   - Verify audio is not corrupted

3. **Generation Takes Too Long**
   - First generation is slower due to model compilation
   - Subsequent generations should be faster
   - Consider using shorter text for testing

4. **Out of Memory**
   - Reduce batch size or use shorter text
   - Restart the container to clear GPU memory
   - Consider using the transformer model instead of hybrid

### Logs

```bash
# View container logs
docker-compose logs -f zonos-api

# Check GPU usage
nvidia-smi

# Monitor container resources
docker stats
```

## API Documentation

Once the service is running, visit:
- **Interactive API docs**: http://localhost:8000/docs
- **ReDoc documentation**: http://localhost:8000/redoc

## License

This project uses the Zonos model which is licensed under Apache-2.0. See the [Zonos repository](https://github.com/Zyphra/Zonos) for more details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Support

For issues related to:
- **Zonos model**: Visit the [official Zonos repository](https://github.com/Zyphra/Zonos)
- **This API wrapper**: Create an issue in this repository
