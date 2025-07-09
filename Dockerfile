# Gunakan base image NVIDIA yang mendukung CUDA + Python
FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3.10-dev \
    python3-pip \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set Python alias
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# Upgrade pip
RUN python -m pip install --upgrade pip

# Set workdir
WORKDIR /app

# Salin requirements
COPY requirements.txt .

# Install PyTorch GPU (CUDA 12.1)
RUN pip install --no-cache-dir torch==2.2.2+cu121 torchvision==0.17.2+cu121 --index-url https://download.pytorch.org/whl/cu121


# Install sentence transformers
RUN pip install --no-cache-dir sentence-transformers==4.1.0 transformers==4.53.0 huggingface-hub==0.33.2
# Install huggingface + sentence-transformers dengan versi kompatibel
# RUN pip install --no-cache-dir \
#     sentence-transformers==2.7.0 \
#     transformers==4.40.2 \
#     huggingface-hub==0.23.0
# Install dependensi lainnya
RUN pip install --no-cache-dir -r requirements.txt

# Salin semua source code
COPY app/ .

# Set PYTHONPATH
ENV PYTHONPATH=/app

# Expose port
EXPOSE 5000

# Jalankan server dengan gunicorn
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:5000", "--timeout", "1200", "--workers", "2"]
