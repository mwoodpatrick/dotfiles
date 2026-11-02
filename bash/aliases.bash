unalias -a
echo "sourcing aliases"

kitty() {
    LIBGL_ALWAYS_SOFTWARE=1 command kitty "$@" &
}

ghostty() {
    command ghostty "$@" &
}

alias c='clear'
# report what clients I have
alias cho='cvs history -o'
alias cn='cvs -n update'
alias cnd='cvs -n update -d'
alias cndn='cvs -n update -d 2>&1 | grep New'
alias demangle='c++filt'
alias ds=dirs
alias gv100r='cd /home/scratch.emu_gv100/gv100/regressions/systems'
alias h=history
alias ht='history | tail -50'
alias hl='history | less'
alias j='jobs -l'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ltr='ls -ltr'
alias ltrt='ls -ltr | tail'
alias pe=printenv
alias rs='eval `resize`'
alias hssh='ssh c823543-a.stcla1.sfba.home.com'
alias soc='source ~/.bashrc'
alias up='cd ..'
alias via='vi ~/.bash_aliases ; source ~/.bash_aliases'
alias myps='ps -w -f -u $USER'
alias mydf='df -k | grep "$USER"'
alias vnc='/home/nv/bin/vncserver_high_ports.sh -alwaysshared -geometry 1600x1000 -depth 24'

# Everyday administrative alias chains matching your layout requirements
# Prefer nixos-rebuild boot for System Services: If you ever start modifying
# core system-level services (like networking, DBus, or kernel modules),
# use sudo nixos-rebuild boot instead of switch. It’s safer and avoids the
# need for live-reloading complex systemd-user states.
alias nix-switch='sudo nixos-rebuild switch --flake \$NIXOS_CONFIG_ROOT'
alias nix-boot='sudo nixos-rebuild boot --flake \$NIXOS_CONFIG_ROOT'
alias nix-check='nix flake check \$NIXOS_CONFIG_ROOT'
alias nix-generations='sudo nixos-rebuild list-generations'

function nix-gc() {
    sudo nix-collect-garbage --delete-older-than 1d
    echo "Remaining NixOS generations:"
    nix-generations
}

function nix-update() {
    nix flake update --flake "$NIXOS_CONFIG_ROOT" nixpkgs-unstable &&
    nix-check &&
    nix-switch &&
    nix-gc
}

alias g="git"
alias v="nvim"
alias ".."="cd .."

# ff - find string in files. $1 = directory, $2 = pattern
ff() {
    local dir=${1:-.}
    local pattern=${2:-}
    if [[ -z $pattern ]]; then
        echo "Usage: ff <directory> <pattern>"
        return 1
    fi
    find "$dir" -type f -exec grep -si -- "$pattern" {} + -print
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
    projectname=$(nvprojectname resolve)
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

function lean_update {
    (
        local project=${1:-my_lean_project}
        echo "Updating project: $project"
        set -e # Exit immediately on error
        nix-switch
        echo "==> Active Lake version:"
        lake --version
        # Navigate to project
        cd $GIT_ROOT/$project || return 1
        echo -n "==> Previous toolchain: "
        cat lean-toolchain
        echo "==> Fetching latest toolchain from Mathlib master..."
        curl -s -o lean-toolchain https://raw.githubusercontent.com/leanprover-community/mathlib4/master/lean-toolchain
        NEW_TOOLCHAIN=$(tr -d ' \r\n' <lean-toolchain)
        echo "==> Updated toolchain: $NEW_TOOLCHAIN"
        # Extract clean tag (e.g., 'v4.35.0-rc4' from 'leanprover/lean4:v4.35.0-rc4')
        VERSO_TAG="${NEW_TOOLCHAIN#*:}"
        # Auto-update Verso's rev in lakefile.toml if present
        if [ -f "lakefile.toml" ]; then
            echo "==> Syncing Verso rev to '$VERSO_TAG' in lakefile.toml..."
            sed -i -E "/name = [\"']verso[\"']/,/rev =/ s/rev = \".*\"/rev = \"${VERSO_TAG}\"/" lakefile.toml
        fi
        # Clean old manifests, build directories, and stale branch refs
        echo "==> Cleaning stale package caches and manifests..."
        rm -rf lake-manifest.json .lake/packages/verso .lake/packages/subverso .lake/build

        # Export NixOS SSL bundle for Lake / curl downloads
        export SSL_CERT_FILE="/etc/ssl/certs/ca-bundle.crt"

        echo "==> Resolving dependencies..."
        lake update

        echo "==> Fetching precompiled Mathlib olean caches..."
        lake exe cache get

        echo "==> Building project..."
        lake build

        set +e
        echo "==> Update complete!"
    )
}

# list extern symbols
alias nmc='nm -gC'
# list unresolved symbols
alias nmuc='nm -uC'
alias lsfstatus='bhosts -s vcs | head -2'
alias lsc='ls -hF --color'
alias diskusage='du -sh \$(ls -A) | sort -hr | head'

case $OSTYPE in
Win32)
    # no 'more' on cygwin
    alias more=less
    ;;

*)
    alias firefox='firefox -P &'
    alias chrome="/home/utils/chrome-58.0.3029.110/opt/google/chrome/google-chrome &"
    alias py=python3
    ;;
esac
