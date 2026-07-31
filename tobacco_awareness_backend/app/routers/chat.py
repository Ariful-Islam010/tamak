from fastapi import APIRouter, HTTPException, Depends
from app.services.supabase import supabase_req
from app.dependencies import require_auth

router = APIRouter(prefix="/api/chat", tags=["Peer Support Chat"])


@router.get("/messages")
async def get_chat_messages(authorization: str = Depends(require_auth)):
    """Fetch all peer support messages with sender profile info."""
    res = supabase_req(
        "GET",
        "/rest/v1/peer_support_messages?select=id,sender_id,content,image_url,created_at,sender:user_profiles(display_name,photo_url)&order=created_at.asc",
        token=authorization,
    )
    if res.status_code >= 400:
        raise HTTPException(status_code=res.status_code, detail=res.text)
    return res.json()


@router.post("/messages")
async def send_chat_message(message_data: dict, authorization: str = Depends(require_auth)):
    """Post a new message to the peer support chat."""
    res = supabase_req("POST", "/rest/v1/peer_support_messages", token=authorization, json_data=message_data)
    if res.status_code >= 400:
        raise HTTPException(status_code=res.status_code, detail=res.text)
    return res.json()


@router.delete("/messages/{message_id}")
async def delete_chat_message(message_id: str, authorization: str = Depends(require_auth)):
    """Delete a specific message by ID."""
    res = supabase_req("DELETE", f"/rest/v1/peer_support_messages?id=eq.{message_id}", token=authorization)
    if res.status_code >= 400:
        raise HTTPException(status_code=res.status_code, detail=res.text)
    return {"status": "success"}


@router.put("/messages/{message_id}")
async def edit_chat_message(message_id: str, message_data: dict, authorization: str = Depends(require_auth)):
    """Edit a specific message by ID."""
    res = supabase_req(
        "PATCH",
        f"/rest/v1/peer_support_messages?id=eq.{message_id}",
        token=authorization,
        json_data=message_data,
    )
    if res.status_code >= 400:
        raise HTTPException(status_code=res.status_code, detail=res.text)
    return res.json()
