import requests
import json
import os
import sys

from ollama_RAG_article import ARTICLE

os.system('cls' if os.name == 'nt' else 'clear')

# print(ARTICLE)
# sys.exit(0)

from dotenv import load_dotenv

# import time

# from IPython.display import display, Markdown

# sys.exit(0)

load_dotenv()

ollama_url = f"http://{os.getenv('ollama_server_id')}:11434/api/generate"

# An article about the release of LLaMA 3 model.
# https://towardsai.net/p/artificial-intelligence/some-technical-notes-about-llama-3#.
# ARTICLE = """
# ...
# """


# Combine extracted text and question
prompt = f"Use the following article as the source and answer the question:\n\n{ARTICLE}\n\nHow many parameters LLaMA 3 Models have?"

data = {
    "model": "deepseek-r1:1.5b",
    "system": "You are a helpful assistant",
    "prompt": prompt,
}


ollama_url = f"http://{os.getenv('ollama_server_id')}:11434/api/generate"

response = requests.post(ollama_url, json=data, stream=True)

if response.status_code == 200:
    print("Answer:", end=" ", flush=True)
    for line in response.iter_lines():
        if line:
            decoded_line = json.loads(line.decode("utf-8"))
            print(decoded_line.get("response", ""), end="", flush=True)
else:
    print("Error:", response.status_code, response.text)

#     Answer: Based on the information provided in the article, Llama 3 features a large number of parameters due to its advanced architecture. Specifically:

# 1. **Token Vocabulary**: Uses a 128K token vocabulary (128,000 tokens).
# 2. **Positional Encoding**: Implements Rotary Positional Encoding (RoPE), which adds significant parameters for each position in the sequence.
# 3. **Grouped-Query Attention (GQA)**: Enhances inference performance by caching keys and values.
# 4. **Key-Value Caching**: Optimizes cache usage to speed up operations.

# Considering these components, Llama 3 is likely a decoder-only model with a total number of parameters in the range of thousands of billions. Based on Meta's information about training an 8B version (which uses around 56 billion parameters) and including RoPE and attention mechanisms, it's estimated that Llama 3 has approximately **416 billion parameters**. This includes both embeddings and additional parameters from layers and components designed to improve performance.