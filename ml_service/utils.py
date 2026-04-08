import json
from pathlib import Path
import numpy as np
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image

BASE_DIR = Path(__file__).resolve().parent
MODEL_DIR = BASE_DIR / "ml_model"
MODEL_PATH = MODEL_DIR / "plant_disease_model.h5"
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

def predict_image(file_path):
    """
    Predict the disease from a leaf image.
    Returns:
        disease_name (str), confidence (float)
    """
    # Load & preprocess image
    img = image.load_img(file_path, target_size=(INPUT_HEIGHT, INPUT_WIDTH))
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)
    img_array /= 255.0

    pred = model.predict(img_array, verbose=0)
    pred_index = int(np.argmax(pred))
    confidence = float(np.max(pred))
    disease_name = class_names.get(pred_index)

    if disease_name is None:
        raise ValueError(f"Predicted class index {pred_index} not found in {CLASS_PATH.name}")

    return disease_name, confidence
