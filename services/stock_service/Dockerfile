FROM tiangolo/uvicorn-gunicorn:python3.11-slim


WORKDIR /app

RUN apt-get update && apt-get install -y wget
COPY requirements.txt .
COPY stock_price_data_files .
RUN pip install --upgrade pip
RUN apt-get update
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD uvicorn app.app:app --host 0.0.0.0 --port 8080 --log-level debug
EXPOSE 8080