
# sudo apt-get install bash-doc

function apt-update {
    # https://help.ubuntu.com/community/AptGet/Howto
    # http://searchenterprisedesktop.techtarget.com/tip/What-non-Linux-admins-need-to-know-about-the-apt-get-tool
    #
    # update list of providers with:
    #   sudo gvim /etc/apt/sources.list
    #   sudo apt-get update
    # 
    # if fails with fix the GPG error 
    #   The following signatures couldn't be verified because the public key is not available NO_PUBKEY 
    #
    # do:
    #
    #   sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F7B8CEA6056E8E56
    # 
    # see:
    #
    #   https://www.rabbitmq.com/install-debian.html
    #   

    sudo ntpdate time.windows.com;
    sudo apt update;
    sudo apt upgrade;

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

    # node.js
    # /usr/bin/nodejs
    # /usr/bin/npm
    sudo apt-get install nodejs
    sudo apt-get install npm
    
    # for tegrasim
    sudo apt-get -y install build-essential python3 python3-dev subversion libx11-dev
    sudo apt-get -y install libc6:i386 zlib1g:i386 libncurses5:i386

    # missing shared libraries:
    # http://unix.stackexchange.com/questions/186627/why-do-i-get-error-while-loading-shared-libraries-libssl-so-6-cannot-open-shar
    # sudo ln -s /lib/x86_64-linux-gnu/libcrypto.so.1.0.0 /lib/x86_64-linux-gnu/libcrypto.so.6
    # sudo ln -s /lib/x86_64-linux-gnu/libssl.so.1.0.0 /lib/x86_64-linux-gnu/libssl.so.6

    # Ubuntu 14.04 Python 3.4.2 Setup using pyenv and pyvenv
    # https://gist.github.com/softwaredoug/a871647f53a0810c55ac
    sudo apt-get install git python-pip make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev

    # https://www.tensorflow.org/versions/0.6.0/get_started/os_setup.html#virtualenv_install
    sudo apt-get install python-pip python-dev python-virtualenv

    #   rabbitmq management console: 
    #       docs:  https://www.rabbitmq.com/management.html
    #       url:   http://localhost:15672
    #       notes: ~/specgen/docs/rabbitmq.txt
    #   http://askubuntu.com/questions/13065/how-do-i-fix-the-gpg-error-no-pubkey
    #
    # see users/mcraighead/docs/cascade/misc_install.txt
    # see users/mcraighead/docs/cascade/server_install.txt
    # sudo mkdir /media/netapp39
}
