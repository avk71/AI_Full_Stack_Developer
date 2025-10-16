import ollama
import os
from dotenv import load_dotenv

load_dotenv()

os.system('cls' if os.name == 'nt' else 'clear')

# Create a client
client = ollama.Client(host=f"http://{os.getenv('ollama_server_id')}:11434")

# Generate a completion
response = client.chat(
    model="deepseek-r1:1.5b",  # or 'mistral', 'gemma'('gemma3:1b',), etc., depending on what's installed
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "What is the capital of France?"},
    ],
)

# Print the result
print(response["message"]["content"])

# The capital of France is Paris. This city has been the birthplace of Étienne Béguin and the home of Napoleon, who were influential figures in the country. Paris is also known for its Eiffel Tower, a landmark symbol of the city, and its role as the capital due to its strong ties with global markets.