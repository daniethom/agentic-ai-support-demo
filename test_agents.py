import os
from app import agents

# Optional: force LiteLLM config path
os.environ["LITELLM_CONFIG_PATH"] = os.path.abspath("litellm.config.json")

# Replace this with any customer-like inquiry
test_inquiry = "My internet keeps disconnecting every few hours. Can you help?"

# Run the agent logic
response = agents.run(test_inquiry)

print("\n🧪 Agent Response:")
print(response)
