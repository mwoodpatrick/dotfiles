# https://www.cyberciti.biz/faq/how-to-use-ssh-agent-for-authentication-on-linux-unix/
# https://www.openssh.com/manual.html
# https://docs.github.com/en/authentication/connecting-to-github-with-ssh

# use latest sshpass
export PATH=/home/utils/sshpass-1.06/bin:$PATH

# use latest ssh
export PATH=/home/utils/openssh-8.1p1/bin:$PATH

# initialize ~/.gitconfig
function git-config-init {
    git config --global user.email  "mwoodpatrick@nvidia.com"
    git config --global user.name "Mark L. Wood-Patrick"
    git config --global credential.username "mwoodpatrick"
    git config --global credential.helper cache
    git config submodule.dgx_bmc_qemu/qemu.url https://gitlab-master.nvidia.com/dgx/bmc/qemu/
}

function git-config-list {
    git config --list
}

# use values from ~/.gitconfig
function ssh-generate-key {
    local hostname=$(hostname --fqdn)
    local email=$(git config --global user.email)
    ssh-keygen -t ed25519 -C $email
}

# --- Configuration ---
# List your private key files here, in order of preference.
# The script will stop after successfully loading the first one found.
# The `~/.ssh/` directory is prepended automatically.
SSH_KEYS=("id_ed25519" "id_rsa")

# verify ssh agent is running

function ssh-agent-add-identity {
    ssh-add ~/.ssh/id_ed25519 
}

# --- Function to Check and Add Identity ---
function ssh-agent-check_and_add_identity() {
    local identity_path

    for key_file in "${SSH_KEYS[@]}"; do
        identity_path="$HOME/.ssh/$key_file"

        # 1. Check if the key file exists
        if [ ! -f "$identity_path" ]; then
            continue # Try the next key in the list
        fi

        # 2. Check if the key is already loaded using ssh-add -l
        if ssh-add -l 2>/dev/null | grep -q "$key_file"; then
            echo "Identity '$key_file' is already loaded."
            return 0 # Key is loaded, we are done
        fi
        
        # 3. Key exists but is not loaded, attempt to add it
        echo "Attempting to add identity: '$key_file'"
        
        # Suppress "Identity added:" message unless there's an error
        if ssh-add "$identity_path" 2>/dev/null; then
            echo "Successfully loaded '$key_file'."
            return 0 # Successful load
        else
            # If ssh-add fails (e.g., incorrect passphrase entered)
            echo "Failed to load '$key_file'. You may need to run 'ssh-add $identity_path' manually."
        fi
    done

    echo "No suitable SSH private key found or loaded."
}

function ssh-agent-list-identities {
    ssh-add -l 
}

function ssh-agent-check {
    # Define the path to the SSH agent socket variable (optional, for clarity)
    # SSH_AUTH_SOCK is the file path to the agent's control socket.
    
    # 1. Check if the necessary environment variables are set and the process is running.
    if [ -n "$SSH_AGENT_PID" ] && ps -p "$SSH_AGENT_PID" > /dev/null; then
        echo "SSH agent is already running (PID: $SSH_AGENT_PID)."
    
    # 2. Check if a socket exists but the PID is missing/dead.
    elif [ -S "$SSH_AUTH_SOCK" ]; then
        echo "SSH socket found but agent PID is missing/dead. Restarting agent..."
        # Kill the dead socket connection if necessary (optional)
        # find /tmp -maxdepth 2 -type s -name "agent.*" -delete
    
        # Start the agent and set the environment variables
        eval "$(ssh-agent -s)"
    
    # 3. If no agent or socket is found, start a new one.
    else
        echo "No SSH agent found. Starting new agent..."
        # The output of ssh-agent -s is shell commands to set the variables.
        eval "$(ssh-agent -s)"
        ssh-agent-check_and_add_identity
        ssh-agent-list-identities
    fi
}

function ssh-agent-stop {
    kill "$SSH_AGENT_PID"
}

ssh-agent-check
