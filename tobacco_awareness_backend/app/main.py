from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import auth, profile, checkins, savings, goals, gamification, chat, upload, ai

app = FastAPI(
    title="Tobacco Awareness AI Backend",
    description="Production-ready API for the তামাকমুক্ত জীবন Flutter app.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ---------- CORS ----------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],          # Restrict to your domain in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------- ROUTERS ----------
app.include_router(auth.router)
app.include_router(profile.router)
app.include_router(checkins.router)
app.include_router(savings.router)
app.include_router(goals.router)
app.include_router(gamification.router)
app.include_router(chat.router)
app.include_router(upload.router)
app.include_router(ai.router)


@app.get("/", tags=["Health"])
async def root():
    """Health check endpoint."""
    return {"status": "ok", "message": "Tobacco Awareness Backend is running 🚀"}
