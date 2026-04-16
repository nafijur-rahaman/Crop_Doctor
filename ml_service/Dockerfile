FROM python:3.12-slim

WORKDIR /home/user/app

# System libs needed by TensorFlow / Pillow
RUN apt-get update && apt-get install -y \    libglib2.0-0 libsm6 libxrender1 libxext6 \    && rm -rf /var/lib/apt/lists/*

# Install Python deps as root so they land in /usr/local/bin
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Non-root user required by HuggingFace Spaces
RUN useradd -m -u 1000 user
USER user

COPY --chown=user . /home/user/app

EXPOSE 7860

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]
