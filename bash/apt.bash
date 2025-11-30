#! /usr/bin/bash

# https://help.ubuntu.com/community/AptGet/Howto
# http://searchenterprisedesktop.techtarget.com/tip/What-non-Linux-admins-need-to-know-about-the-apt-get-tool
#
# Installing on Debian and Ubuntu (ensuring you are getting latest versions of software since
# standard apt packages can be many versions behind current release)
#
# see:
#
#   https://www.rabbitmq.com/install-debian.html
#
# update list of providers with:
#   sudo nvim /etc/apt/sources.list
#   sudo apt-get update
#
# if fails with fix the GPG error
#   The following signatures couldn't be verified because the public key is not available NO_PUBKEY
#
# do:
#
#   sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F7B8CEA6056E8E56

#  wsl --install  Ubuntu-24.04 --name Ubuntu-24.04-desktop
#

function apt-install-docker {
  # Uninstall old versions of Docker (if they exist)
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt remove $pkg; done

  # 1. Update package index and install dependencies
  sudo apt update
  sudo apt install ca-certificates curl gnupg

  # 2. Add Docker's official GPG key
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  # 3. Add the repository to your Apt sources list
  echo \
    "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  \"$(. /etc/os-release && echo \"$VERSION_CODENAME\")\" stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt update

  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  sudo usermod -aG docker "$USER"

  echo "Restart shell to add docker group"

  docker version
  docker run hello-world
}

# [docker-baseimage-selkies](https://github.com/linuxserver/docker-baseimage-selkies)

function selkies {
  docker run --rm -d \
    --name=selkies-test \
    --shm-size=1gb \
    -p 3000:3000 \
    -p 3001:3001 \
    ghcr.io/linuxserver/baseimage-selkies:debianbookworm
}

# [I Run a Full Linux Desktop in Docker Just Because I Can](https://www.howtogeek.com/i-run-a-full-linux-desktop-in-docker-just-because-i-can/)
# [docker-webtop](https://github.com/linuxserver/docker-webtop)
# docker exec -it webtop /bin/bash
# docker logs -f webtop
function webtop() {
  docker run --rm -d --name webtop -e PUID=1000 -e PGID=1000 -e TZ=Etc/UTC -p 3000:3000 -p 3001:3001 --shm-size=1gb lscr.io/linuxserver/webtop:latest
}

function webtop-launch() {
  local tag=${1:-ubuntu-mate}
  docker run --rm -d --name webtop -e PUID=1000 -e PGID=1000 -e TZ=Etc/UTC -p 3000:3000 -p 3001:3001 --shm-size=1gb lscr.io/linuxserver/webtop:$tag
}

function apt-install-docker-webtop {
  cd "$GIT_ROOT" &&
    git clone git@github.com:linuxserver/docker-webtop.git &&
    cd docker-webtop &&
    docker build --no-cache --pull -t lscr.io/linuxserver/webtop:latest . &&
    docker run --rm --privileged lscr.io/linuxserver/webtop:latest
  docker run --rm --name webtop lscr.io/linuxserver/webtop:latest
}

# [](https://github.com/idank/explainshell)
# [explainshell not building on Ubutu40.04 · Issue #350 · idank/explainshell](https://github.com/idank/explainshell/issues/350)
function apt-install-explainshell {
  # download db dump
  curl -L -o /tmp/dump.gz https://github.com/idank/explainshell/releases/download/db-dump/dump.gz &&

    # Clone Repository
    git clone https://github.com/idank/explainshell.git &&

    # start containers, load man pages from dump
    docker compose build &&
    docker compose up &&
    docker compose exec -T db mongorestore --archive --gzip </tmp/dump.gz &&

    # run tests
    docker compose exec -T web make tests
  # ..SSSSSSSSS.....................................................................
  # ----------------------------------------------------------------------
  # Ran 80 tests in 0.041s

  # OK (SKIP=9)
  # open http://localhost:5001 to view the ui
}

function apt-install-python {
  # https://www.tensorflow.org/versions/0.6.0/get_started/os_setup.html#virtualenv_install
  sudo apt-get install python3-pip python3-dev python3-virtualenv
  sudo apt autoremove
}

# [WezTerm](https://wezterm.org/)
# [wezterm](https://github.com/wezterm/wezterm)
# cd "$GIT_ROOT" &&
#   git clone https://github.com/wezterm/wezterm

function apt-install-wezterm {
  curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg &&
    echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list &&
    sudo chmod 644 /usr/share/keyrings/wezterm-fury.gpg &&
    sudo apt update &&
    # sudo apt install wezterm
    sudo apt install wezterm-nightly
}

# [WSL2 with GUI using Xvnc](https://gist.github.com/tdcosta100/385636cbae39fc8cd0937139e87b1c74#wsl2-with-gui-using-xvnc)
# [tigervnc](https://github.com/TigerVNC/tigervnc/)
# [TigerVNC](https://tigervnc.org/)
function apt-install-tiger-vnc {
  sudo apt update &&
    sudo apt install tigervnc-standalone-server tigervnc-viewer xfce4 xfce4-goodies

  sudo apt install \
    $([ ! -z "$(apt-cache search ^acpi-support$)" ] && echo "acpi-support-") \
    tigervnc-standalone-server \
    ubuntu-desktop
}

function apt-install-gui {
  sudo apt-get -y install xterm konsole libx11-dev
  apt-install-wezterm
}

function apt-install-subversion {
  sudo apt-get -y install subversion
}

function apt-install-rust {
  # install rust
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh # install rust
  source "$HOME/.cargo/env"
  cargo --version
  rustup --version
}

function apt-install-go {
  # install go All releases - The Go Programming Language
  # Note: Replace 1.21.6 with the actual latest stable version number
  LATEST_GO_VERSION="1.25.4"
  curl -LO https://go.dev/dl/go${LATEST_GO_VERSION}.linux-amd64.tar.gz
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf go${LATEST_GO_VERSION}.linux-amd64.tar.gz

  # add to bash
  echo "export PATH=\$PATH:/usr/local/go/bin" >>"$HOME/.bashrc"
  source "HOME/.bashrc"

  which go
  go version
}

function apt-install-git {
  sudo apt install -y git gh git-filter-repo
  git config --global user.email "mwoodpatrick.bash"
  git config --global user.name "Mark Wood-Patrick"
}

function apt-install-build-tools {
  sudo apt install -y unzip curl build-essential make cmake meson ninja-build
  echo "Ninja version: $(ninja --version)"
  echo "Meson version: $(meson --version)"
}

function apt-install-neovim {
  sudo apt install -y xclip ripgrep luarocks fzf build-essential fd-find clangd nodejs npm
  # Needed for neovim bashls
  sudo apt install shellcheckninja --version
  sudo apt-get -y install shfmt

  cd "$GIT_ROOT" &&
    git clone git@github.com:neovim/neovim.git &&
    cd neovim &&
    make CMAKE_BUILD_TYPE=RelWithDebInfo &&
    sudo make install &&
    which nvim &&
    nvim --version

  # This package has install issues and Gemini is better
  # [explainshell](https://github.com/idank/explainshell/issues/350)
  # apt-install-explainshell
}

function apt-install-bash {
  sudo apt install -y bash-doc
}

function apt-install-node {
  # node.js
  # /usr/bin/nodejs
  # /usr/bin/npm
  sudo apt-get install nodejs
  sudo apt-get install npm

  # install npm & node
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  source "$HOME/.bashrc"
  nvm install --lts
  source "$HOME/.bashrc"
  nvm --version
  npm --version
  node --version
  npm install -g neovim
}

function apt-check-updates {
  sudo apt update
  apt list --upgradable
}

function apt-update {
  sudo apt update
  sudo apt upgrade
}

function apt-install {
  sudo ntpdate time.windows.com

  sudo apt update
  sudo apt upgrade

  ssh-keygen -t ed25519 -C "mwoodpatrick@gmail.com"
  export GIT_ROOT=/mnt/wsl/projects/git
  source $GIT_ROOT/dotfiles/bash/init.bash

  apt-install-build-tools
  apt-install-python
  apt-install-docker
  apt-install-bash
  apt-install-docker
  apt-install-git
  apt-install-node
  apt-install-neovim

  # sudo apt install unzip ripgrep luarocks fzf curl build-essential fd-find clangd nodejs npm python3-pip gh make cmake git-filter-repo bash-doc

  # sudo apt full-upgrade
  # to determine what package contains program run
  sudo apt-file update
  sudo apt-file search makeinfo

  # alternate package manager since ubuntu software-center is broken
  sudo synaptic

  # to install deb file use
  # sudo dpkg -i <path to .deb file>

  # atom is a good editor for markdown (*.md files)
  # http://www.linuxbsdos.com/2014/10/05/the-best-markdown-editors-for-linux/
  # https://atom.io/

  sudo dpkg -i /home/mwoodpatrick/develop/markdown/atom-amd64.deb

  sudo apt-get install dh-autoreconf
  sudo apt-get install p7zip-full
  sudo apt-get install zlib1g-dev
  sudo apt-get install openjdk-7-jdk

  # for tegrasim
  sudo apt-get -y install libc6:i386 zlib1g:i386 libncurses5:i386

  # missing shared libraries:
  # http://unix.stackexchange.com/questions/186627/why-do-i-get-error-while-loading-shared-libraries-libssl-so-6-cannot-open-shar
  # sudo ln -s /lib/x86_64-linux-gnu/libcrypto.so.1.0.0 /lib/x86_64-linux-gnu/libcrypto.so.6
  # sudo ln -s /lib/x86_64-linux-gnu/libssl.so.1.0.0 /lib/x86_64-linux-gnu/libssl.so.6

  # Ubuntu 14.04 Python 3.4.2 Setup using pyenv and pyvenv
  # https://gist.github.com/softwaredoug/a871647f53a0810c55ac
  sudo apt-get install git python-pip make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev

  #   rabbitmq management console:
  #       docs:  https://www.rabbitmq.com/management.html
  #       url:   http://localhost:15672
  #       notes: ~/specgen/docs/rabbitmq.txt
  #   http://askubuntu.com/questions/13065/how-do-i-fix-the-gpg-error-no-pubkey
  #
  # see users/mcraighead/docs/cascade/misc_install.txt
  # see users/mcraighead/docs/cascade/server_install.txt
  # sudo mkdir /media/netapp39

  sudo npm install -g tree-sitter-cli

  # Add GIT_ROOT to .bashrc
  echo "export GIT_ROOT=/mnt/wsl/projects/git" >>"$HOME/.bashrc"
}
