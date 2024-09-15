To run locally:
1. Create a python venv:
    python3 -m venv venv
2. Activate the env:
    source venv/bin/activate
3. Install requirements:
    pip install -r requirements.txt
4. Run the application locally:
    python3 -m uvicorn app.app:app --host 0.0.0.0 --port 8080 --log-level debug --reload

Everything has to be done in the services/stock_service folder