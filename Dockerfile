# ---- Install dependencies for building psycopg2 ----
FROM python:3.11-slim AS build

WORKDIR /app

RUN apt-get update && \
    apt-get install -y build-essential libpq-dev gcc && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip wheel --no-cache-dir -r requirements.txt -w /wheels


# ---- Runtime image ----
FROM python:3.11-slim

WORKDIR /app

# Install Postgres client libs needed at runtime
RUN apt-get update && \
    apt-get install -y libpq5 && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /wheels /wheels
RUN pip install --no-cache /wheels/*

COPY . .

EXPOSE 8000

CMD ["gunicorn", "idlTp3.wsgi:application", "--bind", "0.0.0.0:8000"]
