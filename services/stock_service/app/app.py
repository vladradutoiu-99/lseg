from fastapi import (
    FastAPI,
    Request,
    status,
)

app = FastAPI()

@app.post('/test-request',
            status_code=status.HTTP_200_OK,
            include_in_schema=False
)
def get_data(request: Request):
    
    return "OK"