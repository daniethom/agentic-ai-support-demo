from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn
import os

# --- Mock Data for Troubleshooting Steps ---
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

# --- FastAPI Application Setup ---
app = FastAPI(
    title="Mock Troubleshooting Service",
    description="Provides predefined troubleshooting steps for common IT issues.",
    version="1.0.0"
)

# Pydantic model for the response structure
class TroubleshootingGuideResponse(BaseModel):
    issue: str
    steps: list[str]

# --- API Endpoint: Get Troubleshooting Steps ---
@app.get(
    "/troubleshooting_steps/{issue_type}",
    response_model=TroubleshootingGuideResponse,
    summary="Retrieve troubleshooting steps for a specific issue type"
)
async def get_troubleshooting_steps(issue_type: str):
    """
    Retrieves a list of troubleshooting steps for a common issue type.
    - **issue_type**: Identifier for the issue (e.g., 'internet_slow', 'login_issue').
    """
    guide = MOCK_TROUBLESHOOTING_GUIDES.get(issue_type.lower())
    if not guide:
        raise HTTPException(status_code=404, detail=f"Troubleshooting guide for '{issue_type}' not found.")
    return guide

# --- Main function to run the service ---
if __name__ == "__main__":
    port = int(os.getenv("PORT", 8001)) # Using a different port: 8001
    service_name = os.getenv("SERVICE_NAME", "Troubleshooting Service")
    print(f"Starting {service_name} on http://0.0.0.0:{port}")
    uvicorn.run(app, host="0.0.0.0", port=port)