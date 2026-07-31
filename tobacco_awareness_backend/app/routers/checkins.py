from datetime import datetime
from fastapi import APIRouter, HTTPException, Depends
from app.services.supabase import supabase_req
from app.dependencies import require_auth

router = APIRouter(prefix="/api/checkins", tags=["Check-ins"])


@router.get("/today")
async def get_checkin_today(authorization: str = Depends(require_auth)):
    """Fetch today's check-in record for the authenticated user."""
    today = datetime.now().strftime("%Y-%m-%d")
    res = supabase_req("GET", f"/rest/v1/daily_checkins?select=*&check_in_date=eq.{today}", token=authorization)
    if res.status_code >= 400:
        raise HTTPException(status_code=res.status_code, detail=res.text)
    data = res.json()
    if isinstance(data, list) and len(data) > 0:
        return data[0]
    return None


@router.post("")
async def add_checkin(checkin_data: dict, authorization: str = Depends(require_auth)):
    """Submit a daily check-in."""
    res = supabase_req("POST", "/rest/v1/daily_checkins", token=authorization, json_data=checkin_data)
    if res.status_code >= 400:
        raise HTTPException(status_code=res.status_code, detail=res.text)
    return res.json()
