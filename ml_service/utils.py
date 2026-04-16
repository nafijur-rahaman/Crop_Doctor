import numpy as np
from PIL import Image
import io
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input


def load_and_preprocess(file_bytes: bytes) -> np.ndarray:
    """
    Preprocess raw image bytes for MobileNetV2.
    Scales pixel values to [-1, 1] — must match training preprocessing exactly.
    Returns ndarray of shape (1, 224, 224, 3).
    """
    img = Image.open(io.BytesIO(file_bytes)).convert("RGB")
    img = img.resize((224, 224))
    arr = np.array(img, dtype=np.float32)
    arr = preprocess_input(arr)          # [0,255] → [-1,1]
    return np.expand_dims(arr, axis=0)   # (1, 224, 224, 3)
