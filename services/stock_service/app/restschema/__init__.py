from pydantic import BaseModel
from typing import Dict, List, Optional

class SimpleRequest(BaseModel):
    processed_files: int
    max_concurrent_threads: Optional[int] = 1

class File(BaseModel):
    file_name: str
    random_rows: List[Dict]

class Folder(BaseModel):
    folder_name: str
    files: list[File]

class SimpleResponse(BaseModel):
    folders: list[Folder]


class PredictionRequest(BaseModel):
    folders: list[Folder]
    max_concurrent_threads: Optional[int] = 1