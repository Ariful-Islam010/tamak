import requests
from fastapi import APIRouter, HTTPException, Depends
from app.services.supabase import supabase_req
from app.dependencies import require_auth
from app.config import settings

router = APIRouter(prefix="/api/profile", tags=["Profile"])


@router.get("")
async def get_profile(authorization: str = Depends(require_auth)):
    """Get the authenticated user's profile."""
    res = supabase_req("GET", "/rest/v1/user_profiles?select=*", token=authorization)
    if res.status_code >= 400:
        raise HTTPException(status_code=res.status_code, detail=res.text)
    data = res.json()
    if isinstance(data, list) and len(data) > 0:
        return data[0]
    return data


@router.post("")
async def update_profile(profile_data: dict, authorization: str = Depends(require_auth)):
    """Upsert (create or update) the authenticated user's profile."""
    url = f"{settings.SUPABASE_URL}/rest/v1/user_profiles"
    headers = {
        "apikey": settings.SUPABASE_ANON_KEY,
        "Authorization": authorization,
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=representation",
    }
    try:
        res = requests.post(url, headers=headers, json=profile_data)
        if res.status_code >= 400:
            raise HTTPException(status_code=res.status_code, detail=res.text)
        data = res.json()
        if isinstance(data, list) and len(data) > 0:
            return data[0]
        return data
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
