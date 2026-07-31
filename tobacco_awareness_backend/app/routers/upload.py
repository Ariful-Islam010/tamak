import requests
from fastapi import APIRouter, HTTPException, Depends, File, UploadFile
from app.dependencies import require_auth
from app.config import settings

router = APIRouter(prefix="/api/upload", tags=["File Upload"])


@router.post("")
async def upload_file(file: UploadFile = File(...), authorization: str = Depends(require_auth)):
    """Upload an image to Cloudinary and return the secure URL."""
    file_bytes = await file.read()
    cloudinary_url = f"https://api.cloudinary.com/v1_1/{settings.CLOUDINARY_CLOUD_NAME}/image/upload"
    files = {"file": (file.filename, file_bytes, file.content_type)}
    data = {"upload_preset": settings.CLOUDINARY_UPLOAD_PRESET}

    try:
        r = requests.post(cloudinary_url, files=files, data=data)
        if r.status_code >= 400:
            raise HTTPException(status_code=r.status_code, detail=f"Cloudinary error: {r.text}")
        res = r.json()
        return {"secure_url": res.get("secure_url")}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
