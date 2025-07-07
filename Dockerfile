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

# Salin Pipfile & lock (agar layer caching lebih optimal)
COPY Pipfile Pipfile.lock ./

RUN pip install --no-cache-dir torch==2.3.0+cpu torchvision==0.18.0+cpu -f https://download.pytorch.org/whl/torch_stable.html

# Install dependencies via pipenv
RUN pipenv install --deploy --ignore-pipfile

# Salin seluruh kode aplikasi
COPY app/ .  

ENV PYTHONPATH=/app
ENV CUDA_VISIBLE_DEVICES=""
# Expose port Flask
EXPOSE 5000

# Gunakan Gunicorn untuk menjalankan server
# Ganti `app.routes:app` sesuai dengan path ke objek Flask kamu
CMD ["pipenv", "run", "gunicorn", "app:app", "--bind", "0.0.0.0:5000"]
