from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from .. import models
from ..database import get_db
from ..auth.auth import verify_password, create_access_token

# Create router with prefix to match the token URL
router = APIRouter(prefix="/auth", tags=["auth"])  # Add prefix here

@router.post("/token")  # Remove /auth from here since we have prefix
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db)
):
    print(f"Login attempt for: {form_data.username}")  # Debug print
    try:
        # Find user by email
        query = select(models.User).where(models.User.email == form_data.username)
        result = await db.execute(query)
        user = result.scalar_one_or_none()

        if not user or not verify_password(form_data.password, user.password):
            print("User not found or password mismatch")  # Debug print
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password",
            )

        access_token = create_access_token(data={"sub": user.email})
        return {
            "access_token": access_token,
            "token_type": "bearer"
        }
    except Exception as e:
        print(f"Login error: {str(e)}")  # Debug print
        raise 

@router.post("/admin/login")
async def admin_login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(models.User).filter(models.User.email == form_data.username)
    )
    user = result.scalar_one_or_none()
    
    if not user or not verify_password(form_data.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    if user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized. Admin access only."
        )
    
    access_token = create_access_token(data={"sub": user.email})
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": user.role
    } 