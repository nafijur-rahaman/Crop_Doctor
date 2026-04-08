import logging
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware

try:
    from .utils import predict_image_from_bytes
except ImportError:
    from utils import predict_image_from_bytes

app = FastAPI(title="Leaf Disease Prediction API")
logger = logging.getLogger(__name__)

# Enable CORS for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to your specific frontend domains in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    """Health check endpoint to verify the API is running."""
    return {
        "status": "active",
        "message": "Leaf Disease Prediction API is running. Navigate to /docs to test the endpoints."
    }

@app.post("/predict/")
async def predict(file: UploadFile = File(...)):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Uploaded file must be an image.")

    try:
        # Read the file directly into memory (No temp file created on disk!)
        file_bytes = await file.read()
        
        # Pass the bytes directly to the utility function
        disease, confidence = predict_image_from_bytes(file_bytes)
        
    except Exception as exc:
        logger.exception("Prediction failed for uploaded file %s", file.filename)
        raise HTTPException(status_code=500, detail="Error processing the image for prediction.")
        
    return {
        "disease": disease,
        "confidence": round(confidence, 4)
    }