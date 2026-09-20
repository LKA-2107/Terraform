FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --requirement requirements.txt

COPY worker.py .

RUN useradd --uid 10001 --no-create-home appuser \
    && chown -R appuser:appuser /app
USER 10001

CMD ["python", "worker.py"]

