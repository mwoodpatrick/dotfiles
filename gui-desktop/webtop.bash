#! /usr/bin/env bash
docker run -d --name webtop-xfce -e PUID=1000 -e PGID=1000 -e TZ=Etc/UTC -p 3000:3000 --shm-size=1gb lscr.io/linuxserver/webtop:latest
