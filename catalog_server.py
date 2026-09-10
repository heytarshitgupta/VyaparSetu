import json
import os

import google.generativeai as genai
import uvicorn
from fastapi import FastAPI, HTTPException, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

# --- 1. SETUP & CONFIGURATION ---
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise RuntimeError(
        "GEMINI_API_KEY is required. Add GEMINI_API_KEY=your-key to .env "
        "or set it in the terminal before starting the server."
    )

genai.configure(api_key=api_key)

# We can use the same model for both features!
gemini_model = genai.GenerativeModel("gemini-3.5-flash")

app = FastAPI(title="VyaparSetu AI Server")

# Allow Flutter to communicate with this API without CORS blocking it
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

class VoicePayload(BaseModel):
    transcript: str

@app.options("/api/generate-catalog")
async def generate_catalog_options() -> Response:
    return Response(status_code=200)

# --- 2. FEATURE 1: MULTILINGUAL AUTO-CATALOGER ---
@app.post("/api/generate-catalog")
async def generate_catalog(payload: VoicePayload):
    transcript = payload.transcript.strip()
    if not transcript:
        raise HTTPException(status_code=400, detail="Transcript cannot be empty.")

    prompt = f"""
You are an expert e-commerce copywriter. A rural artisan from Punjab just recorded
a voice note describing their product.

Raw voice transcript: "{transcript}"

Respond ONLY with a valid JSON object matching this exact structure:
{{
    "english": {{
        "title": "SEO Optimized Title (max 60 chars)",
        "description": "3-sentence description highlighting craftsmanship.",
        "keywords": ["tag1", "tag2", "tag3", "tag4"]
    }},
    "hindi": {{
        "title": "हिंदी SEO शीर्षक",
        "description": "शिल्प कौशल को उजागर करने वाला 3-वाक्य का विवरण।",
        "keywords": ["टैग1", "टैग2", "टैग3", "टैग4"]
    }}
}}
"""
    try:
        # Hackathon Pro-Tip: Forcing response_mime_type to application/json 
        # guarantees Gemini won't wrap the output in markdown backticks!
        response = gemini_model.generate_content(
            prompt,
            generation_config={"response_mime_type": "application/json"}
        )
        parsed_data = json.loads(response.text)
        return {"status": "success", "data": parsed_data}
        
    except Exception as error:
        print(f"Error during AI Catalog generation: {error}")
        raise HTTPException(
            status_code=500,
            detail="Failed to generate catalog from AI.",
        ) from error

# --- 3. FEATURE 2: VYAPARSETU SAATHI (VOICE ASSISTANT FAQ) ---
@app.post("/api/voice-assistant")
async def voice_assistant(payload: VoicePayload):
    transcript = payload.transcript.strip()
    if not transcript:
        raise HTTPException(status_code=400, detail="Transcript cannot be empty.")

    prompt = f"""
You are 'VyaparSetu Saathi', a helpful voice assistant for rural artisans in Punjab, India.
An artisan has asked you this question: "{transcript}"

Rules:
1. Answer in the EXACT SAME LANGUAGE they asked the question in (Punjabi, Hindi, or English).
2. Keep the answer extremely brief, simple, and polite (maximum 2-3 sentences).
3. If they ask about GST, remind them that turnover under 40 Lakhs is exempt for intra-state online sales.
4. Do NOT use markdown, bolding, or lists. Just return pure, readable text.
"""
    try:
        # We don't need JSON here, just raw text for the chat bubble
        response = gemini_model.generate_content(prompt)
        return {"status": "success", "answer": response.text.strip()}
        
    except Exception as error:
        print(f"Error during AI Voice Assistant generation: {error}")
        raise HTTPException(
            status_code=500,
            detail="Failed to generate answer from AI.",
        ) from error

# --- 4. SERVER RUNNER ---
if __name__ == "__main__":
    print("Starting VyaparSetu AI Server on port 8000...")
    uvicorn.run(app, host="0.0.0.0", port=8000)