from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn
import os

# --- Mock Data for our Customer Database ---
# This simulates real customer data that an actual MCP system would access.
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

# --- FastAPI Application Setup ---
app = FastAPI(
    title="Mock Customer Database Service",
    description="A mock service to simulate retrieving customer account information.",
    version="1.0.0"
)

# Pydantic model for the response structure
class AccountStatusResponse(BaseModel):
    account_id: str
    name: str
    service_status: str
    plan: str
    current_issues: list[str]

# --- API Endpoint: Get Account Status ---
@app.get(
    "/account_status/{account_id}",
    response_model=AccountStatusResponse,
    summary="Retrieve detailed account status for a given customer ID"
)
async def get_account_status(account_id: str):
    """
    Retrieves the service status and current issues for a specific customer.
    - **account_id**: The unique identifier for the customer.
    """
    customer = MOCK_CUSTOMERS.get(account_id)
    if not customer:
        raise HTTPException(status_code=404, detail="Account not found. Please provide a valid customer ID.")
    return customer

# --- API Endpoint: Simulate Device Reset ---
@app.post(
    "/device_reset/{device_id}",
    summary="Simulate a remote device reset"
)
async def device_reset(device_id: str):
    """
    Simulates initiating a remote reset for a given device ID.
    In a real scenario, this would trigger an actual hardware reset.
    - **device_id**: The unique identifier for the device.
    """
    # In a real system, this would interact with a device management system.
    # For our mock, we just acknowledge the request.
    print(f"[{os.getenv('SERVICE_NAME', 'CustomerDB')}] Simulating device reset for device_id: {device_id}")
    return {"status": "success", "message": f"Device {device_id} reset initiated."}


# --- Main function to run the service ---
# This part allows us to run the FastAPI app directly using `python app.py`
if __name__ == "__main__":
    # Get port from environment variable, default to 8000
    port = int(os.getenv("PORT", 8000))
    service_name = os.getenv("SERVICE_NAME", "CustomerDB Service")
    print(f"Starting {service_name} on http://0.0.0.0:{port}")
    uvicorn.run(app, host="0.0.0.0", port=port)