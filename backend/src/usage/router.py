
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from ..core.database import get_db
from ..models.usage import UsageRecord
from ..models.user import User
from ..auth.dependencies import get_current_user

router = APIRouter(prefix="/usage", tags=["usage"])

@router.get("")
async def get_usage(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(
            func.sum(UsageRecord.total_tokens).label("total_tokens"),
            func.count(UsageRecord.id).label("total_requests"),
            func.sum(UsageRecord.input_tokens).label("input_tokens"),
            func.sum(UsageRecord.output_tokens).label("output_tokens"),
        ).where(UsageRecord.user_id == current_user.id)
    )
    row = result.first()
    return {
        "user_id": current_user.id,
        "total_tokens": row.total_tokens or 0,
        "total_requests": row.total_requests or 0,
        "input_tokens": row.input_tokens or 0,
        "output_tokens": row.output_tokens or 0,
    }

@router.get("/history")
async def get_history(
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(UsageRecord).where(UsageRecord.user_id == current_user.id).order_by(UsageRecord.created_at.desc()).limit(limit)
    )
    records = result.scalars().all()
    return [{"id": r.id, "model_id": r.model_id, "provider_id": r.provider_id, "total_tokens": r.total_tokens, "success": r.success, "created_at": r.created_at} for r in records]
