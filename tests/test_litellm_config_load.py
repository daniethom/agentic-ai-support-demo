import os
from litellm import completion, model_alias_map

# Confirm config path
print("LITELLM_CONFIG_PATH:", os.getenv("LITELLM_CONFIG_PATH"))

# Try calling a dummy completion with the alias to force-load the config
try:
    response = completion(
        model="demo-llm",
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Hello!"},
        ]
    )
    print("Success! Response:", response["choices"][0]["message"]["content"])
except Exception as e:
    print("Error calling model:", e)

# Check if aliases were loaded
print("Loaded model_alias_map:", model_alias_map)
