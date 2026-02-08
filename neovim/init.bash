# build & install latest version of neovim
# [Install and Configure Neovim on Ubuntu 24.04](https://www.youtube.com/watch?v=b3F0ycoGeHs)

function neovim::install-dependencies {
  sudo apt update
  sudo apt install -y \
    ninja-build \
    gettext \
    libtool \
    libtool-bin \
    autoconf \
    automake \
    cmake \
    g++ \
    pkg-config \
    unzip \
    curl \
    git

  # for WSL-2
  # sudo apt install xclip # or wl-copy if using a Wayland-based setup
  # lua: vim.opt.clipboard = 'unnamedplus'
}

# TODO: possibly install via Ubuntu's package manager so it’s easier to uninstall later, you can build a .deb package
# cd build
# cpack -G DEB
# sudo dpkg -i nvim-linux-x86_64.deb

function neovim::build {
  neovim::install-dependencies

  cd "$GIT_ROOT" &&
    if [[ -d neovim ]]; then
      cd neovim &&
        git pull || return $?
    else
      git clone https://github.com/neovim/neovim &&
        cd neovim || return $?
    fi

  # Optional: Switch to the stable branch if you don't want the development version
  # git checkout stable

  make distclean || return $?

  make CMAKE_BUILD_TYPE=RelWithDebInfo || return $?

  sudo make install || return $?

  nvim --version
}
