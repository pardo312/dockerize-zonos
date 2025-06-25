#!/usr/bin/env python3
"""
Test script for the Zonos Voice Cloning API
Usage: python test_api.py
"""

import requests
import time
import os

# API base URL
BASE_URL = "http://localhost:8000"

def test_health():
    """Test the health endpoint"""
    print("Testing health endpoint...")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Health check: {response.status_code}")
    print(f"Response: {response.json()}")
    return response.status_code == 200

def test_voice_cloning():
    """Test voice cloning with the example audio"""
    print("\nTesting voice cloning...")
    
    # Check if example audio exists
    audio_file = "assets/exampleaudio.m4a"
    if not os.path.exists(audio_file):
        print(f"Error: {audio_file} not found!")
        return False
    
    # Prepare the request
    files = {
        'reference_audio': ('exampleaudio.m4a', open(audio_file, 'rb'), 'audio/m4a')
    }
    
    data = {
        'text': 'Hello! This is a test of voice cloning using Zonos. The quick brown fox jumps over the lazy dog.',
        'language': 'en-us',
        'temperature': 1.0,
        'top_p': 0.9
    }
    
    print(f"Sending request with text: '{data['text']}'")
    print("This may take a few moments...")
    
    try:
        response = requests.post(f"{BASE_URL}/clone-voice", files=files, data=data, timeout=120)
        files['reference_audio'][1].close()  # Close the file
        
        if response.status_code == 200:
            result = response.json()
            print(f"Success! Generated audio:")
            print(f"  - URL: {BASE_URL}{result['audio_url']}")
            print(f"  - Duration: {result['duration']} seconds")
            print(f"  - Filename: {result['filename']}")
            print(f"  - Sampling rate: {result['sampling_rate']} Hz")
            return True
        else:
            print(f"Error: {response.status_code}")
            print(f"Response: {response.text}")
            return False
            
    except requests.exceptions.Timeout:
        print("Request timed out. The model might still be loading or processing.")
        return False
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_audio_download(filename):
    """Test downloading generated audio"""
    print(f"\nTesting audio download for {filename}...")
    
    try:
        response = requests.get(f"{BASE_URL}/audio/{filename}")
        if response.status_code == 200:
            # Save the audio file locally
            with open(f"downloaded_{filename}", 'wb') as f:
                f.write(response.content)
            print(f"Audio downloaded successfully as 'downloaded_{filename}'")
            return True
        else:
            print(f"Error downloading audio: {response.status_code}")
            return False
    except Exception as e:
        print(f"Error: {e}")
        return False

def main():
    print("Zonos Voice Cloning API Test")
    print("=" * 40)
    
    # Test health endpoint
    if not test_health():
        print("Health check failed. Make sure the API is running.")
        return
    
    # Wait a moment for the model to be fully loaded
    print("\nWaiting for model to be ready...")
    time.sleep(5)
    
    # Test voice cloning
    if test_voice_cloning():
        print("\n✅ Voice cloning test passed!")
        
        # You can uncomment the line below to test audio download
        # test_audio_download("generated_<some-uuid>.wav")
    else:
        print("\n❌ Voice cloning test failed!")

if __name__ == "__main__":
    main()
