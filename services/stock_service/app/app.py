from fastapi import (
    FastAPI,
    Request,
    status,
    HTTPException,
)

from app.restschema import SimpleRequest, SimpleResponse, PredictionRequest
from app.utils import process_files_from_folder, predict_stock

STOCK_FOLDER = 'stock_price_data_files'
# FastAPI is used as the framework to create the REST API
app = FastAPI()

@app.post('/api-consecutive-datapoints',
            status_code=status.HTTP_200_OK,
            include_in_schema=False
)
def get_data(request: Request, content: SimpleRequest) -> SimpleResponse:

    if content.processed_files <= 0:
        raise HTTPException(status_code=400, detail="Number of processed files must be greater than 0")
    
    if content.max_concurrent_threads <= 0:
        raise HTTPException(status_code=400, detail="Number of threads must be greater than 0")

    try:
        processed_files = process_files_from_folder(STOCK_FOLDER, content.processed_files)

        return processed_files
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error processing request: {e}")
    
@app.post('/api-predict-stock-price',
            status_code=status.HTTP_200_OK,
            include_in_schema=False
)
def predict_stock_price(request: Request, content: PredictionRequest):

    if content.max_concurrent_threads <= 0:
        raise HTTPException(status_code=400, detail="Number of threads must be greater than 0")

    try:
        zip = predict_stock(content)

        return zip
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error processing request: {e}")