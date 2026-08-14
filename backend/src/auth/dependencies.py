
from fastapi import Depends, HTTPException, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from ..core.database import get_db
from ..models.user import User
from .security import decode_token
from ..core.exceptions import UnauthorizedException

async def get_current_user(authorization: str = Header(None), db: AsyncSession = Depends(get_db)) -> User:
    if not authorization or not authorization.startswith("Bearer "):
        raise UnauthorizedException("Missing or invalid authorization header")
    
    token = authorization.replace("Bearer ", "")
    try:
        payload = decode_token(token)
        if payload.get("type") != "access":
            raise UnauthorizedException("Invalid access token")
        user_id = payload.get("sub")
        if not user_id:
            raise UnauthorizedException("Invalid token payload")
    except:
        raise UnauthorizedException("Invalid or expired token")
    
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise UnauthorizedException("User not found or deactivated")
    
    return user

async def get_optional_user(authorization: str = Header(None), db: AsyncSession = Depends(get_db)):
    if not authorization:
        return None
    try:
        return await get_current_user(authorization, db)
    except:
        return None
