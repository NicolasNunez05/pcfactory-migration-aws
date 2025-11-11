# Multi-stage build para optimizar imagen
FROM python:3.11-slim as builder

WORKDIR /build
COPY app/requirements.txt .

# Instalar dependencias en etapa de construcción
RUN pip install --user --no-cache-dir -r requirements.txt && \
    pip install --user --no-cache-dir pytest pytest-cov flake8 black

# Etapa intermedia: Tests
FROM builder as tester

WORKDIR /app
COPY app/ .
COPY tests/ /tests/

# Ejecutar linting
RUN flake8 --max-line-length=100 --exclude=venv,env .

# Ejecutar tests (opcional en build, puede deshabilitarse)
# RUN pytest /tests/ --cov=app --cov-report=xml

# Etapa final: Producción
FROM python:3.11-slim

WORKDIR /app

# Etiquetas de metadata
LABEL maintainer="PCFactory DevOps Team"
LABEL version="3.0"
LABEL description="PCFactory Application - Production Container"

# Copiar dependencias del builder
COPY --from=builder /root/.local /root/.local

# Copiar aplicación desde la etapa de tests (asegura que pasó validación)
COPY --from=tester /app .

# Crear usuario no-root
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

USER appuser

# Configurar PATH y variables de entorno
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV ENVIRONMENT=production
ENV PORT=8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8080/health')" || exit 1

EXPOSE 8080

# Ejecutar aplicación
CMD ["python", "-u", "app.py"]