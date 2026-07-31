from fastapi import Header, HTTPException
from typing import Optional


def require_auth(authorization: Optional[str] = Header(None)) -> str:
    """Dependency that ensures a valid Authorization header is present."""
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing Authorization Header")
    return authorization
