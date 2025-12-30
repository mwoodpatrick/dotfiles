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

if [ -z ${PATH_BASE+x} ]; then
    # echo ".bashrc: defining PATH_BASE=$PATH"
    export PATH_BASE=$PATH
    export LD_LIBRARY_PATH_BASE=$LD_LIBRARY_PATH
fi

SCRIPT_PATH="${BASH_SOURCE[0]}"
export DOTFILES=$(dirname $(dirname $SCRIPT_PATH))
# echo "SCRIPT_PATH=$SCRIPT_PATH"
# echo "DOTFILES=$DOTFILES"

export TZ=US/Pacific
export DISPLAY=${DISPLAY:-"`uname -n`:0"}
export HOSTNAME=$(hostname --fqdn)

if [ -f $DOTFILES/bash/aliases.bash ]; then
    # echo "sourcing aliases"
    source $DOTFILES/bash/aliases.bash
fi

if [ -f $DOTFILES/bash/ssh.bash ]; then
    source $DOTFILES/bash/ssh.bash
fi

if [ -f $DOTFILES/bash/apt.bash ]; then
    source $DOTFILES/bash/apt.bash
fi

# enable tab expansion
# https://askubuntu.com/questions/1245285/bash-doesnt-expand-variables-when-pressing-tab-key

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1
HISTSIZE=1000
HISTFILESIZE=2000

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

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

case $OSTYPE in
Win32)
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
    # perlbrew info

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
    export MANPATH=/usr/local/man:/usr/share/man:/usr/perl5/man:/usr/local/lsf/man:/usr/X11R6/man:/usr/man

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
