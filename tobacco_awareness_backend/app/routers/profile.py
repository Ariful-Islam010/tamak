from fastapi import APIRouter, HTTPException, Depends
from app.services.supabase import supabase_req
from app.dependencies import require_auth

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
    res = supabase_req(
        "POST",
        "/rest/v1/user_profiles",
        token=authorization,
        json_data=profile_data,
        prefer="resolution=merge-duplicates,return=representation",
    )
    if res.status_code >= 400:
        raise HTTPException(status_code=res.status_code, detail=res.text)
    data = res.json()
    if isinstance(data, list) and len(data) > 0:
        return data[0]
    return data
