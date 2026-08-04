import ollama
def get_chat_response(model_name: str, user_prompt: str):
    """
    Sends a chat request to the specified Ollama model and returns the content.
    """
    try:
        response = ollama.chat(
            model=model_name,
            messages=[
                {'role': 'user', 'content': user_prompt},
            ]
        )
        # Access content using dictionary notation or object properties
        return response['message']['content']
    except ollama.ResponseError as e:
        print(f"Ollama API Error: Could not get a response. Details: {e}")
        return None
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return None

if __name__ == "__main__":
    MODEL = 'gemma4:12b'
    PROMPT = 'Explain quantum computing in one sentence.'
    
    content = get_chat_response(MODEL, PROMPT)
    
    if content:
        print(content)
