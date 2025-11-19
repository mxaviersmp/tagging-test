# Use an official Python runtime as a small base image
FROM python:3.11-slim

# Avoid Python buffering so logs appear immediately in container logs
ENV PYTHONUNBUFFERED=1
ENV POETRY_VIRTUALENVS_CREATE=false

# Create app directory and non-root user
WORKDIR /app
RUN useradd --create-home --shell /bin/bash appuser \
    && chown -R appuser:appuser /app

# Copy only requirements first to leverage Docker cache (if you have them)
COPY requirements.txt /app/requirements.txt

# Install dependencies if requirements.txt exists
RUN set -eux; \
    if [ -s /app/requirements.txt ]; then \
      apt-get update && apt-get install -y --no-install-recommends gcc libpq-dev && \
      pip install --no-cache-dir -r /app/requirements.txt && \
      apt-get purge -y --auto-remove gcc libpq-dev && rm -rf /var/lib/apt/lists/*; \
    else \
      echo "No requirements.txt or it's empty — skipping pip install"; \
    fi

# Copy app code
COPY . /app
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Default command: run your script (change main.py if your filename differs)
CMD ["python", "source/main.py"]
