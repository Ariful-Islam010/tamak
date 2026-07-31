from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from app.services.supabase import supabase_req

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


class EmailPasswordAuth(BaseModel):
    email: str
    password: str


class GoogleAuthRequest(BaseModel):
    idToken: str
    accessToken: Optional[str] = None


@router.post("/signup")
async def auth_signup(req: EmailPasswordAuth):
    """Register a new user with email and password via Supabase."""
    res = supabase_req("POST", "/auth/v1/signup", json_data={"email": req.email, "password": req.password})
    if res.status_code >= 400:
        raise HTTPException(status_code=res.status_code, detail=res.json())
    return res.json()


@router.post("/signin")
async def auth_signin(req: EmailPasswordAuth):
    """Sign in an existing user with email and password."""
    res = supabase_req("POST", "/auth/v1/token?grant_type=password", json_data={"email": req.email, "password": req.password})
    if res.status_code >= 400:
        raise HTTPException(status_code=res.status_code, detail=res.json())
    return res.json()


@router.post("/signin-google")
async def auth_signin_google(req: GoogleAuthRequest):
    """Sign in with Google ID token via Supabase."""
    body = {"provider": "google", "id_token": req.idToken}
    if req.accessToken:
        body["access_token"] = req.accessToken
    res = supabase_req("POST", "/auth/v1/token?grant_type=id_token", json_data=body)
    if res.status_code >= 400:
        raise HTTPException(status_code=res.status_code, detail=res.json())
    return res.json()
