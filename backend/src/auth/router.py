
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel, EmailStr
from datetime import datetime, timedelta
import hashlib
import uuid

from ..core.database import get_db
from ..models.user import User
from ..models.session import RefreshToken
from .security import hash_password, verify_password, create_access_token, create_refresh_token, decode_token
from ..core.exceptions import UnauthorizedException, InvalidRequestException
from ..config.settings import settings

router = APIRouter(prefix="/auth", tags=["auth"])

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    full_name: str | None = None

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class RefreshRequest(BaseModel):
    refresh_token: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: dict

def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()

@router.post("/register")
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    # Check existing
    result = await db.execute(select(User).where(User.email == body.email))
    existing = result.scalar_one_or_none()
    if existing:
        raise InvalidRequestException("Email already registered", code="email_exists")
    
    if len(body.password) < 8:
        raise InvalidRequestException("Password must be at least 8 characters", code="weak_password")
    
    user = User(
        id=str(uuid.uuid4()),
        email=body.email,
        hashed_password=hash_password(body.password),
        full_name=body.full_name,
        is_active=True,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    
    # Create tokens
    access_token = create_access_token({"sub": user.id, "email": user.email})
    refresh_token = create_refresh_token({"sub": user.id})
    token_hash = hash_token(refresh_token)
    
    refresh_record = RefreshToken(
        id=str(uuid.uuid4()),
        user_id=user.id,
        token_hash=token_hash,
        expires_at=datetime.utcnow() + timedelta(days=settings.jwt_refresh_expire_days),
    )
    db.add(refresh_record)
    await db.commit()
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.jwt_access_expire_minutes * 60,
        user={"id": user.id, "email": user.email, "full_name": user.full_name}
    )

@router.post("/login")
async def login(body: LoginRequest, request: Request, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()
    if not user or not verify_password(body.password, user.hashed_password):
        raise UnauthorizedException("Invalid email or password")
    
    if not user.is_active:
        raise UnauthorizedException("Account deactivated")
    
    access_token = create_access_token({"sub": user.id, "email": user.email})
    refresh_token = create_refresh_token({"sub": user.id})
    token_hash = hash_token(refresh_token)
    
    refresh_record = RefreshToken(
        id=str(uuid.uuid4()),
        user_id=user.id,
        token_hash=token_hash,
        expires_at=datetime.utcnow() + timedelta(days=settings.jwt_refresh_expire_days),
        user_agent=request.headers.get("user-agent"),
        ip_address=request.client.host if request.client else None,
    )
    db.add(refresh_record)
    await db.commit()
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.jwt_access_expire_minutes * 60,
        user={"id": user.id, "email": user.email, "full_name": user.full_name}
    )

@router.post("/refresh")
async def refresh(body: RefreshRequest, db: AsyncSession = Depends(get_db)):
    try:
        payload = decode_token(body.refresh_token)
        if payload.get("type") != "refresh":
            raise UnauthorizedException("Invalid refresh token")
        user_id = payload.get("sub")
    except:
        raise UnauthorizedException("Invalid refresh token")
    
    token_hash = hash_token(body.refresh_token)
    result = await db.execute(select(RefreshToken).where(RefreshToken.token_hash == token_hash))
    token_record = result.scalar_one_or_none()
    
    if not token_record or token_record.is_revoked or token_record.expires_at < datetime.utcnow():
        raise UnauthorizedException("Refresh token expired or revoked")
    
    # Check user
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise UnauthorizedException("User not found")
    
    # Rotate refresh token (revoke old, create new)
    token_record.is_revoked = True
    new_refresh_token = create_refresh_token({"sub": user.id})
    new_hash = hash_token(new_refresh_token)
    
    new_record = RefreshToken(
        id=str(uuid.uuid4()),
        user_id=user.id,
        token_hash=new_hash,
        expires_at=datetime.utcnow() + timedelta(days=settings.jwt_refresh_expire_days),
    )
    db.add(new_record)
    await db.commit()
    
    access_token = create_access_token({"sub": user.id, "email": user.email})
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh_token,
        expires_in=settings.jwt_access_expire_minutes * 60,
        user={"id": user.id, "email": user.email, "full_name": user.full_name}
    )

@router.post("/logout")
async def logout(body: RefreshRequest, db: AsyncSession = Depends(get_db)):
    token_hash = hash_token(body.refresh_token)
    result = await db.execute(select(RefreshToken).where(RefreshToken.token_hash == token_hash))
    token_record = result.scalar_one_or_none()
    if token_record:
        token_record.is_revoked = True
        await db.commit()
    return {"message": "Logged out"}

@router.get("/me")
async def get_me(current_user = Depends(lambda: None)):  # Will be replaced by dependency
    # This will be overridden by auth dependency in main.py
    return {"user": current_user}
