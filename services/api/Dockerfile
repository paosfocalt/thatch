FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim

COPY --from=builder /install /usr/local
COPY app.py /app/app.py
WORKDIR /app

RUN adduser --disabled-password --no-create-home --uid 1000 appuser
USER 1000

EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
