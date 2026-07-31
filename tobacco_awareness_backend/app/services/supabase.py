import requests
from fastapi import HTTPException
from app.config import settings


def supabase_req(method: str, path: str, token: str = None, json_data=None, params=None, use_service_role: bool = False):
    """Central Supabase HTTP helper used by all routers."""
    url = f"{settings.SUPABASE_URL}{path}"
    
    key = settings.SUPABASE_SERVICE_ROLE_KEY if (use_service_role and settings.SUPABASE_SERVICE_ROLE_KEY) else settings.SUPABASE_ANON_KEY

    headers = {
        "apikey": key,
        "Content-Type": "application/json",
    }
    if use_service_role and settings.SUPABASE_SERVICE_ROLE_KEY:
        headers["Authorization"] = f"Bearer {settings.SUPABASE_SERVICE_ROLE_KEY}"
    elif token:
        headers["Authorization"] = token if token.startswith("Bearer ") else f"Bearer {token}"
    else:
        headers["Authorization"] = f"Bearer {key}"

    if method in ["POST", "PATCH", "PUT", "DELETE"]:
        headers["Prefer"] = "return=representation"

    try:
        response = requests.request(method, url, headers=headers, json=json_data, params=params)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Supabase request failed: {str(e)}")
