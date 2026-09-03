FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    ffmpeg \
    libpq-dev \
    libmagic1 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy everything
COPY backend/ .

# Catch inconsistent Python modules and URL imports while building the exact
# filesystem that Gunicorn will run. This check does not access the database.
RUN DJANGO_SECRET_KEY=docker-build-check-only DEBUG=False python manage.py check

# Create necessary directories
RUN mkdir -p logs staticfiles media

# Debug: list files
RUN ls -la /app/

EXPOSE 8000

CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]
