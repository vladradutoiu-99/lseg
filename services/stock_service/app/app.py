from fastapi import (
    FastAPI,
    Response,
    status,
    HTTPException,
)

from app.restschema import ConsecutiveDatapointsRequest, ConsecutiveDatapointsResponse, PredictionRequest
from app.utils.functions import process_files_from_folder, predict_stock

from app.utils.config import STOCK_FOLDER
# FastAPI is used as the framework to create the REST API
app = FastAPI()

@app.post('/consecutive-datapoints',
            status_code=status.HTTP_200_OK,
            include_in_schema=False
)
def get_data(content: ConsecutiveDatapointsRequest) -> ConsecutiveDatapointsResponse:

    if content.processed_files <= 0 or content.max_concurrent_threads <= 0:
        raise HTTPException(status_code=400, detail="Number of processed files or number of threads must be greater than 0")
    
    try:
        processed_files = process_files_from_folder(STOCK_FOLDER, content.processed_files)

        return processed_files
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Error processing file: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing request: {e}")
    
@app.post('/predict-stock-price',
            status_code=status.HTTP_200_OK,
            include_in_schema=False
)
def predict_stock_price(content: PredictionRequest) -> Response:

    if content.max_concurrent_threads <= 0:
        raise HTTPException(status_code=400, detail="Number of threads must be greater than 0")

    try:
        zip_bytes = predict_stock(content)

        response = Response(zip_bytes, media_type="application/x-zip-compressed", headers={
            'Content-Disposition': f'attachment;filename=predicted_stock.zip'
        })

        return response
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Error processing file: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing request: {e}")