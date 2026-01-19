unalias -a

alias c=clear
# report what clients I have
alias p4clients="p4 clients -t -u mwoodpatrick"
alias p4shelved="p4 changes -u $USER -s shelved"
# report latest changelist
alias p4tot="p4 changes -m 1 ..."
alias p4changes="p4 changes -t -m 20 |less"
# report what cl we want
function p4want {
    echo "want:"
    p4 describe $1|head -1
    echo "have:"
    p4 changes -m 1 ...#have
}
# report what changelist I have in my tree
alias p4have="p4 changes -m 1 ...#have"
alias p4rev="p4 _revision"
alias cho='cvs history -o'
alias cn='cvs -n update'
alias cnd='cvs -n update -d'
alias cndn='cvs -n update -d 2>&1 | grep New'
alias demangle="c++filt"
alias ds=dirs
alias forge='/home/nv/utils/forge/1.0/bin/forge.pl $*'
alias gv100r='cd /home/scratch.emu_gv100/gv100/regressions/systems'
alias h=history
alias ht='history | tail -50'
alias hl='history | less'
alias j='jobs -l'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ltr="ls -ltr"
alias ltrt="ls -ltr | tail"
alias pe=printenv
alias rs='eval `resize`'
alias hssh="ssh c823543-a.stcla1.sfba.home.com"
alias s='cmd /c "start $1"'
alias soc="source ~/.bashrc"
alias up='cd ..'
alias via="vi ~/.bash_aliases ; source ~/.bash_aliases"
alias myps='ps -w -f -u $USER'
alias mydf='df -k | grep "$USER"'
alias vnc="/home/nv/bin/vncserver_high_ports.sh -alwaysshared -geometry 1600x1000 -depth 24"
alias myvnc="grep $USER /tmp/vnc_totals"

# ff - find string in files. $1 = directory, $2 = pattern
ff ()
{
	find $1 -exec grep -si $2 \{\} \; -print
}

#   nvrun projectteam
#   nvprojectname resolve_validate
function record_projectname() {
    cd $NVTEE_LITTER_ROOT
    # PROJECT_TEAM= hwinf_content_mods <group>_<team>_<subteam>
    # For nvprojectname, I use gpu_g000_hwinf_content_class
    # The thinking is that our work is not focused on supporting a specific chip, so I use g000 instead of gh100.

    if [ ! -e .nvprojectname ]; then
        nvprojectname save . business=gpu group=hwinf team=content subteam=class
    fi
    # gpu_ga100_hwinf_content_mods
    projectname=`nvprojectname resolve`
    export PROJECT=$projectname
    echo "nvprojectname=$projectname"
    cat .nvprojectname

    # define projects to build in tree.make e.g. gm20b gm20b_debug
    # then nvmk does bin/t_make -build fmod -build rtl -project gm20b -project gm20b_debug
    # see https://wiki.nvidia.com/gpuhwdept/index.php/New_Architect_First_Day/Maxwell_FModel_QuickStart

    if [ ! -e tree.make ]; then
        # AS2 command: echo export PROJECTS := gp100 gp100_111 gp100_121 gp100_111_trim gp100_222 gp100_252 gp100_354 gp100_454 gp104 gp104_111 gp105 gp105_111 gp105_121 gp105_111_trim gp10b gp10b_111 gp10b_111_trim gp000 > tree.make
        make tree.make
        # set the PROJECT_TEAM in the tree.make file
        # PROJECT_TEAM := hwinf_content_class

        nvrun projectteam
        nvprojectname resolve_validate
    fi
}

# list extern symbols
alias nmc="nm -gC"
# list unresolved symbols
alias nmuc="nm -uC"
alias lsfstatus="bhosts -s vcs | head -2"
alias lsc='ls -hF --color'
alias p="/home/utils/perl-5.8.8/bin/perl"
alias pd="/home/utils/perl-5.8.8/bin/perl -I lib -d:ptkdb  "
alias pl="/home/utils/perl-5.14/5.14.1-nothreads-64/bin/perl"
alias perltidy="/home/utils/perl-5.8.8/bin/perltidy"
alias glivd=$hw/tools/imgtools/bin/glivd
alias diskusage="du -sh \$(ls -A) | sort -hr | head"

case $OSTYPE in
Win32)
	# no 'more' on cygwin
	alias more=less;
	alias bj="rsh -l $USER l-xterm-1 bjobs"
	alias bjw="rsh -l $USER l-xterm-1 bjobs -w"
	alias bjp="rsh -l $USER l-xterm-1 bjobs -p"
	alias bq="rsh -l $USER l-xterm-1 bq"
    # alias p4='env PWD="`echo $PWD | cygpath -w -f -`" p4'
    ;;

*)
    alias bj=bjobs
    alias bjw="bjobs -w"
    alias bjp="bjobs -p"
    alias bq="bqueues | bq.pl"
    alias firefox="firefox -P &"
    alias chrome="/home/utils/chrome-58.0.3029.110/opt/google/chrome/google-chrome &"
    alias py=python3
    ;;
esac
