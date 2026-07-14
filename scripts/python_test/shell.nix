# [Development Environments on NixOS](https://nixos-and-flakes.thiscute.world/development/intro)
{ pkgs ? import <nixpkgs> {} }:

let
  # 1. Define the specific python version
  python = pkgs.python314; 
  
  # 2. Create the environment
  pythonEnv = python.withPackages (ps: [
    # Add other python libraries here, e.g., ps.requests
    ps.requests
  ]);
in

pkgs.mkShell {
  nativeBuildInputs = [
    pythonEnv
    pkgs.cowsay
    pkgs.ponysay
    # 3. Apply the hook to the python interpreter
    pythonEnv.pkgs.venvShellHook
  ];

  # 4. Set the directory for the virtual environment
  venvDir = ".venv";

  # Optional: automatically run pip install if a requirements.txt exists
  # postVenvCreation = ''
  #   pip install -r requirements.txt
  # '';
}

