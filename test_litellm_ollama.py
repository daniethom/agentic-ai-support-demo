from litellm import completion
import os

os.environ["LITELLM_CONFIG_PATH"] = "./litellm.config.json"

response = completion(
    model="demo-llm",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "How do I fix WiFi problems?"}
    ]
)

print(response["choices"][0]["message"]["content"])
