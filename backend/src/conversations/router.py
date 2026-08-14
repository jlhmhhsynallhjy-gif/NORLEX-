
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from pydantic import BaseModel
from typing import List, Optional
import uuid
from datetime import datetime

from ..core.database import get_db
from ..models.conversation import Conversation
from ..models.message import Message
from ..models.user import User
from ..auth.dependencies import get_current_user
from ..core.exceptions import InvalidRequestException, UnauthorizedException

router = APIRouter(prefix="/conversations", tags=["conversations"])

class CreateConversationRequest(BaseModel):
    title: str = "New Chat"
    project_id: Optional[str] = None

class ConversationResponse(BaseModel):
    id: str
    user_id: str
    title: str
    project_id: Optional[str]
    archived: bool
    created_at: datetime
    updated_at: datetime

class MessageResponse(BaseModel):
    id: str
    conversation_id: str
    role: str
    content: str
    status: str
    model_id: Optional[str]
    created_at: datetime

@router.post("", response_model=ConversationResponse)
async def create_conversation(
    body: CreateConversationRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    conv = Conversation(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        title=body.title,
        project_id=body.project_id,
    )
    db.add(conv)
    await db.commit()
    await db.refresh(conv)
    return ConversationResponse(
        id=conv.id, user_id=conv.user_id, title=conv.title,
        project_id=conv.project_id, archived=conv.archived,
        created_at=conv.created_at, updated_at=conv.updated_at
    )

@router.get("", response_model=List[ConversationResponse])
async def list_conversations(
    include_archived: bool = False,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = select(Conversation).where(Conversation.user_id == current_user.id)
    if not include_archived:
        query = query.where(Conversation.archived == False)
    query = query.order_by(desc(Conversation.updated_at))
    result = await db.execute(query)
    convs = result.scalars().all()
    return [
        ConversationResponse(
            id=c.id, user_id=c.user_id, title=c.title,
            project_id=c.project_id, archived=c.archived,
            created_at=c.created_at, updated_at=c.updated_at
        ) for c in convs
    ]

@router.get("/{conversation_id}", response_model=ConversationResponse)
async def get_conversation(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Conversation).where(Conversation.id == conversation_id))
    conv = result.scalar_one_or_none()
    if not conv:
        raise InvalidRequestException("Conversation not found", code="not_found")
    if conv.user_id != current_user.id:
        raise UnauthorizedException("Not authorized to access this conversation")
    return ConversationResponse(
        id=conv.id, user_id=conv.user_id, title=conv.title,
        project_id=conv.project_id, archived=conv.archived,
        created_at=conv.created_at, updated_at=conv.updated_at
    )

@router.delete("/{conversation_id}")
async def delete_conversation(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Conversation).where(Conversation.id == conversation_id))
    conv = result.scalar_one_or_none()
    if not conv:
        raise InvalidRequestException("Conversation not found", code="not_found")
    if conv.user_id != current_user.id:
        raise UnauthorizedException("Not authorized")
    await db.delete(conv)
    await db.commit()
    return {"message": "Deleted"}

@router.get("/{conversation_id}/messages", response_model=List[MessageResponse])
async def get_messages(
    conversation_id: str,
    limit: int = Query(100, le=200),
    offset: int = 0,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Check ownership
    result = await db.execute(select(Conversation).where(Conversation.id == conversation_id))
    conv = result.scalar_one_or_none()
    if not conv or conv.user_id != current_user.id:
        raise UnauthorizedException("Not authorized")
    
    query = select(Message).where(Message.conversation_id == conversation_id).order_by(Message.created_at.asc()).limit(limit).offset(offset)
    result = await db.execute(query)
    msgs = result.scalars().all()
    return [
        MessageResponse(
            id=m.id, conversation_id=m.conversation_id, role=m.role,
            content=m.content, status=m.status, model_id=m.model_id,
            created_at=m.created_at
        ) for m in msgs
    ]
