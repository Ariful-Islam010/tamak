from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
import json
import uvicorn
from fastapi.middleware.cors import CORSMiddleware
from openai import OpenAI
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

app = FastAPI(title="Tobacco Awareness AI Backend")

# Allow CORS for flutter web or local testing
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load GROQ API Key from environment variables
GROQ_API_KEY = os.getenv("GROQ_API_KEY")

# Initialize OpenAI client pointing to Groq
client = OpenAI(
    api_key=GROQ_API_KEY,
    base_url="https://api.groq.com/openai/v1",
)


class PlanRequest(BaseModel):
    durationInDays: int
    cigarettesPerDay: int
    age: str
    gender: str

class SosRequest(BaseModel):
    triggerReason: str

@app.post("/generate-plan")
async def generate_plan(req: PlanRequest):
    prompt = f"""
You are an AI assistant helping a user quit smoking.
User Profile: Age {req.age}, Gender {req.gender}, smokes {req.cigarettesPerDay} cigarettes per day.
Goal: Quit smoking in {req.durationInDays} days.

Please generate a day-by-day quit plan for {req.durationInDays} days in Bengali language.
For each day, provide:
1. day: The day number (e.g., 1, 2, 3)
2. title: Title of the day's focus
3. desc: Description of the strategy
4. user_task: What the user specifically needs to do today
5. ai_task: What you (the AI) have done/prepared for them to help today
6. daily_target: Today's maximum allowed cigarettes (e.g. "সর্বোচ্চ ৪টি", "সর্বোচ্চ ২টি", "০ (শূন্য)টি - চ্যালেঞ্জ কমপ্লিট!").

Strictly use the following structured themes for the days (scaled or adapted to {req.durationInDays} days, ensuring a smooth reduction from {req.cigarettesPerDay} to 0 by the final days):
- Day 1: Daily Check-in & Triggers
  Process/Description: আজ সিগারেট কমানোর দরকার নেই। তবে অ্যাপের 'Daily Check-in' সম্পন্ন করতে হবে এবং সেখানে 'Note' বা ডায়েরির জায়গায় আজ আপনাকে কোন বিষয়গুলো সিগারেট খাওয়ার জন্য ট্রিগার করেছে (যেমন: কাজের চাপ, আড্ডা) তা লিখতে হবে।
  Daily Target: {req.cigarettesPerDay}টি (সর্বোচ্চ)
- Day 2: The SOS Emergency
  Process/Description: আজ সিগারেট খাওয়ার তীব্র ইচ্ছা হলেই অ্যাপের 'SOS Emergency' বাটনে চাপ দিন। সেখানে আপনার ট্রিগার রিজনটি লিখুন এবং এআই-এর দেওয়া তাৎক্ষণিক পরামর্শটি মেনে চলুন।
- Day 3: Peer Support (Community)
  Process/Description: ধূমপান ছাড়ার এই জার্নিতে আপনি একা নন! আজ অ্যাপের 'Peer Support' বা সাপোর্ট গ্রুপে গিয়ে আপনার আজকের অভিজ্ঞতা শেয়ার করুন অথবা অন্য কারো মেসেজে উৎসাহমূলক রিপ্লাই দিন।
- Day 4: Money Saver Goal
  Process/Description: সিগারেট না খেয়ে প্রতিদিন যে টাকাটা বাঁচাচ্ছেন, তা দিয়ে কী করতে চান? আজই অ্যাপের 'Money Saver' অপশনে গিয়ে আপনার একটি স্বপ্নের গোল (যেমন: পছন্দের কোনো গ্যাজেট বা খাবার) সেট করুন।
- Day 5: Virtual Quit-Tree
  Process/Description: আপনার প্রতিদিনের চেক-ইন এর উপর ভিত্তি করে আপনার ড্যাশবোর্ডে একটি ভার্চুয়াল গাছ বড় হচ্ছে! আজ আপনার কাজ হলো তামাকমুক্ত থেকে আপনার স্ট্রিক (Streak) ধরে রাখা এবং গাছটির বৃদ্ধি নিশ্চিত করা।
- Day 6: Educational Content
  Process/Description: আজ অ্যাপের এডুকেশনাল সেকশন বা লাইব্রেরি থেকে ধূমপান ছাড়ার উপায় বা এর ক্ষতিকর দিক নিয়ে অন্তত একটি আর্টিকেল পড়ুন এবং নিজেকে মোটিভেটেড রাখুন।
- Day 7 (or final day): The Celebration!
  Process/Description: অভিনন্দন! আপনি সফলভাবে আপনার চ্যালেঞ্জের শেষ দিনে পৌঁছেছেন। আজ মানি সেভারে জমানো টাকা দিয়ে আপনার সেট করা গোলটি পূরণ করুন এবং আপনার সফলতার ব্যাজটি (Badge) সাপোর্ট গ্রুপে শেয়ার করুন!

Return ONLY a valid JSON object with a single key "plans" that contains an array of these day objects. The objects must have keys: "day", "title", "desc", "user_task", "ai_task", "daily_target". Do not include any markdown block wrapper or extra text.
"""

    try:
        response = client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[
                {
                    "role": "system",
                    "content": "You are a helpful assistant that only outputs valid JSON. You must output a JSON object containing a 'plans' array with the day-by-day tasks."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            response_format={"type": "json_object"},
            temperature=0.7
        )
        
        content = response.choices[0].message.content
        # Return the parsed content
        return json.loads(content)
        
    except Exception as e:
        print(f"Error calling Groq API via OpenAI SDK: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/get-sos-advice")
async def get_sos_advice(req: SosRequest):
    try:
        response = client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[
                {
                    "role": "system",
                    "content": "You are an empathetic, concise AI assistant helping someone overcome a sudden tobacco craving. Provide a brief, actionable coping strategy instantly in Bengali language. Do not lecture, just give immediate practical advice."
                },
                {
                    "role": "user",
                    "content": f"I am having a strong craving for tobacco right now because: {req.triggerReason}. What should I do right now?"
                }
            ],
            temperature=0.7,
            max_tokens=150
        )
        return {"advice": response.choices[0].message.content.strip()}
    except Exception as e:
        print(f"Error calling Groq SOS: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
