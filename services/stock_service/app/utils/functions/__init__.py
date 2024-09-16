import os
import io
import zipfile

import concurrent.futures

from app.restschema import ConsecutiveDatapointsResponse, File, Folder, PredictionRequest
from app.utils.pandas import PandasUtils

from app.utils.config import COLUMNS

pandas_utils = PandasUtils()

def process_file(file_path: str, folder: Folder) -> File:

    file = File(file_name=os.path.basename(file_path), random_rows=[])

    df = pandas_utils.get_data_from_file(file_path, COLUMNS)
    random_data = pandas_utils.get_n_values_from_random_timestamp(df, n=10)
    file.random_rows = random_data.to_dict(orient='records')

    folder.files.append(file)

    return file

def predict_stock_file(file: File, folder_name: str, zf: zipfile.ZipFile) -> File:
    
    df = pandas_utils.get_stock_df_from_list(file.random_rows)
    predicted_stock = pandas_utils.predict_rows_in_df(df)
    
    predicted_file_name = f"{file.file_name.split('.')[0]}_predicted.csv"
    predicted_file_path = os.path.join(folder_name, predicted_file_name)

    output_bytes = io.BytesIO()
    predicted_stock.to_csv(output_bytes, index=False)
    output_bytes.seek(0)

    # Each file is addded to the archive here
    zf.writestr(predicted_file_path, output_bytes.read())

def process_files_from_folder(folder_path: str, num_files: int, max_concurrent_threads: int = 1) -> ConsecutiveDatapointsResponse:


    response = ConsecutiveDatapointsResponse(folders=[])

    try:
    # Threadpool is used to process files concurrently
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_concurrent_threads) as executor:
            threads = []
            folders = os.listdir(folder_path)
            for folder in folders:
                response.folders.append(Folder(folder_name=folder, files=[]))

                files = os.listdir(os.path.join(folder_path, folder))
                for file in files[0: num_files]:
                    file_path = os.path.join(folder_path, folder, file)
                    t = executor.submit(process_file, file_path, response.folders[-1])
                    threads.append(t)

            for t in concurrent.futures.as_completed(threads):
                try:
                    t.result()
                except Exception as e:
                    print(f"Error processing files: {e}")
                    raise ValueError(f"Error processing files: {e}")
    except Exception as e:
        raise

    return response
    

def predict_stock(content: PredictionRequest) -> bytes:

    s = io.BytesIO()
    zf = zipfile.ZipFile(s, "w")

    try:
        with concurrent.futures.ThreadPoolExecutor(max_workers=content.max_concurrent_threads) as executor:
            threads = []
            for folder in content.folders:
                for file in folder.files:
                    t = executor.submit(predict_stock_file, file, folder.folder_name, zf)
                    threads.append(t)

            for t in concurrent.futures.as_completed(threads):
                try:
                    t.result()
                except Exception as e:
                    print(f"Error predicting stock prices: {e}")
                    raise ValueError(f"Error predicting stock prices: {e}")
    except Exception as e:
        raise

    zf.close()

    return s.getvalue()