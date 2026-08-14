import pytest
from src.auth.security import hash_password, verify_password, create_access_token, decode_token

def test_password_hashing():
    pwd = "securePassword123"
    hashed = hash_password(pwd)
    assert verify_password(pwd, hashed) == True
    assert verify_password("wrong", hashed) == False

def test_jwt_tokens():
    data = {"sub": "user123", "email": "test@norlex.app"}
    token = create_access_token(data)
    assert token is not None
    payload = decode_token(token)
    assert payload["sub"] == "user123"
