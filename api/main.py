from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn
import uuid
from datetime import datetime, timedelta
from typing import List, Optional

# --- Pydantic Models ---
class AccountStatusResponse(BaseModel):
    account_id: str
    name: str
    service_status: str
    plan: str
    current_issues: List[str]

class TroubleshootingGuideResponse(BaseModel):
    issue: str
    steps: List[str]

class CreateTicketRequest(BaseModel):
    customer_id: str
    issue_summary: str
    priority: str = "Medium"

class TicketResponse(BaseModel):
    ticket_id: str
    customer_id: str
    issue_summary: str
    priority: str
    status: str
    created_at: str
    estimated_resolution: str

# --- Mock Data ---
MOCK_CUSTOMERS = {
    "CUST123": {
        "account_id": "CUST123",
        "name": "Alice Smith",
        "service_status": "Active",
        "plan": "Premium Internet",
        "current_issues": []
    },
    "CUST456": {
        "account_id": "CUST456",
        "name": "Bob Johnson",
        "service_status": "Inactive",
        "plan": "Basic Internet",
        "current_issues": ["internet_down", "billing_issue"]
    },
    "CUST789": {
        "account_id": "CUST789",
        "name": "Charlie Brown",
        "service_status": "Active",
        "plan": "Standard TV",
        "current_issues": ["login_failure"]
    },
    "CUST000": {
        "account_id": "CUST000",
        "name": "Demo Customer",
        "service_status": "Active",
        "plan": "Fiber Max",
        "current_issues": []
    }
}

MOCK_TROUBLESHOOTING_GUIDES = {
    "internet_slow": {
        "issue": "Internet Slow",
        "steps": [
            "1. Restart your router and modem. Unplug them for 30 seconds, then plug back in.",
            "2. Check if multiple devices are using bandwidth heavily (e.g., streaming, large downloads).",
            "3. Perform a speed test at speedtest.net to confirm current speed.",
            "4. Ensure your router's firmware is up to date.",
            "5. Try connecting directly to the modem with an Ethernet cable to rule out Wi-Fi issues."
        ]
    },
    "no_internet_connection": {
        "issue": "No Internet Connection",
        "steps": [
            "1. Verify all cables are securely connected to your modem and router.",
            "2. Check the indicator lights on your modem/router. Look for a solid internet light.",
            "3. Perform a full power cycle of your modem and router (unplug for 1 minute).",
            "4. Check for service outages in your area with your internet service provider.",
            "5. If using Wi-Fi, try connecting with an Ethernet cable to bypass Wi-Fi problems."
        ]
    },
    "login_issue": {
        "issue": "Login Issues",
        "steps": [
            "1. Double-check your username and password for typos (case-sensitivity matters).",
            "2. Ensure Caps Lock is off.",
            "3. Try the 'Forgot Password' link to reset your password.",
            "4. Clear your browser's cache and cookies or try a different browser.",
            "5. If your account is locked, wait 15-30 minutes and try again, or contact support for a manual unlock."
        ]
    }
}

MOCK_TICKETS = {}

# --- FastAPI Application ---
app = FastAPI(
    title="Unified IT Support API",
    description="Consolidated API for customer data, troubleshooting, ticketing, and device management",
    version="1.0.0"
)

# Customer Service Endpoints (Port 8000 equivalent)
@app.get("/account_status/{account_id}", response_model=AccountStatusResponse)
async def get_account_status(account_id: str):
    customer = MOCK_CUSTOMERS.get(account_id)
    if not customer:
        raise HTTPException(status_code=404, detail="Account not found")
    return customer

# Troubleshooting Service Endpoints (Port 8001 equivalent)
@app.get("/troubleshooting_steps/{issue_type}", response_model=TroubleshootingGuideResponse)
async def get_troubleshooting_steps(issue_type: str):
    guide = MOCK_TROUBLESHOOTING_GUIDES.get(issue_type.lower())
    if not guide:
        raise HTTPException(status_code=404, detail=f"Guide for '{issue_type}' not found")
    return guide

# Ticketing Service Endpoints (Port 8002 equivalent)
@app.post("/create_ticket", response_model=TicketResponse)
async def create_ticket(request: CreateTicketRequest):
    ticket_id = str(uuid.uuid4())[:8]
    created_at = datetime.now()
    
    if request.priority.lower() == "high":
        estimated_resolution = created_at + timedelta(hours=4)
    elif request.priority.lower() == "medium":
        estimated_resolution = created_at + timedelta(hours=24)
    else:
        estimated_resolution = created_at + timedelta(days=3)

    ticket_data = {
        "ticket_id": ticket_id,
        "customer_id": request.customer_id,
        "issue_summary": request.issue_summary,
        "priority": request.priority,
        "status": "Open",
        "created_at": created_at.isoformat(),
        "estimated_resolution": estimated_resolution.isoformat()
    }
    MOCK_TICKETS[ticket_id] = ticket_data
    return ticket_data

# Device Management Endpoints (Port 8003 equivalent)
@app.post("/reboot_device/{device_id}")
async def reboot_device(device_id: str):
    return {
        "status": "success", 
        "message": f"Remote reboot command sent to device {device_id}."
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "unified-api"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)