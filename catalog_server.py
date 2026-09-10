import json
import os

import google.generativeai as genai
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv


load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise RuntimeError(
        "GEMINI_API_KEY is required. Add GEMINI_API_KEY=your-key to .env "
        "or set it in the terminal before starting the server."
    )

genai.configure(api_key=api_key)
catalog_model = genai.GenerativeModel("gemini-3.5-flash")

app = FastAPI(title="VyaparSetu Auto-Cataloger API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok", "service": "catalog"}


class VoicePayload(BaseModel):
    transcript: str


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
        response = catalog_model.generate_content(prompt)
        clean_json = response.text.replace("```json", "").replace("```", "").strip()
        parsed_data = json.loads(clean_json)
        return {"status": "success", "data": parsed_data}
    except Exception as error:
        print(f"Error during AI generation: {error}")
        raise HTTPException(
            status_code=500,
            detail="Failed to generate catalog from AI.",
        ) from error


if __name__ == "__main__":
    print("Starting VyaparSetu Auto-Cataloger AI Server...")
    uvicorn.run(app, host="0.0.0.0", port=8000)
