from .auth import (
    get_current_user,
    get_password_hash,
    verify_password,
    create_access_token
)

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session
from .. import models
from ..database import get_db

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/token")

async def get_current_active_user(current_user: models.User = Depends(get_current_user)):
    if current_user.status != "active":
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

__all__ = ['get_current_user', 'get_password_hash', 'verify_password', 'create_access_token'] 