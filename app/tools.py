# app/tools.py

import os
import json
import requests
import weaviate
from typing import Type
from pydantic import BaseModel, Field
from crewai.tools.base_tool import BaseTool
from llama_index.core import VectorStoreIndex
from llama_index.vector_stores.weaviate import WeaviateVectorStore
from tavily import TavilyClient

# ---------------------------
# 1. Argument Schemas
# ---------------------------

class KnowledgeBaseInput(BaseModel):
    question: str = Field(..., description="User's question for the knowledge base.")

class CustomerDetailsInput(BaseModel):
    account_id: str = Field(..., description="Customer's unique account ID.")

class TroubleshootingInput(BaseModel):
    issue_type: str = Field(..., description="Issue type, e.g. 'login_issue'.")

class TicketingInput(BaseModel):
    customer_id: str = Field(..., description="Customer's unique account ID.")
    issue_summary: str = Field(..., description="Short issue summary.")

class DeviceRebootInput(BaseModel):
    device_id: str = Field(..., description="Device identifier to reboot.")

class TavilySearchInput(BaseModel):
    query: str = Field(..., description="Web search query string.")


# ---------------------------
# 2. Tool Implementations
# ---------------------------

class KnowledgeBaseTool(BaseTool):
    name: str = "Knowledge Base Search"
    description: str = "Searches FAQs using a vector database."
    args_schema: Type[BaseModel] = KnowledgeBaseInput

    def _run(self, question: str) -> str:
        client = None
        try:
            client = weaviate.connect_to_local()
            store = WeaviateVectorStore(weaviate_client=client, index_name="SupportFAQs")
            index = VectorStoreIndex.from_vector_store(vector_store=store)
            engine = index.as_query_engine()
            response = engine.query(question)
            return str(response)
        except Exception as e:
            return f"Knowledge base query failed: {e}"
        finally:
            if client:
                client.close()

class CustomerDetailsTool(BaseTool):
    name: str = "Get Customer Details"
    description: str = "Fetches customer account details."
    args_schema: Type[BaseModel] = CustomerDetailsInput

    def _run(self, account_id: str) -> str:
        url = f"http://localhost:8000/account_status/{account_id}"
        try:
            r = requests.get(url, timeout=5)
            r.raise_for_status()
            return json.dumps(r.json(), indent=2)
        except requests.RequestException as e:
            return f"Failed to fetch customer details: {e}"

class TroubleshootingTool(BaseTool):
    name: str = "Get Troubleshooting Steps"
    description: str = "Provides troubleshooting guides for known issues."
    args_schema: Type[BaseModel] = TroubleshootingInput

    def _run(self, issue_type: str) -> str:
        url = f"http://localhost:8001/troubleshooting_steps/{issue_type}"
        try:
            r = requests.get(url, timeout=5)
            r.raise_for_status()
            return json.dumps(r.json(), indent=2)
        except requests.RequestException as e:
            return f"Failed to fetch troubleshooting steps: {e}"

class TicketingTool(BaseTool):
    name: str = "Create Support Ticket"
    description: str = "Creates a new support ticket."
    args_schema: Type[BaseModel] = TicketingInput

    def _run(self, customer_id: str, issue_summary: str) -> str:
        url = "http://localhost:8002/create_ticket"
        payload = {"customer_id": customer_id, "issue_summary": issue_summary}
        try:
            r = requests.post(url, json=payload, timeout=5)
            r.raise_for_status()
            return json.dumps(r.json(), indent=2)
        except requests.RequestException as e:
            return f"Failed to create support ticket: {e}"

class DeviceRebootTool(BaseTool):
    name: str = "Reboot Device"
    description: str = "Sends a remote reboot command to a device."
    args_schema: Type[BaseModel] = DeviceRebootInput

    def _run(self, device_id: str) -> str:
        url = f"http://localhost:8003/reboot_device/{device_id}"
        try:
            r = requests.post(url, timeout=5)
            r.raise_for_status()
            return json.dumps(r.json(), indent=2)
        except requests.RequestException as e:
            return f"Failed to reboot device: {e}"

class TavilySearchTool(BaseTool):
    name: str = "Web Search"
    description: str = "Performs real-time web search using Tavily (requires API key)."
    args_schema: Type[BaseModel] = TavilySearchInput

    def _run(self, query: str) -> str:
        key = os.getenv("TAVILY_API_KEY")
        if not key:
            return "Tavily API key not set. Web search is disabled."

        try:
            client = TavilyClient(api_key=key)
            res = client.search(query=query, search_depth="basic")
            return json.dumps(res.get("results", []), indent=2)
        except Exception as e:
            return f"Tavily search failed: {e}"