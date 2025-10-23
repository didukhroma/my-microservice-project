FROM python:3.13-slim

WORKDIR /app

COPY requirements.txt .

RUN pip3 install --upgrade pip && pip install -r requirements.txt --no-cache-dir --break-system-packages

ENV POSTGRES_HOST=${POSTGRES_HOST}
ENV POSTGRES_PORT=${POSTGRES_PORT}
ENV POSTGRES_NAME=${POSTGRES_NAME}
ENV POSTGRES_USER=${POSTGRES_USER}
ENV POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
