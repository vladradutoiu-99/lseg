import os
import io
from fastapi import (
    FastAPI,
    Request,
    status,
    HTTPException,
    Response
)
import zipfile

from app.restschema import SimpleRequest, SimpleResponse, File, Folder, PredictionRequest
from app.utils.pandas import PandasUtils

STOCK_FOLDER = 'stock_price_data_files'
COLUMNS = ['STOCK_ID', 'TIMESTAMP', 'PRICE']

app = FastAPI()

pandas_utils = PandasUtils()

def process_files_from_folder(folder_path: str, num_files: int):


    response = SimpleResponse(folders=[])

    try:
        folders = os.listdir(folder_path)
        for folder in folders:
            response.folders.append(Folder(folder_name=folder, files=[]))

            files = os.listdir(os.path.join(folder_path, folder))
            for file in files[0: num_files]:
                response.folders[-1].files.append(File(file_name=file, random_rows=[]))

                file_path = os.path.join(folder_path, folder, file)
                df = pandas_utils.get_data_from_file(file_path, COLUMNS)
                random_data = pandas_utils.get_n_values_from_random_timestamp(df, n=10)
                response.folders[-1].files[-1].random_rows = random_data.to_dict(orient='records')
        return response
    
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error reading files, check your folder structure: {e}")

def predict_stock(content: PredictionRequest):

    s = io.BytesIO()
    zf = zipfile.ZipFile(s, "w")

    for folder in content.folders:
        for file in folder.files:
            df = pandas_utils.get_stock_df_from_list(file.random_rows)
            predicted_stock = pandas_utils.predict_rows_in_df(df)
            
            predicted_file_name = f"{file.file_name.split('.')[0]}_predicted.csv"
            predicted_file_path = os.path.join(folder.folder_name, predicted_file_name)
            output_bytes = io.BytesIO()
            predicted_stock.to_csv(output_bytes, index=False)
            output_bytes.seek(0)
            zf.writestr(predicted_file_path, output_bytes.read())

    zf.close()

    resp = Response(s.getvalue(), media_type="application/x-zip-compressed", headers={
        'Content-Disposition': f'attachment;filename=predicted_stock.zip'
    })

    return resp

    


@app.post('/api-consecutive-datapoints',
            status_code=status.HTTP_200_OK,
            include_in_schema=False
)
def get_data(request: Request, content: SimpleRequest) -> SimpleResponse:

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

    try:
        zip = predict_stock(content)

        return zip
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error processing request: {e}")