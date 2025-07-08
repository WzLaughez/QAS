# Base image: CUDA + CUDNN + Python
FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

# Install Python dan tools dasar
RUN apt-get update && apt-get install -y \
    python3.10 python3.10-venv python3.10-dev python3-pip \
    build-essential curl git \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.10 sebagai default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# Install pipenv
RUN pip install --no-cache-dir pipenv

# ---------------- Tahapan cacheable mulai dari sini ---------------- #

# Buat folder kerja
WORKDIR /app

# Hanya copy Pipfile & lock dulu
COPY Pipfile Pipfile.lock ./

# Install torch GPU dan sentence-transformers sekali saja (tidak masuk pipenv agar stabil)
RUN pip install --no-cache-dir torch==2.3.0 torchvision==0.18.0 --index-url https://download.pytorch.org/whl/cu121
RUN pip install --no-cache-dir sentence-transformers


# Install dependencies lain dari Pipfile (pipenv)
RUN pipenv install --deploy --ignore-pipfile

# Baru copy source code (ini agar perubahan file app tidak bikin re-install dependencies)
COPY app/ .

# Expose port
EXPOSE 5000

# Jalankan server
CMD ["pipenv", "run", "gunicorn", "app:app", "--bind", "0.0.0.0:5000"]
