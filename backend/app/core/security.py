from datetime import datetime, timedelta, timezone
from typing import Any, Optional
from jose import jwt
from .config import settings

ALGORITHM = "HS256"

def create_access_token(subject: str | Any, role: str, expires_delta: Optional[timedelta] = None) -> str:
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode = {"exp": expire, "sub": str(subject), "role": role}
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def decode_access_token(token: str) -> Optional[dict[str, Any]]:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except Exception:
        return None

def verify_firebase_token(id_token: str) -> Optional[dict[str, Any]]:
    """
    Verifies Firebase-issued identity token using Firebase Admin SDK.
    Falls back gracefully if admin SDK is in offline development mode.
    """
    try:
        import firebase_admin
        from firebase_admin import auth
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token
    except Exception:
        return None

