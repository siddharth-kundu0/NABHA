from pydantic import BaseModel
from typing import List, Dict, Any

class OutboxMutation(BaseModel):
    id: str
    entity: str
    action: str
    payload: Dict[str, Any]
    queued_at: str

class BatchSyncRequest(BaseModel):
    device_id: str
    role: str
    mutations: List[OutboxMutation]

class BatchSyncResponse(BaseModel):
    success: bool
    processed_count: int
    failed_count: int
    server_timestamp: str
    message: str
