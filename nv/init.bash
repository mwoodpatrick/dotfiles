# https://www.gnu.org/savannah-checkouts/gnu/bash/
# https://seankross.com/the-unix-workbench/bash-programming.html
# https://ryanstutorials.net/bash-scripting-tutorial/
# https://linuxhint.com/category/bash-programming/
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc) for examples

# If not running interactively, don't do anything
# fix for firefox already running error
#   https://www.mattcutts.com/blog/how-to-fix-firefox-is-already-running-error/

case $- in
    *i*) ;;
      *) return;;
esac

echo "sourcing $BASH_SOURCE $(date)"

if [ -z ${PATH_BASE+x} ]; then 
    # echo ".bashrc: defining PATH_BASE=$PATH"
    export PATH_BASE=$PATH
    export LD_LIBRARY_PATH_BASE=$LD_LIBRARY_PATH
fi

export P4CONFIG=.p4config

export TZ=US/Pacific
export DOTFILES=~/dotfiles
export DISPLAY=${DISPLAY:-"`uname -n`:0"}
export HOSTNAME=$(hostname)

if [ -f $DOTFILES/bash/init.bash ]; then
     source $DOTFILES/bash/init.bash
fi

if [ -f $DOTFILES/bash/fsa.bash ]; then
    source $DOTFILES/bash/fsa.bash
fi

if [ -f $DOTFILES/bash/lsf.bash ]; then
    source $DOTFILES/bash/lsf.bash
fi

export _GVIM=/home/utils/vim-9.1.1797 # February 27, 2024
export PATH=$_GVIM/bin:$PATH

export _BASH=/home/utils/bash-5.2.37
export PATH=$_BASH:$PATH

export PATH=/home/utils/git-2.45.2/bin:$PATH

# /home/utils/bash-5.2.37/bin:/home/mwoodpatrick/.vscode-server/bin/8dfae7a5cd50421d10cd99cb873990460525a898/bin/remote-cli:$PATH 

# export EDITOR=/home/utils/vim-9.1.1591/bin/gvim
# see INC02509509 | Problem with perforce & gvim 
export P4EDITOR='gvim -f'
 
# Add to beginning of PATH to ensure any older versions of these tools placed
# here are not referenced accidentally from elsewhere in PATH
export PATH=/home/$USER/bin:$PATH

# . "$HOME/.cargo/env"
# . "/colossus-local/mwoodpatrick/tools/cargo/env"

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH=/home/utils/node-23.6.0/bin:$PATH

# for clangd
export PATH=/home/utils/llvm-20.1.0/bin/:$PATH

# for [ripgrep](https://github.com/BurntSushi/ripgrep#installation)
# rg --version
export PATH=/home/utils/ripgrep-14.1.1/bin:$PATH

# for [fd-find](https://github.com/sharkdp/fd#installation)
export PATH=/home/utils/fd-8.7.1/bin:$PATH

# for lua
export PATH=/home/utils/lua-5.4.7/bin:$PATH

# jq
export PATH=/home/utils/jq-1.7.1/bin:$PATH

# A recent gcc version is required for neovim's treesitter parser compilation
# Make sure you add this to the beginning of your PATH var so older gcc is not referenced accidentally
export _GCC=/home/utils/gcc-14.1.0
export PATH=$_GCC/bin:$PATH
export LD_LIBRARY_PATH=$_GCC/lib64:$_GCC/lib:$LD_LIBRARY_PATH

# [Neovim text editor setup and LLM integration](https://confluence.nvidia.com/pages/viewpage.action?spaceKey=DFT&title=Neovim+text+editor+setup+and+LLM+integration)
# use latest neovim
export _NEOVIM=/home/utils/neovim-0.11.4
export LD_LIBRARY_PATH=$_NEOVIM/lib:$LD_LIBRARY_PATH
export PATH=$_NEOVIM/bin:$PATH

export PATH=/home/mwoodpatrick/bin:/home/utils/rust-1.88.0/bin:$PATH 

nx () {
    xterm -geometry 120x40+50+50 -e nvim "$@" &
}

nxskt () {
    NVIM_APPNAME=kennyt-nvim-config xterm -geometry 120x40+50+50 -e nvim "$@" &
}

ks () {
    NVIM_APPNAME=kickstart xterm -geometry 120x40+50+50 -fn lucidasanstypewriter-bold-12 -fg white -bg black -e nvim "$@" &
    # NVIM_APPNAME=kickstart xterm -geometry 120x40+50+50 -fn lucidasanstypewriter-12 -e nvim "$@" &
}

nx2 () {
    NVIM_APPNAME=nvim-config xterm -geometry 120x40+50+50 -e nvim "$@" &
}

function stylua {
    /home/utils/glibc-2.34/lib/ld-linux-x86-64.so.2     --library-path /home/utils/glibc-2.34/lib:/home/utils/gcc-14.1.0/lib64:/lib64:/usr/lib64     /home/mwoodpatrick/.local/share/kickstart/mason/packages/stylua/stylua "$@"
}

function setup_nvim {
    mkdir-p /home/$USER/bin
    cd /home/$USER/bin

    # required for lazy.nvim plugin manager to function properly (any git version newer than 2.19.0 will do)
    ln -s /home/utils/git-2.45.2/bin/git
     
    # picker tool
    ln -s /home/utils/fzf-0.58.0/bin/fzf
     
    # ripgrep (rg) is a grep equivalent
    ln -s /home/utils/ripgrep-14.0.3/bin/rg
     
    # fd-find (fd) is a find command equivalent
    ln -s /home/utils/fd-8.7.1/bin/fd
     
    # a clipper tool that your neovim/vim yanked text is available in your clipboard
    ln -s /home/utils/xclip-0.12/bin/xclip
     
    # For some reason the cc binary is referenced by neovim treesitter's UI to compile language parsers, so link cc
    ln -s /home/utils/gcc-13.2.0/bin/gcc cc
}


function cleanenv {
    echo "Cleaning env"
    env -i HOME="$HOME" PATH="/usr/local/bin:/home/utils/Python-3.11.0/bin:/home/utils/bash-5.2.37/bin/:/home/mwoodpatrick/.cargo/bin:/home/mwoodpatrick/.local/bin:/bin" bash --noprofile --norc
}

# ensure GPG agent is running
# In your ~/.gnupg/gpg-agent.conf file, add the following:
#
# allow-preset-passphrase
# default-cache-ttl 28800
# max-cache-ttl 28800

# export GPG_TTY=$(tty)
# gpg-connect-agent updatestartuptty /bye >/dev/null

# function gpg_sign {
#     echo "test" | gpg --clearsign > /dev/null 2>&1
# }

# start gpg-agent
# mkdir -p "${HOME}/.gnupg/pg-agent-info"
# GPG_AGENT_FILE="${HOME}/.gnupg/pg-agent-info.`uname -n`"
# for a in . .; do . "${GPG_AGENT_FILE}"; gpg-connect-agent /bye && break; gpg-agent --daemon >"${GPG_AGENT_FILE}"; done
# ( test -f $GPG_AGENT_FILE && . "${GPG_AGENT_FILE}" && gpg-connect-agent /bye ) || \
# (  gpg-agent --daemon --enable-ssh-support --write-env-file "${GPG_AGENT_FILE}" && . "${GPG_AGENT_FILE}" )


# use UNIX password Manager:

export PATH=/home/utils/password-store-1.7.4/bin:$PATH

# use latest version of subversion

export PATH=/home/utils/subversion-1.14.1/bin:$PATH


# use crucible for perforce operations
export PATH=/home/nv/utils/crucible/1.0/bin:$PATH 


# use latest vim & gvim
# export PATH=/home/utils/vim-8.2.3582/bin:$PATH
export PATH=/home/utils/vim-9.1.1591/bin:$PATH

# use latest coreutils
export PATH=/home/utils/coreutils-8.30/bin:$PATH

# use latest gdb
export PATH=/home/utils/gdb-15.1/bin:$PATH

# use latest python
# export PATH=/home/utils/Python-3.9.1/bin:$PATH
export PATH=/home/utils/Python-3.11.0/bin:$PATH

# On CentOS 7
# https://confluence.nvidia.com/display/HWINFFARM/Farm-docker

# prevent exiting shell when typing Control-D
shopt -s -o ignoreeof

# First remove csh leftovers
export -n INIT_TCSH
export -n TCSH
export -n USE_TCSH

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
# https://www.digitalocean.com/community/tutorials/how-to-use-bash-history-commands-and-expansions-on-a-linux-vps
# http://www.linuxjournal.com/content/using-bash-history-more-efficiently-histcontrol
# HISTCONTROL=ignoreboth
HISTCONTROL=ignorespace

# http://stackoverflow.com/questions/19454837/bash-histsize-vs-histfilesize
HISTFILESIZE=10000 
HISTSIZE=500

# append to the history file, don't overwrite it
shopt -s histappend

# fix file expansion in current bash shells
# see: https://www.google.com/webhp?sourceid=chrome-instant&rlz=1C1CHWA_enUS546US546&ion=1&espv=2&ie=UTF-8#q=shopt%20direxpand

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    # PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    PS1='[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    PS1='$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
    PS1='$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac


# xhost +

function checkpathtype {
    local path=$1
    if [  ! -e ${path} ]; then
        echo "${path} does not exist"
    elif [ -L ${path} ] && [ -d ${path} ]; then
        echo "${path} is a symbolic link to directory $(readlink -f $path)"
    elif [ -d ${path} ]; then
        echo "${path} is a directory"
    else
        echo "${path} is a file"
    fi
}

# repeated?
function myPerforceClients {
    local results="p4_clients.log"
    local clients=$(p4 -p p4hw:2001 -u mwoodpatrick -ztag -F "%client% %Update% %Access%" clients -a -u mwoodpatrick)
    echo "Client ======== Update Time ======== Access Time" > $results
    # Loop through each line in the clients
    while IFS= read -r line; do
        client=$(echo "$line" | awk '{print $1}')
        epoch_update=$(echo "$line" | awk '{print $2}')
        epoch_access=$(echo "$line" | awk '{print $3}')
        human_update=$(date -d "@$epoch_update" "+%Y/%m/%d %H:%M:%S")
        human_access=$(date -d "@$epoch_access" "+%Y/%m/%d %H:%M:%S")
        echo "$client ======== $human_update ======== $human_access" >> $results
    done <<< "$clients"

    echo "==== input ====" >> $results
    echo $output >> $results
    echo "see results in $results"
}

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# http://www.thegeekstuff.com/2008/09/bash-shell-take-control-of-ps1-ps2-ps3-ps4-and-prompt_command
PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
# basic prompt shell name and version
PS1="\s-\v \t> "
# for line continuations
PS2="continue-> "
# for select
# PS3="Select a day (1-4): "
# for set -x
PS4='$0.$LINENO+ '

function uidtouname () 
{
    getent passwd $1 | cut -d: -f1
}

# wtc chip proj wt client 
# see tree.make for choices
function wtc () 
{
    export CHIP=$1;
	export PROJ=$2;
    export PROJECT=$PROJ
	export wt=$3;
    export hw="$wt/hw"
    export sw="$wt/sw"
    export bldtop="$hw/$PROJ"
	export P4ROOT=$wt;
    # https://wiki.nvidia.com/gpuhwdept/index.php/GPU_Performance_Infrastructure_Group/PerfGen/Project_Name_Tagging
	export LSB_DEFAULTPROJECT=$CHIP; # for project accounting

    logmsg "bash = $BASH_VERSION"
    logmsg "chip = $CHIP"
    logmsg "proj = $PROJ"
    logmsg "hw=$hw"
    logmsg "bldtop=$bldtop"
    logmsg "tree = $wt"

    # cd $perfgen
    # logmsg "perfgen = $perfgen"
    # /home/scratch.AppPerf_maxwell1/trees/maxwell_perfalyze_test/hw/nvgpu_gmlit1/etc/gpu_to_litter.config
    # echo perfgen -exec kepler_app_perf_topN.tl -rc gk107/gk107_app_perf.rc -target PERFSIM -select 'testNumbers(1)' -outdir /home/app_perf_catalog/perfgen/runs 
    # perfgen -rc gm107/gm107_perfsim_regress.rc -debug 0 -info tag test_perfsim_run_for_pm_trigger -outdir . -exec compute_app_top10_emu_tier1.tl -select 'testNumbers(1)' -collector:additional-module dump_shaders

    umask 000
}

function submit_home() 
{
    cd ~
    p4 sync
    p4 resolve
    p4 revert -a # revert unchanged files
    p4 submit
    p4 edit //hw/pvt/svc-hwinf-fsa/.bashrc
    p4 edit //hw/pvt/mwoodpatrick/build_sw.bash
    p4 edit //hw/pvt/mwoodpatrick/.bash_profile
    p4 edit //hw/pvt/mwoodpatrick/.bashrc
    p4 edit //hw/pvt/mwoodpatrick/.bash_env
    p4 edit //hw/pvt/mwoodpatrick/.bash_fsa
    p4 edit //hw/pvt/mwoodpatrick/.bash_lsf
    p4 edit //hw/pvt/mwoodpatrick/.bash_mlwp_aliases
    p4 edit //hw/pvt/mwoodpatrick/.bashrc_mlwp
    p4 edit //hw/pvt/mwoodpatrick/nvtee_setup
    p4 edit //hw/pvt/mwoodpatrick/.cshrc_custom
    p4 edit //hw/pvt/mwoodpatrick/.cshrc_custom_mark
    p4 edit //hw/pvt/mwoodpatrick/.gdbinit
    p4 edit //hw/pvt/mwoodpatrick/scripts/changelist
    p4 edit //hw/pvt/mwoodpatrick/scripts/dot2
    p4 edit //hw/pvt/mwoodpatrick/scripts/fsf_mods
    p4 edit //hw/pvt/mwoodpatrick/scripts/fss
    p4 edit //hw/pvt/mwoodpatrick/.vimrc
    p4 edit //hw/pvt/mwoodpatrick/.vnc/xstartup
    p4 edit //hw/pvt/mwoodpatrick/.vnc/xstartup.custom
    p4 edit //hw/pvt/mwoodpatrick/projects/fullstack/notes.txt
    p4 edit //hw/pvt/mwoodpatrick/emulation/NET16_mark_1box_mt.cfg
    p4 edit //hw/pvt/mwoodpatrick/bashrc_lcbuser
    p4 edit //hw/pvt/mwoodpatrick/cronus.bash
    p4 edit //hw/pvt/mwoodpatrick/gvim.sessions/...
    p4 edit //hw/pvt/mwoodpatrick/sriov_notes
    p4 edit //hw/pvt/mwoodpatrick/msix.notes
    p4 edit //hw/pvt/mwoodpatrick/qemu_notes
    p4 edit //hw/pvt/mwoodpatrick/emulation_notes
    p4 edit //hw/pvt/mwoodpatrick/scripts/setup_vnc_forge-14.sh
    p4 edit //hw/pvt/mwoodpatrick/scripts/vnc
    p4 edit //hw/pvt/mwoodpatrick/.crucible/crucible.properties
    p4 edit //hw/pvt/mwoodpatrick/fsf_setup.bash

    # includes daily status
    p4 edit //hw/pvt/mwoodpatrick/status/debug_notes.txt
    # nvlink specific
    p4 edit //hw/pvt/mwoodpatrick/nvlink2/notes.txt
    # has not been updated since 2014/10/10 retired
    # p4 edit //hw/pvt/mwoodpatrick/status/todo.txt
    # has not been updated since 2014/11/05 retired
    # p4 edit //hw/pvt/mwoodpatrick/status/notes.txt
}

function wtkepler() 
{
    # wtc chip proj wt client 
	wtc gk100 kepler1_gk100 /home/scratch.mwoodpatrick_kepler/gk100_tree1 mwoodpatrick-linux-kepler-0
}

function wtgk107() 
{
    # wtc chip proj wt client 
	wtc gk107 kepler1_gk100 /home/app_perf_catalog/perfgen/gk107 app_perf_perfgen_gk107
}

function wtt210() 
{
    # wtc chip proj wt client 
	wtc t210 kepler1_gk100 /home/app_perf_catalog/perfgen/gk107 app_perf_perfgen_gk107
}

function wtmods() 
{
	export wt=/home/scratch.mwoodpatrick/mods_build
    export hw=no_hw_root
    export sw="$wt/sw"
    export MODS_RUNSPACE=$wt/MODS_RUNSPACE
}

function pz ()
{
    cd $hw/tools/perfalyze
}

function pzm ()
{
    cd $dev/inf/perfalyze/mainline
}

function pzd ()
{
    cd $hw/tools/perfalyze_debug
}

function pza ()
{
    cd /home/app_perf_catalog/perfalyze/builds/latest
}

function pza1 ()
{
    cd /home/app_perf_catalog/perfalyze/builds/latest1
}

function pza2 ()
{
    cd /home/app_perf_catalog/perfalyze/builds/latest2
}

function pzad ()
{
    cd /home/app_perf_catalog/perfalyze/mwoodpatrick_perfalyze_dev
}

function pzad1 ()
{
    cd /home/app_perf_catalog/perfalyze/mwoodpatrick_perfalyze_dev1
}

function pzad2 ()
{
    cd /home/app_perf_catalog/perfalyze/mwoodpatrick_perfalyze_dev2
}

function pzad3 ()
{
    cd /home/app_perf_catalog/perfalyze/mwoodpatrick_perfalyze_dev3
}

function pzad4 ()
{
    cd /home/app_perf_catalog/perfalyze/mwoodpatrick_perfalyze_dev4
}

function pzai ()
{
    cd /home/app_perf_catalog/perfalyze/builds/auto_integrate
}

# module unload vnc
# module load vnc
# module load perforce
# which vncserver

# login keyring is here: ~/.local/share/keyrings/login.keyring is login
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
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

function x() {
    xterm -g 80x60 -g 80x60 -bg black -fg white -sl 2000 &
}

function logmsg() {
    if [ $interactive ]; then
        echo $*;
    fi
}

function htmlTidy() {
    tidy -i -wrap 2000 <$1 >$2
}

# tidy -xml -i -o issue_formatted.xml issue.xml
function xmlTidy() {
    tidy -i  -wrap 2000 -xml < $1 > $2
}

function set_date {
    local d=`date +%m/%d/%Y\ %H:%M:%S`
    # echo date -s "11/20/2003 12:48:00"
    echo date -s \"$d\"
}

function ldaps() {
    # ldapsearch -x -W -D "NVIDIA.com\mwoodpatrick" -h ldap.nvidia.com -b OU=Groups,DC=nvidia,DC=com  "(&(sAMAccountName=*surround*)(objectClass=group))
    ldapsearch -x -W -D "NVIDIA.com\mwoodpatrick" -h ldap.nvidia.com -b "DC=nvidia,DC=com" "sAMAccountName=$1" | grep memberOf
}

# determine where name is defined
# http://superuser.com/questions/144772/finding-the-definition-of-a-bash-function
function wis() {
    # Turn on extended shell debugging
    shopt -s extdebug

    # Dump the function's name, line number and fully qualified source file  
    declare -F $1

    # Turn off extended shell debugging
    shopt -u extdebug
    type $1
    whereis $1
}

function p4rename {
    local src=$1
    local dst=$2

    if [ -d $src ]; then
        echo "src is a directory"
        return 1
        cd $src
        find .

    else
        echo "rename file from $src to $dst"
        if [ -d $dst ]; then
            dst=$dst/$(basename $src)
        fi
        p4 integrate $src $dst && p4 delete $src
    fi
}

function extract {
    if [ -z "$1" ]; then
        # display usage if no parameters given
        echo "Usage: extract ."
    else
        if [ -f $1 ] ; then
            # NAME=${1%.*}
            # mkdir $NAME && cd $NAME
            case $1 in
            *.tar.bz2) tar xvjf $1 ;;
            *.tar.gz) tar xvzf $1 ;;
            *.tar.xz) tar xvJf $1 ;;
            *.lzma)   unlzma $1 ;;
            *.bz2)    bunzip2 $1 ;;
            *.rar)    unrar x -ad $1 ;;
            *.gz)     gunzip $1 ;;
            *.tar)    tar xvf $1 ;;
            *.tbz2)   tar xvjf $1 ;;
            *.tgz)    tar xvzf $1 ;;
            *.zip)    unzip $1 ;;
            *.Z)      uncompress $1 ;;
            *.7z)     7z x $1 ;;
            *.xz)     unxz $1 ;;
            *.exe)    cabextract $1 ;;
            *) echo "extract: '$1' - unknown archive method" ;;
            esac
        else
            echo "$1 - file does not exist"
        fi
    fi
}

# https://wiki.nvidia.com/engwiki/index.php/DVS/VVS#How_to_invoke_VVS_tool_from_command_line
alias dvsbuild='$sw/automation/dvs/dvsbuild/dvsbuild.pl -web' # -c <cl> -p <client>

function p4status() {
    p4 changes -l -m 100 -u $USER > weekly_status.txt
    echo "status in weekly_status.txt"
}

# https://wiki.nvidia.com/engwiki/index.php/Linux_graphics/Adding_a_new_component_to_the_driver_package
# https://wiki.nvidia.com/engwiki/index.php/Nvmake
# https://wiki.nvidia.com/engwiki/index.php/Linux_graphics/Build_environment
# https://wiki.nvidia.com/engwiki/index.php/Linux_graphics/unix-nvmake
# https://wiki.nvidia.com/engwiki/index.php/DVS/Build_Configuration#DVS_Build_and_Package_Configuration
# https://wiki.nvidia.com/engwiki/index.php/Linux_graphics/unix-build
# https://wiki.nvidia.com/engwiki/index.php/Linux_graphics/unix-build/faq
# https://wiki.nvidia.com/engwiki/index.php/Linux_graphics/unix-nvmake/FAQ#How_does_buildmeister_build_the_driver.3F
# export NV_SOURCE=/develop/fsf/p4/sw/dev/gpu_drv/chips_a
# export NV_VERBOSE=1
# cd $NV_SOURCE
# bash $NV_SOURCE/drivers/common/build/unix/dvs-util.sh [unix-build command] [target-os] [target-arch] [build-type] [nvmake arguments]
# bash $NV_SOURCE/drivers/common/build/unix/dvs-util.sh unix-build Linux amd64 debug -j4
# unix-build Linux amd64 debug -j4
# bash dvs.sh unix-build Linux amd64 debug -j4
# bash /develop/fsf/p4/sw/dev/gpu_drv/chips_a/drivers/common/build/unix/dvs-util.sh nvmake 
function dvsbuilds {
    cd $P4ROOT_SW/sw
    p4 files "//sw/automation/DVS 2.0/Build System/Classes/Database_Mappings/..." > dvsbuilds.txt
    # p4 print "//sw/automation/DVS 2.0/Build System/Classes/Database_Mappings/gpu_drv_bringup_a/Debug_Linux_AMD64_vGPU_Display_Plugin.txt" > /develop/fsf/Debug_Linux_AMD64_vGPU_Display_Plugin.txt
}


# http://stackoverflow.com/questions/6433241/can-the-perl-debugger-save-the-readline-history-to-a-file
export PERLDB_OPTS=HistFile=$HOME/.perldb.history

case $OSTYPE in
Win32)
    /home/nv/utils/cygwin/bin/cygconfig -info
	# export CYGWIN=tty
    # unset PERL5DB since it gets set by active state which causes problems with 
    # cygwin perl.

    unset PERL5DB
    export COLUMNS=80
	export SYSROOT=/${SYSTEMDRIVE/:/}
	export VIMRUNTIME=C:/Software/vim/vim74
	export VIM=$VIMRUNTIME/gvim.exe
	export EDITOR=`cygpath -iw $VIM`
	export CVSEDITOR=`cygpath -iw $VIM`
	export COMPILER=msvc6;
	export CDPATH=$SYSROOT/Software
	export P4EDITOR=`cygpath -iw $VIM`
    export CYGCOPYTOOLS_P4=1
    # as2 does not currently understand backslashes
	export P4EDITOR=$VIM
	# If you want additional packages, that's what /home/utils/perl-* is for.  
	# We don't modify any Fermi Cygwin install packages from their Cygwin default config.
	# John Neil Mon 5/7/2007 4:12 PM

    function gvim() {
	    local arglist="";
	    local f;
	
	    for f 
	    do 
	        if [ -a $f ]
	        then
	            local p=`cygpath -iw $f`;
	            arglist="$arglist $p"
	        else
	            arglist="$arglist $f"
	        fi
	    done
	
	    # echo "edit $arglist"
	
	   $VIM $arglist & 
	}


	function iview() { $SYSROOT/Program\ Files/IrfanView/i_view32.exe `cygpath -iw $@` & }
	function tkdiff() { wish `cygpath -iw $SYSROOT/bin/tkdiff.tcl` -- $@ & }

	function start() { 
	    if [ -d $1 ]; then
            explorer `cygpath -iaw $1` &
        else
            cmd /c `cygpath -iaw $1` & 
        fi
    }

	function p4w() { p4win& }

    ;;

Linux)
    export EDITOR=vim
    export VISUAL=vim
    export VIEWER=vim
    export PAGER=less
    export MANPAGER=less
    export SHELL=/bin/tcsh
    # Now make bash our shell
    export SHELL=/bin/bash

    # Commit to perlbrew
    # use perlbrew use 5.20.1-007 to switch version
    # source /home/utils/perl5/perlbrew/etc/bashrc
    # perlbrew info
    echo ".bashrc: consider sourcing /home/utils/perl5/perlbrew/etc/bashrc"

	#export VCS_HOME=/home/vcs/vcs5.2
	#export VCS=/home/vcs/vcs5.2
	#export VIRSIMHOME=/home/virsim
    export XUSERFILESEARCHPATH=${XUSERFILESEARCHPATH}:$HOME/app-defaults/%N
	#export VIRSIM_LICENSE_DIR=$VIRSIMHOME/license
	#export LM_LICENSE_FILE=/home/virsim/license/license.dat
	#export LM_LICENSE_FILE=${LM_LICENSE_FILE}:/home/vcs/license.dat.vcsd
	#export VS=$VIRSIMHOME
	#export VS_BIN=${VS}/bin
	#export XNLSPATH=${VIRSIMHOME}/nls
	export CDS_INST_DIR=/home/xl_98
	export XL=/home/xl_98
	export WDIR_OVERRIDE=1
    ;;
SunOS)
    export MANPATH=/usr/local/man:/usr/share/man:/usr/perl5/man:/usr/local/lsf/man:/usr/X11R6/man:/usr/man:/home/nv/man

    export EDITOR=vim
    export VISUAL=vim
    export VIEWER=vim
    export PAGER=less
	#export VCS_HOME=/home/vcs/vcs5.2
	#export VCS=/home/vcs/vcs5.2
	#export VIRSIMHOME=/home/virsim
    export XUSERFILESEARCHPATH=${XUSERFILESEARCHPATH}:$HOME/app-defaults/%N
	#export VIRSIM_LICENSE_DIR=$VIRSIMHOME/license
	#export LM_LICENSE_FILE=/home/virsim/license/license.dat
	#export LM_LICENSE_FILE=${LM_LICENSE_FILE}:/home/vcs/license.dat.vcsd
	#export VS=$VIRSIMHOME
	#export VS_BIN=${VS}/bin
	#export XNLSPATH=${VIRSIMHOME}/nls
	export CDS_INST_DIR=/home/xl_98
	export XL=/home/xl_98
	export WDIR=/home/vcs/flexlm
	export WDIR_OVERRIDE=1
    ;;
IRIX64)
    declare -x PATH=~/os-tools/bin:$PATH;
    ;;
*)
    logmsg "Unknown OS type `uname`: .environment startup failed";
    ;;
esac

unset -f command_not_found_handle
