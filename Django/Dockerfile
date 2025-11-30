FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY ./django_app/requirements.txt .

RUN pip install --upgrade pip \
    && pip install -r requirements.txt --no-cache-dir

COPY . .

EXPOSE 8000

CMD ["gunicorn", "django_app.wsgi:application", "--bind", "0.0.0.0:8000"]