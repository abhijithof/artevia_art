import os
from fastapi import UploadFile
from datetime import datetime

UPLOAD_DIR = "static/uploads"

async def save_uploaded_file(file: UploadFile) -> str:
    # Create uploads directory if it doesn't exist
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    
    # Generate unique filename using timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{timestamp}_{file.filename}"
    file_path = os.path.join(UPLOAD_DIR, filename)
    
    # Save the file
    content = await file.read()
    with open(file_path, "wb") as f:
        f.write(content)
    
    # Return the relative path
    return f"/uploads/{filename}" 
from fastapi import UploadFile
from datetime import datetime

UPLOAD_DIR = "static/uploads"

async def save_uploaded_file(file: UploadFile) -> str:
    # Create uploads directory if it doesn't exist
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    
    # Generate unique filename using timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{timestamp}_{file.filename}"
    file_path = os.path.join(UPLOAD_DIR, filename)
    
    # Save the file
    content = await file.read()
    with open(file_path, "wb") as f:
        f.write(content)
    
    # Return the relative path
    return f"/uploads/{filename}"