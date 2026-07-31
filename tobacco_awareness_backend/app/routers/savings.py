from fastapi import APIRouter, HTTPException, Depends
from app.services.supabase import supabase_req
from app.dependencies import require_auth

router = APIRouter(prefix="/api/savings", tags=["Savings"])


@router.get("")
async def get_savings(authorization: str = Depends(require_auth)):
    """Get all savings log entries for the authenticated user."""
    res = supabase_req("GET", "/rest/v1/savings_logs?select=*", token=authorization)
    if res.status_code >= 400:
        raise HTTPException(status_code=res.status_code, detail=res.text)
    return res.json()


@router.post("")
async def add_savings(data: dict, authorization: str = Depends(require_auth)):
    """Log a new savings entry."""
    res = supabase_req("POST", "/rest/v1/savings_logs", token=authorization, json_data=data)
    if res.status_code >= 400:
        raise HTTPException(status_code=res.status_code, detail=res.text)
    return res.json()
