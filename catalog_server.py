import json
import os

import google.generativeai as genai
import uvicorn
from fastapi import FastAPI, HTTPException, Response
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


class VoiceAssistantRequest(BaseModel):
    question: str | None = None
    transcript: str | None = None


@app.options("/api/voice-assistant")
def voice_assistant_options() -> Response:
    return Response(status_code=200)


@app.post("/api/voice-assistant")
async def voice_assistant(payload: VoiceAssistantRequest):
    user_prompt = (payload.question or payload.transcript or "").strip()
    if not user_prompt:
        raise HTTPException(status_code=400, detail="Question cannot be empty.")
    if len(user_prompt) > 1000:
        raise HTTPException(
            status_code=400,
            detail="Question exceeds maximum allowed length of 1000 characters.",
        )

    system_prompt = f"""
You are 'VyaparSetu Saathi', a friendly grassroots business assistant for local artisan producers on VyaparSetu in India.
The user asked: "{user_prompt}"

Rules:
1. Language: Answer in the same language the user used (English, Hindi, or Punjabi).
2. Brevity: Keep the response concise, clear, and polite (2 to 4 sentences).
3. VyaparSetu guidance:
   - To add a product: Use the 'Add Product' button, take a photo, enter details, or tap the microphone to speak your product description.
   - To improve photos: Use 'Improve Photo' on your product card for instant background enhancement.
   - To set a price: Tap 'Set a Good Price' near the price field for market-based guidance.
   - Verification: Email, PAN, and GST verification help build trust on VyaparSetu.
4. Truthfulness & Non-Government Policy:
   - Do NOT make legal, tax, or official government verification guarantees.
   - Clarify that prototype verification on VyaparSetu records business details for platform trust, not government legal clearance.
   - For GST: Artisans with annual turnover under ₹40 Lakhs selling intra-state are generally exempt under Indian e-commerce norms.
5. Formatting: Return clean, readable plain text without markdown symbols, tables, or asterisks.
"""

    try:
        response = catalog_model.generate_content(system_prompt)
        answer = response.text.strip()
        return {"status": "success", "answer": answer}
    except Exception as error:
        print(f"Error during Voice Assistant AI generation: {error}")
        raise HTTPException(
            status_code=500,
            detail="Failed to generate response from Voice Assistant.",
        ) from error


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
