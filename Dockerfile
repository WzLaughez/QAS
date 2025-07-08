# Gunakan image Python yang ringan
FROM python:3.10-slim

# Install sistem dependencies yang dibutuhkan
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install pipenv
RUN pip install pipenv

# Set working directory
WORKDIR /app

# Salin Pipfile dan Pipfile.lock
COPY Pipfile Pipfile.lock ./

# Install torch + torchvision versi CPU secara manual
RUN pip install --no-cache-dir torch==2.3.0+cpu torchvision==0.18.0+cpu -f https://download.pytorch.org/whl/torch_stable.html

# Install dependencies via pipenv (selain torch)
RUN pipenv install --deploy --ignore-pipfile

# Salin semua kode
COPY app/ .

# Setup ENV agar Flask bisa jalan normal
ENV PYTHONPATH=/app
ENV CUDA_VISIBLE_DEVICES=""
ENV PYTORCH_FORCE_CPU=1
ENV PYTORCH_ENABLE_MPS_FALLBACK=1

# Expose port
EXPOSE 5000

# Jalankan server
CMD ["pipenv", "run", "gunicorn", "app:app", "--bind", "0.0.0.0:5000"]
