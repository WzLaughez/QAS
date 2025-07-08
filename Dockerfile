# Gunakan image Python + CUDA untuk GPU (CUDA 12.1 sesuai torch cu121)
FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

# Install sistem dependencies dan Python 3.10
RUN apt-get update && apt-get install -y \
    python3.10 python3.10-venv python3.10-dev python3-pip \
    build-essential curl git \
    && rm -rf /var/lib/apt/lists/*

# Gunakan Python 3.10 sebagai default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# Install pipenv
RUN pip install --no-cache-dir pipenv

# Set working directory
WORKDIR /app

# Salin Pipfile dan Pipfile.lock
COPY Pipfile Pipfile.lock ./

# Install PyTorch GPU versi cu121 (tidak pakai pipenv untuk torch, biar pasti jalan)
RUN pip install --no-cache-dir torch==2.3.0 torchvision==0.18.0 --index-url https://download.pytorch.org/whl/cu121

# Install dependencies via pipenv (selain torch)
RUN pipenv install --deploy --ignore-pipfile

# Salin kode ke container
COPY app/ .

# Expose port Flask
EXPOSE 5000

# Jalankan server Flask pakai gunicorn
CMD ["pipenv", "run", "gunicorn", "app:app", "--bind", "0.0.0.0:5000"]
