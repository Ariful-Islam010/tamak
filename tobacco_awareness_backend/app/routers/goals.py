from fastapi import APIRouter, HTTPException, Depends
from app.services.supabase import supabase_req
from app.dependencies import require_auth

router = APIRouter(prefix="/api/goals", tags=["Money Saver Goals"])


@router.get("")
async def get_goals(authorization: str = Depends(require_auth)):
    """Get all money saver goals for the authenticated user."""
    res = supabase_req("GET", "/rest/v1/money_saver_goals?select=*&order=created_at.desc", token=authorization)
    if res.status_code >= 400:
        raise HTTPException(status_code=res.status_code, detail=res.text)
    return res.json()


@router.post("")
async def add_goal(data: dict, authorization: str = Depends(require_auth)):
    """Create a new money saver goal."""
    res = supabase_req("POST", "/rest/v1/money_saver_goals", token=authorization, json_data=data)
    if res.status_code >= 400:
        raise HTTPException(status_code=res.status_code, detail=res.text)
    return res.json()
