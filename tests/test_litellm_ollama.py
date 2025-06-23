from litellm import completion

response = completion(
    model="ollama/mistral",  # <-- provider/model_name directly
    api_base="http://localhost:11434",  # required for local Ollama
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "What's the capital of France?"}
    ]
)

print(response["choices"][0]["message"]["content"])

