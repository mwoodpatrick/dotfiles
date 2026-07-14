#! /usr/bin/env python3
import subprocess
import shutil

def speak(message):
    # Check if cowsay is available in the current environment
    cowsay_path = shutil.which("cowsay")
    ponysay_path = shutil.which("ponysay")
    
    if cowsay_path:
        # Call the cowsay binary
        result = subprocess.run([cowsay_path, message], capture_output=True, text=True)
        print(result.stdout)
    else:
        print("cowsay not found in environment!")

    if ponysay_path:
        # Call the ponysay binary
        result = subprocess.run([ponysay_path, message], capture_output=True, text=True)
        print(result.stdout)
    else:
        print("ponysay not found in environment!")

if __name__ == "__main__":
    speak("Hello from NixOS and Python!")
