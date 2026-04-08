from pathlib import Path
import logging
import shutil
import uuid

from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware

try:
    from .utils import predict_image
except ImportError:
    from utils import predict_image

app = FastAPI(title="Leaf Disease Prediction API")
logger = logging.getLogger(__name__)

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # change to your frontend domain in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

BASE_DIR = Path(__file__).resolve().parent
UPLOAD_FOLDER = BASE_DIR / "temp"
UPLOAD_FOLDER.mkdir(exist_ok=True)

@app.post("/predict/")
async def predict(file: UploadFile = File(...)):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Uploaded file must be an image.")

    file_suffix = Path(file.filename or "upload.jpg").suffix or ".jpg"
    file_path = UPLOAD_FOLDER / f"{uuid.uuid4()}{file_suffix}"

    try:
        with file_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        disease, confidence = predict_image(file_path)
    except Exception as exc:
        logger.exception("Prediction failed for uploaded file %s", file.filename)
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    finally:
        if file_path.exists():
            file_path.unlink()

    return {
        "disease": disease,
        "confidence": round(confidence, 4)
    }
