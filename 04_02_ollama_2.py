import requests
import json
import os
import sys


os.system('cls' if os.name == 'nt' else 'clear')

from dotenv import load_dotenv

import time

# from IPython.display import display, Markdown

# sys.exit(0)

load_dotenv()

ollama_url = f"http://{os.getenv('ollama_server_id')}:11434/api/generate"

data = {
    "model": "deepseek-r1:1.5b",
    "prompt": "Can you explain what transformers are in the context of machine learning?",
    "system": "You are a knowledgeable and precise AI assistant with expertise in machine learning and NLP. Provide clear, technical explanations suitable for a developer audience."
}

time_start = time.time()

response = requests.post(
    url=ollama_url, json=data, stream=False
)  # remove the stream=True to get the full response

time_end = time.time()
print(f"Request time: {time_end - time_start} seconds")

# check the response status
if response.status_code == 200:
    print("Generated Text:", end=" ", flush=True)
    # Iterate over the streaming response
    for line in response.iter_lines():
        if line:
            # Decode the line and parse the JSON
            decoded_line = line.decode("utf-8")
            result = json.loads(decoded_line)
            # Get the text from the response
            generated_text = result.get("response", "")
            print(generated_text, end="", flush=True)
else:
    print("Error:", response.status_code, response.text)

# Request time: 5.658616304397583 seconds
# Generated Text: Transformers are a class of deep neural network architectures that have made significant impacts in natural language processing (NLP). Here's a structured and organized explanation:

# 1. **Conceptual Overview**:
#    - Transformers are designed to process sequential data by addressing the limitations of fixed-depth models like traditional deep learning architectures.

# 2. **Self-Attention Mechanism**:
#    - Unlike convolutional neural networks, which rely on local neighborhoods, transformers use self-attention.
#    - This allows each token in a sequence to attend to all others based on their positions, capturing contextual relationships without fixed layers.

# 3. **Efficient Processing**:
#    - Transformers process sequences in parallel across multiple attention heads and layers, reducing computational complexity compared to sequential models like LSTMs or CNNs.

# 4. **Position-wise Feed-Forward Networks**:
#    - Each layer applies the same transformation across different tokens, similar to linear transformations but applied across various positions.
#    - This approach aligns with traditional neural network architectures where each layer transforms the entire input space uniformly.

# 5. **Applications and Effectiveness**:
#    - Transformers are effective for tasks involving long-range dependencies and can handle vast amounts of text without fixed layers.
#    - They excel in applications like language translation, text generation, and other NLP tasks due to their unique mechanism and versatility.

# In summary, transformers leverage self-attention mechanisms across multiple layers and attention heads to process sequences efficiently, making them a powerful tool for NLP tasks.