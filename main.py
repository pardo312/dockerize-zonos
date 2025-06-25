import os
import uuid
import asyncio
from pathlib import Path
from typing import Optional
import torch
import torchaudio
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
import aiofiles
from contextlib import asynccontextmanager

from zonos.model import Zonos
from zonos.conditioning import make_cond_dict
from zonos.utils import DEFAULT_DEVICE as device

# Global model instance
model = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Load the model on startup
    global model
    print("Loading Zonos model...")
    try:
        # Use transformer model by default (lighter than hybrid)
        model = Zonos.from_pretrained("Zyphra/Zonos-v0.1-transformer", device=device)
        print(f"Model loaded successfully on device: {device}")
    except Exception as e:
        print(f"Error loading model: {e}")
        raise e
    
    yield
    
    # Cleanup on shutdown
    print("Shutting down...")

app = FastAPI(
    title="Zonos Voice Cloning API",
    description="API for voice cloning using Zonos TTS model",
    version="1.0.0",
    lifespan=lifespan
)

# Create directories
os.makedirs("uploads", exist_ok=True)
os.makedirs("generated", exist_ok=True)

# Mount static files for serving generated audio
app.mount("/audio", StaticFiles(directory="generated"), name="audio")

@app.get("/")
async def root():
    return {
        "message": "Zonos Voice Cloning API",
        "endpoints": {
            "POST /clone-voice": "Clone voice with reference audio",
            "GET /audio/{filename}": "Download generated audio",
            "GET /health": "Health check"
        }
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "model_loaded": model is not None,
        "device": str(device)
    }

@app.post("/clone-voice")
async def clone_voice(
    text: str = Form(..., description="Text to synthesize"),
    reference_audio: UploadFile = File(..., description="Reference audio file for voice cloning"),
    language: str = Form("en-us", description="Language code (e.g., en-us, ja, zh, fr, de)"),
    temperature: float = Form(1.0, description="Sampling temperature (0.1-2.0)"),
    top_p: float = Form(0.9, description="Top-p sampling (0.1-1.0)")
):
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    # Validate inputs
    if not text.strip():
        raise HTTPException(status_code=400, detail="Text cannot be empty")
    
    if len(text) > 1000:
        raise HTTPException(status_code=400, detail="Text too long (max 1000 characters)")
    
    # Validate audio file
    if not reference_audio.content_type or not reference_audio.content_type.startswith('audio/'):
        raise HTTPException(status_code=400, detail="Invalid audio file format")
    
    try:
        # Generate unique filename for upload
        upload_id = str(uuid.uuid4())
        upload_filename = f"upload_{upload_id}.{reference_audio.filename.split('.')[-1]}"
        upload_path = f"uploads/{upload_filename}"
        
        # Save uploaded file
        async with aiofiles.open(upload_path, 'wb') as f:
            content = await reference_audio.read()
            await f.write(content)
        
        # Load and process reference audio
        try:
            wav, sampling_rate = torchaudio.load(upload_path)
            
            # Convert to mono if stereo
            if wav.shape[0] > 1:
                wav = wav.mean(dim=0, keepdim=True)
            
            # Create speaker embedding
            speaker = model.make_speaker_embedding(wav, sampling_rate)
            
        except Exception as e:
            # Clean up upload file
            if os.path.exists(upload_path):
                os.remove(upload_path)
            raise HTTPException(status_code=400, detail=f"Error processing audio file: {str(e)}")
        
        # Generate speech
        try:
            cond_dict = make_cond_dict(
                text=text,
                speaker=speaker,
                language=language,
                temperature=temperature,
                top_p=top_p
            )
            conditioning = model.prepare_conditioning(cond_dict)
            
            # Generate audio codes
            codes = model.generate(conditioning)
            
            # Decode to audio
            wavs = model.autoencoder.decode(codes).cpu()
            
            # Save generated audio
            output_filename = f"generated_{upload_id}.wav"
            output_path = f"generated/{output_filename}"
            torchaudio.save(output_path, wavs[0], model.autoencoder.sampling_rate)
            
            # Get audio duration
            duration = wavs[0].shape[1] / model.autoencoder.sampling_rate
            
            # Clean up upload file
            if os.path.exists(upload_path):
                os.remove(upload_path)
            
            return {
                "audio_url": f"/audio/{output_filename}",
                "filename": output_filename,
                "duration": round(duration, 2),
                "text": text,
                "language": language,
                "sampling_rate": model.autoencoder.sampling_rate,
                "parameters": {
                    "temperature": temperature,
                    "top_p": top_p
                }
            }
            
        except Exception as e:
            # Clean up files
            if os.path.exists(upload_path):
                os.remove(upload_path)
            raise HTTPException(status_code=500, detail=f"Error generating speech: {str(e)}")
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")

@app.get("/audio/{filename}")
async def get_audio(filename: str):
    file_path = f"generated/{filename}"
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Audio file not found")
    
    return FileResponse(
        file_path,
        media_type="audio/wav",
        filename=filename
    )

@app.delete("/audio/{filename}")
async def delete_audio(filename: str):
    file_path = f"generated/{filename}"
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Audio file not found")
    
    try:
        os.remove(file_path)
        return {"message": f"Audio file {filename} deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error deleting file: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
