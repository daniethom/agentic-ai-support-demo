from fastapi import FastAPI
import uvicorn
import os

# --- FastAPI Application Setup ---
app = FastAPI(
    title="Mock Remote Device Management Service",
    description="A mock service to simulate remote device actions like reboots.",
    version="1.0.0"
)

# --- API Endpoint: Simulate Device Reboot ---
@app.post(
    "/reboot_device/{device_id}",
    summary="Simulate a remote device reboot"
)
async def reboot_device(device_id: str):
    """
    Simulates initiating a remote reboot for a given device ID.
    - **device_id**: The unique identifier for the device (e.g., router serial, modem MAC).
    """
    # In a real system, this would interact with a device management platform.
    print(f"[{os.getenv('SERVICE_NAME', 'RemoteDevice')}] Initiating remote reboot for device_id: {device_id}")
    # Simulate some delay for realism, but keep it quick for demo
    # await asyncio.sleep(2)
    return {"status": "success", "message": f"Remote reboot command sent to device {device_id}."}

# --- Main function to run the service ---
if __name__ == "__main__":
    port = int(os.getenv("PORT", 8003)) # Using a different port: 8003
    service_name = os.getenv("SERVICE_NAME", "Remote Device Service")
    print(f"Starting {service_name} on http://0.0.0.0:{port}")
    uvicorn.run(app, host="0.0.0.0", port=port)