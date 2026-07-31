import requests
from fastapi import APIRouter, HTTPException, Depends
from app.services.supabase import supabase_req
from app.dependencies import require_auth
from app.config import settings

router = APIRouter(prefix="/api/gamification", tags=["Gamification"])


@router.get("")
async def get_gamification(authorization: str = Depends(require_auth)):
    """Get gamification progress for the authenticated user."""
    res = supabase_req("GET", "/rest/v1/gamification_progress?select=*", token=authorization)
    if res.status_code >= 400:
        raise HTTPException(status_code=res.status_code, detail=res.text)
    data = res.json()
    if isinstance(data, list) and len(data) > 0:
        return data[0]
    return None


@router.post("")
async def save_gamification(data: dict, authorization: str = Depends(require_auth)):
    """Upsert gamification progress for the authenticated user."""
    url = f"{settings.SUPABASE_URL}/rest/v1/gamification_progress"
    headers = {
        "apikey": settings.SUPABASE_ANON_KEY,
        "Authorization": authorization,
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=representation",
    }
    try:
        res = requests.post(url, headers=headers, json=data)
        if res.status_code >= 400:
            raise HTTPException(status_code=res.status_code, detail=res.text)
        return res.json()
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/stats")
async def get_gamification_stats(authorization: str = Depends(require_auth)):
    """Aggregate stats: check-ins, savings, SOS count, message count, profile info."""
    checkins_res = supabase_req(
        "GET",
        "/rest/v1/daily_checkins?select=check_in_date,used_tobacco&order=check_in_date.asc",
        token=authorization,
    )
    checkins = checkins_res.json() if checkins_res.status_code == 200 else []

    savings_res = supabase_req("GET", "/rest/v1/savings_logs?select=amount", token=authorization)
    savings = savings_res.json() if savings_res.status_code == 200 else []
    total_savings = sum([int(row.get("amount", 0)) for row in savings])

    profile_res = supabase_req(
        "GET", "/rest/v1/user_profiles?select=plan_duration,quit_date", token=authorization
    )
    profile_data = profile_res.json() if profile_res.status_code == 200 else []
    profile = profile_data[0] if isinstance(profile_data, list) and len(profile_data) > 0 else {}

    sos_res = supabase_req("GET", "/rest/v1/sos_logs?select=id", token=authorization)
    sos_count = len(sos_res.json()) if sos_res.status_code == 200 else 0

    user_res = supabase_req("GET", "/auth/v1/user", token=authorization)
    user_id = None
    if user_res.status_code == 200:
        user_id = user_res.json().get("id")

    messages_count = 0
    if user_id:
        messages_res = supabase_req(
            "GET",
            f"/rest/v1/peer_support_messages?select=id&sender_id=eq.{user_id}",
            token=authorization,
        )
        messages_count = len(messages_res.json()) if messages_res.status_code == 200 else 0

    return {
        "checkins": checkins,
        "total_savings": total_savings,
        "plan_duration": profile.get("plan_duration", 7),
        "quit_date": profile.get("quit_date"),
        "sos_count": sos_count,
        "messages_count": messages_count,
    }
