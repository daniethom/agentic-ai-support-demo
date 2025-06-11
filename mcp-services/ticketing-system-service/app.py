from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn
import os
import uuid # To generate unique ticket IDs
from datetime import datetime, timedelta

# --- Mock Data for Ticketing System ---
MOCK_TICKETS = {} # Stores created tickets

class CreateTicketRequest(BaseModel):
    customer_id: str
    issue_summary: str
    priority: str = "Medium" # Default priority

class TicketResponse(BaseModel):
    ticket_id: str
    customer_id: str
    issue_summary: str
    priority: str
    status: str
    created_at: str
    estimated_resolution: str

# --- FastAPI Application Setup ---
app = FastAPI(
    title="Mock Ticketing System Service",
    description="A mock service to simulate creating and managing support tickets.",
    version="1.0.0"
)

# --- API Endpoint: Create a New Ticket ---
@app.post(
    "/create_ticket",
    response_model=TicketResponse,
    summary="Create a new support ticket"
)
async def create_ticket(request: CreateTicketRequest):
    """
    Creates a new support ticket in the system.
    - **customer_id**: The ID of the customer reporting the issue.
    - **issue_summary**: A brief description of the problem.
    - **priority**: The urgency of the ticket (e.g., 'Low', 'Medium', 'High').
    """
    ticket_id = str(uuid.uuid4())[:8] # Generate a short unique ID
    created_at = datetime.now()
    # Estimate resolution based on priority
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
    print(f"[{os.getenv('SERVICE_NAME', 'Ticketing')}] Created ticket: {ticket_id} for {request.customer_id}")
    return ticket_data

# --- API Endpoint: Get Ticket Status ---
@app.get(
    "/ticket_status/{ticket_id}",
    response_model=TicketResponse,
    summary="Retrieve the status of a specific ticket"
)
async def get_ticket_status(ticket_id: str):
    """
    Retrieves the current status of a specific support ticket.
    - **ticket_id**: The unique identifier of the ticket.
    """
    ticket = MOCK_TICKETS.get(ticket_id)
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found.")
    return ticket

# --- Main function to run the service ---
if __name__ == "__main__":
    port = int(os.getenv("PORT", 8002)) # Using a different port: 8002
    service_name = os.getenv("SERVICE_NAME", "Ticketing System Service")
    print(f"Starting {service_name} on http://0.0.0.0:{port}")
    uvicorn.run(app, host="0.0.0.0", port=port)