from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timedelta
import uuid
import jwt
import os
from dotenv import load_dotenv

load_dotenv()

JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "chatbuddy_secret_key_change_in_production_12345")
JWT_ALGORITHM = "HS256"

from database import users_collection, chats_collection
from llm import get_chat_response

app = FastAPI(title="ChatBuddy Backend", version="1.0.0")

# Enable CORS for Flutter app and web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()

# Pydantic models for request validation
class SignupRequest(BaseModel):
    name: str
    email: str
    password: str

class LoginRequest(BaseModel):
    email: str
    password: str

class ChatRequest(BaseModel):
    message: str
    chat_id: Optional[str] = None


# Simple token helper functions
def create_access_token(user_id: str, email: str) -> str:
    expire = datetime.utcnow() + timedelta(days=7)
    payload = {
        "user_id": user_id,
        "email": email,
        "exp": expire
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
        user_id = payload.get("user_id")
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid token")

        user = await users_collection.find_one({"user_id": user_id})
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        return user
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")


# Public root endpoint
@app.get("/")
def root():
    return {"message": "Welcome to ChatBuddy API"}


# 1. Authentication APIs

@app.post("/signup")
async def signup(request: SignupRequest):
    email_clean = request.email.strip().lower()

    # Check if user already exists
    existing_user = await users_collection.find_one({"email": email_clean})
    if existing_user:
        raise HTTPException(status_code=400, detail="Email is already registered")

    user_id = str(uuid.uuid4())

    new_user = {
        "user_id": user_id,
        "name": request.name.strip(),
        "email": email_clean,
        "password": request.password,
        "created_at": datetime.utcnow().isoformat()
    }

    await users_collection.insert_one(new_user)

    return {
        "message": "User registered successfully",
        "user_id": user_id
    }


@app.post("/login")
async def login(request: LoginRequest):
    email_clean = request.email.strip().lower()

    # Find user by email
    user = await users_collection.find_one({"email": email_clean})
    if not user:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    # Verify password
    if user["password"] != request.password:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    # Generate token
    token = create_access_token(user["user_id"], user["email"])

    return {
        "token": token,
        "user": {
            "user_id": user["user_id"],
            "name": user["name"],
            "email": user["email"]
        }
    }

    return {
        "token": token,
        "user": {
            "user_id": user["user_id"],
            "name": user["name"],
            "email": user["email"]
        }
    }


# 2. Chat APIs

@app.post("/chat")
async def chat(request: ChatRequest, current_user: dict = Depends(get_current_user)):
    user_id = current_user["user_id"]
    user_message = request.message.strip()

    if not user_message:
        raise HTTPException(status_code=400, detail="Message cannot be empty")

    now = datetime.utcnow().isoformat()
    chat_id = request.chat_id
    messages_history = []
    is_new_chat = False

    if chat_id:
        # Fetch existing conversation belonging to this user
        existing_chat = await chats_collection.find_one({"chat_id": chat_id, "user_id": user_id})
        if not existing_chat:
            raise HTTPException(status_code=404, detail="Chat conversation not found")
        messages_history = existing_chat.get("messages", [])
    else:
        # Create a new conversation ID and title
        chat_id = str(uuid.uuid4())
        is_new_chat = True
        title = user_message[:30] + ("..." if len(user_message) > 30 else "")

    # Generate AI response using LangChain and Groq
    try:
        ai_response = get_chat_response(messages_history, user_message)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"LLM Error: {str(e)}")

    user_msg_entry = {
        "role": "user",
        "content": user_message,
        "created_at": now
    }
    ai_msg_entry = {
        "role": "assistant",
        "content": ai_response,
        "created_at": now
    }

    if is_new_chat:
        new_chat_doc = {
            "chat_id": chat_id,
            "user_id": user_id,
            "title": title,
            "messages": [user_msg_entry, ai_msg_entry],
            "created_at": now,
            "updated_at": now
        }
        await chats_collection.insert_one(new_chat_doc)
    else:
        await chats_collection.update_one(
            {"chat_id": chat_id},
            {
                "$push": {"messages": {"$each": [user_msg_entry, ai_msg_entry]}},
                "$set": {"updated_at": now}
            }
        )

    return {
        "chat_id": chat_id,
        "response": ai_response
    }


@app.get("/chats")
async def get_all_chats(current_user: dict = Depends(get_current_user)):
    user_id = current_user["user_id"]

    cursor = chats_collection.find(
        {"user_id": user_id},
        {"_id": 0, "chat_id": 1, "title": 1, "created_at": 1, "updated_at": 1}
    ).sort("updated_at", -1)

    chats = await cursor.to_list(length=100)
    return chats


@app.get("/chats/{chat_id}")
async def get_chat_by_id(chat_id: str, current_user: dict = Depends(get_current_user)):
    user_id = current_user["user_id"]

    chat_doc = await chats_collection.find_one(
        {"chat_id": chat_id, "user_id": user_id},
        {"_id": 0}
    )

    if not chat_doc:
        raise HTTPException(status_code=404, detail="Chat conversation not found")

    return chat_doc


@app.delete("/chats/{chat_id}")
async def delete_chat(chat_id: str, current_user: dict = Depends(get_current_user)):
    user_id = current_user["user_id"]

    result = await chats_collection.delete_one({"chat_id": chat_id, "user_id": user_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Chat conversation not found")

    return {"message": "Chat deleted successfully"}


@app.delete("/chats")
async def delete_all_chats(current_user: dict = Depends(get_current_user)):
    user_id = current_user["user_id"]

    result = await chats_collection.delete_many({"user_id": user_id})
    return {"message": f"All {result.deleted_count} chats deleted successfully"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

