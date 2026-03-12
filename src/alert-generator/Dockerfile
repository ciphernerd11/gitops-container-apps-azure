FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir requests

COPY main.py .

RUN adduser --disabled-password --no-create-home appuser
USER appuser

CMD ["python", "main.py"]
