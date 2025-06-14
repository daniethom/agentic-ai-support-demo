import os
from litellm import completion
import litellm
litellm._turn_on_debug()

# Ensure config path is set
os.environ["LITELLM_CONFIG_PATH"] = "/Users/dthom/git/agentic-ai-support-demo/litellm.config.json"

print("📄 LITELLM_CONFIG_PATH:", os.environ.get("LITELLM_CONFIG_PATH"))

response = completion(
    model="demo-llm",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "What is the capital of France?"}
    ]
)

print("✅ Response:", response["choices"][0]["message"]["content"])