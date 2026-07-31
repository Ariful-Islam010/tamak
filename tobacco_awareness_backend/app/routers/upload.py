import requests
from fastapi import APIRouter, HTTPException, Depends, File, UploadFile
from app.dependencies import require_auth
from app.config import settings

router = APIRouter(prefix="/api/upload", tags=["File Upload"])


@router.post("")
async def upload_file(file: UploadFile = File(...), authorization: str = Depends(require_auth)):
    """Upload an image to Cloudinary and return the secure URL."""
    # Validate content type is an image
    if file.content_type and not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Only image files are allowed.")

    file_bytes = await file.read()
    
    # Validate max file size (10 MB limit)
    MAX_FILE_SIZE = 10 * 1024 * 1024
    if len(file_bytes) > MAX_FILE_SIZE:
        raise HTTPException(status_code=400, detail="File size exceeds maximum allowed limit of 10MB.")

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
