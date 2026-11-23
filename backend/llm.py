from langchain_groq import ChatGroq
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage
from dotenv import load_dotenv
load_dotenv()
def get_chat_response(messages_history: list, new_user_message: str) -> str:

    llm = ChatGroq(
        model='openai/gpt-oss-120b',
        temperature=0.7
    )

    # Simple system prompt
    prompt_messages = [
        SystemMessage(content="You are ChatBuddy, a helpful and friendly AI assistant, u delvop sahil kumar, ur model name sahil-gpt-model")
    ]

    # Add previous messages for conversation context
    for msg in messages_history:
        role = msg.get("role")
        content = msg.get("content", "")
        if role == "user":
            prompt_messages.append(HumanMessage(content=content))
        elif role == "assistant":
            prompt_messages.append(AIMessage(content=content))

    # Add the current user message
    prompt_messages.append(HumanMessage(content=new_user_message))

    # Generate response
    response = llm.invoke(prompt_messages)
    return response.content
