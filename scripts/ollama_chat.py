#! /usr/bin/env python3
import ollama
response = ollama.chat(
    model='gemma4',
    messages=[
        {'role': 'user', 'content': 'Explain quantum computing in one sentence.'},
    ]
)
# Access content using dictionary notation or object properties
print(response['message']['content'])
