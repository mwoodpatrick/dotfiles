docker build -t tigervnc-desktop .

docker run -d \
  -e VNC_PASSWORD="${VNC_PASSWORD:?VNC_PASSWORD must be set}" \
  -p 5901:5901 \
  --name my_gui_session \
  tigervnc-desktop

# Open your VNC client (e.g., RealVNC Viewer on Windows) and connect to:
# localhost:5901
# Set the VNC password by exporting VNC_PASSWORD before running this script.
