import json
import io
from pathlib import Path
import numpy as np
from PIL import Image
from tensorflow.keras.models import load_model

BASE_DIR = Path(__file__).resolve().parent
MODEL_DIR = BASE_DIR / "ml_model"
MODEL_PATH = MODEL_DIR / "plant_disease_model.keras"
CLASS_PATH = MODEL_DIR / "class_names.json"


def load_class_names(class_path):
    with class_path.open(encoding="utf-8") as f:
        raw_data = json.load(f)

    sample_key = next(iter(raw_data), None)
    if sample_key is None:
        raise ValueError(f"Label file is empty: {class_path}")

    if str(sample_key).isdigit():
        return {int(k): v for k, v in raw_data.items()}

    return {int(v): k for k, v in raw_data.items()}



model = load_model(MODEL_PATH)
class_names = load_class_names(CLASS_PATH)

INPUT_HEIGHT = int(model.input_shape[1])
INPUT_WIDTH = int(model.input_shape[2])

def predict_image_from_bytes(file_bytes):
    """
    Predict the disease directly from raw image bytes in memory.
    Returns:
        disease_name (str), confidence (float)
    """
    # Open image directly from memory, ensure it is RGB
    img = Image.open(io.BytesIO(file_bytes)).convert("RGB")
    
    # Resize to match your model's expected input
    img = img.resize((INPUT_WIDTH, INPUT_HEIGHT))
    
    # Convert to array and preprocess
    img_array = np.array(img)
    img_array = np.expand_dims(img_array, axis=0)
    img_array = img_array / 255.0

    # Predict
    pred = model.predict(img_array, verbose=0)
    pred_index = int(np.argmax(pred))
    confidence = float(np.max(pred))
    disease_name = class_names.get(pred_index)

    if disease_name is None:
        raise ValueError(f"Predicted class index {pred_index} not found in {CLASS_PATH.name}")

    return disease_name, confidence