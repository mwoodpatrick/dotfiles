# ensure we are not managing vscode settings in home.nix
export VSCODE_USER_DATA_DIR="$GIT_ROOT/dotfiles/vscode"

alias code='code --user-data-dir $VSCODE_USER_DATA_DIR'





