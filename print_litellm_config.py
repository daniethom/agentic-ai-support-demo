import os
from litellm import completion, model_alias_map

# Optional: Print the config path being used
print(f"LITELLM_CONFIG_PATH: {os.getenv('LITELLM_CONFIG_PATH')}")

# Now print the loaded model alias map
print("Loaded aliases from config:")
print(model_alias_map)
