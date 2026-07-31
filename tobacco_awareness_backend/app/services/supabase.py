import requests
from fastapi import HTTPException
from app.config import settings


def supabase_req(method: str, path: str, token: str = None, json_data=None, params=None):
    """Central Supabase HTTP helper used by all routers."""
    url = f"{settings.SUPABASE_URL}{path}"
    headers = {
        "apikey": settings.SUPABASE_ANON_KEY,
        "Content-Type": "application/json",
    }
    if token:
        headers["Authorization"] = token if token.startswith("Bearer ") else f"Bearer {token}"
    else:
        headers["Authorization"] = f"Bearer {settings.SUPABASE_ANON_KEY}"

    if method in ["POST", "PATCH", "PUT", "DELETE"]:
        headers["Prefer"] = "return=representation"

    try:
        response = requests.request(method, url, headers=headers, json=json_data, params=params)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Supabase request failed: {str(e)}")
