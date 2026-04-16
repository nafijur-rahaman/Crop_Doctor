import json
import numpy as np
import tensorflow as tf
import keras
from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from utils import load_and_preprocess

print(f"TF: {tf.__version__}  Keras: {keras.__version__}")

app = FastAPI(title="Plant Disease Detection API v3")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Load model + metadata on startup ──
model = tf.keras.models.load_model("model/plant_disease_model.keras")
print("✅ Model loaded")

with open("model/class_names.json") as f:
    class_names = json.load(f)

with open("model/model_meta.json") as f:
    meta = json.load(f)

CONFIDENCE_THRESHOLD = meta["confidence_threshold"]
ENTROPY_THRESHOLD    = meta["entropy_threshold"]
NUM_CLASSES          = meta["num_classes"]


def predict_with_tta(arr: np.ndarray, tta_steps: int = 8):
    """Average predictions over TTA passes (horizontal flip augmentation)."""
    preds = [model.predict(arr, verbose=0)[0]]
    for _ in range(tta_steps - 1):
        aug = arr[:, :, ::-1, :]   # horizontal flip
        preds.append(model.predict(aug, verbose=0)[0])
    return np.mean(preds, axis=0)


@app.get("/")
def root():
    return {
        "status"    : "running 🚀",
        "tf_version": tf.__version__,
        "keras"     : keras.__version__,
        "classes"   : NUM_CLASSES,
        "tta_steps" : meta["tta_steps"],
        "message"   : "Go to /docs to test the API",
    }


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    contents = await file.read()
    arr      = load_and_preprocess(contents)         # (1, 224, 224, 3)
    preds    = predict_with_tta(arr, tta_steps=8)

    max_conf     = float(np.max(preds))
    eps          = 1e-10
    entropy      = float(-np.sum(preds * np.log(preds + eps)))
    norm_entropy = entropy / np.log(NUM_CLASSES)
    is_plant     = (max_conf >= CONFIDENCE_THRESHOLD) and (norm_entropy <= ENTROPY_THRESHOLD)

    if not is_plant:
        return {
            "status"    : "not_a_plant",
            "disease"   : None,
            "confidence": round(max_conf * 100, 2),
            "entropy"   : round(norm_entropy, 4),
            "message"   : "Not a plant leaf. Please upload a clear photo of a plant leaf.",
            "top_5"     : [],
        }

    top_indices = np.argsort(preds)[::-1][:5]
    return {
        "status"    : "plant",
        "disease"   : class_names[str(top_indices[0])],
        "confidence": round(max_conf * 100, 2),
        "entropy"   : round(norm_entropy, 4),
        "message"   : f"{class_names[str(top_indices[0])]} ({max_conf*100:.1f}% confidence)",
        "top_5"     : [
            {"disease": class_names[str(i)], "confidence": round(float(preds[i]) * 100, 2)}
            for i in top_indices
        ],
    }
