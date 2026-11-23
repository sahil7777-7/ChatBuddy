import os
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv

load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL", "")
DATABASE_NAME = os.getenv("DATABASE_NAME", "chatbuddy")

mongo_url = MONGODB_URL if MONGODB_URL else "mongodb://localhost:27017"
client = AsyncIOMotorClient(mongo_url)
db = client[DATABASE_NAME]

# Collections
users_collection = db["users"]
chats_collection = db["chats"]

