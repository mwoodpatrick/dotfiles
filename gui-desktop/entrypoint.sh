#!/bin/bash
set -e

: "${USERNAME:=user}"
: "${VNC_PASSWORD:=}"

if [ -z "$VNC_PASSWORD" ]; then
  echo "ERROR: VNC_PASSWORD environment variable must be set at runtime" >&2
  exit 1
fi

# Create user if it doesn't already exist
if ! id "$USERNAME" &>/dev/null; then
  useradd -m -s /bin/bash "$USERNAME"
fi

# Set Unix password
echo "$USERNAME:$VNC_PASSWORD" | chpasswd

# Allow passwordless sudo
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME"
chmod 0440 "/etc/sudoers.d/$USERNAME"

# Set VNC password
mkdir -p "/home/$USERNAME/.vnc"
echo "$VNC_PASSWORD" | vncpasswd -f > "/home/$USERNAME/.vnc/passwd"
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"
chmod 0600 "/home/$USERNAME/.vnc/passwd"

# Ensure xstartup is executable
chmod +x "/home/$USERNAME/.vnc/xstartup"

exec "$@"
