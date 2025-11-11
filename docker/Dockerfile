# Multi-stage build para optimizar imagen
FROM python:3.11-slim as builder

WORKDIR /build
COPY app/requirements.txt .

RUN pip install --user --no-cache-dir -r requirements.txt

# Final stage
FROM python:3.11-slim

WORKDIR /app

# Copiar dependencias del builder
COPY --from=builder /root/.local /root/.local

# Copiar aplicación
COPY app/ .

# Configurar PATH
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1
ENV ENVIRONMENT=production
ENV PORT=8080

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8080/health')"

CMD ["python", "-u", "app.py"]
