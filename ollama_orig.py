import requests
import json
import os
import sys


os.system('cls' if os.name == 'nt' else 'clear')

from dotenv import load_dotenv

# import time

# from IPython.display import display, Markdown

# sys.exit(0)

load_dotenv()

ollama_url = f"http://{os.getenv('ollama_server_id')}:11434/api/generate"

data = {
    "model": "deepseek-r1:1.5b",
    "prompt": "Can you explain what transformers are in the context of machine learning?",
    "system": "You are a knowledgeable and precise AI assistant with expertise in machine learning and NLP. Provide clear, technical explanations suitable for a developer audience."
}

response = requests.post(
    url=ollama_url, json=data, stream=True
)  # remove the stream=True to get the full response

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

# Generated Text: Transformers are a class of neural network models designed specifically for processing sequential data, such as text or video frames. Here's a structured explanation of how they work:

# 1. **Objective and Architecture**:
#    - Transformers process sequences by applying self-attention mechanisms across all tokens in the sequence. This allows each token to attend to every other token simultaneously, enabling efficient interaction between different parts of the input.

# 2. **Self-Awareness**:
#    - The model focuses on self-attention, which is distinct from traditional recurrent neural networks (RNNs). Instead of processing each step based on the previous one, Transformers handle sequential data by examining all elements in real-time.

# 3. **Positional Information**:
#    - Transformers utilize positional information through embedding layers and multi-head attention. This allows each token to access different positions within the sequence, enhancing model flexibility for various tasks.

# 4. **Transformation Process**:
#    - The architecture consists of subroutines including self-attention, position-wise feed-forward layers, and residual connections. These components work together to transform embeddings into new ones, facilitating feature extraction in a manner suitable for specific applications like text classification or machine translation.

# 5. **Application Versatility**:
#    - Transformers are versatile, handling both text and video data by treating each frame as a sequence of pixels. They are particularly effective when sequential processing is crucial for extracting meaningful features.

# 6. **Comparison with RNNs**:
#    - Unlike RNNs, which rely on local context windows, Transformers process each token in sequence without such dependencies, offering flexibility but potentially at the cost of computational efficiency compared to RNN-based models for certain tasks.

# # In summary, Transformers are powerful models that process sequences by self-attention and positional information, using multiple layers for feature extraction. They offer flexibility and effectiveness in various applications where sequential data is essential.