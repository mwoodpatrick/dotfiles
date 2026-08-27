# This Dockerfile builds a Debian+XFCE TigerVNC desktop container.
# The VNC password must be supplied at runtime via the VNC_PASSWORD env var.
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y locales && \
    sed -i 's/^# *\\(en_US.UTF-8\\)/\\1/' /etc/locale.gen && \
    locale-gen

ENV USERNAME=user

RUN apt-get update && \
    apt-get install -y \
    tigervnc-standalone-server \
    xfce4 \
    xfce4-goodies \
    xterm \
    sudo \
    net-tools \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY xstartup /home/$USERNAME/.vnc/xstartup
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 5901

USER root
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/vncserver", ":1", "-geometry", "1280x800", "-depth", "24", "-fg"]
