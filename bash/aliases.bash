#   https://www.gnu.org/software/bash/manual/bashref.html#Shell-Parameters
#   https://seankross.com/the-unix-workbench/bash-programming.html
#   https://confluence.nvidia.com/pages/viewpage.action?spaceKey=CH&title=FModel+Setu
#   vim delete from character to end of line: https://stackoverflow.com/questions/37293734/vim-delete-starting-from-character-to-end-of-line

# environment variables used for builds/runs
#
# P4CLIENT_HW perforce client for hw tree
# P4ROOT_HW filesystem path to hw tree
# HW_CL current changelist for hw tree
# P4CLIENT_SW perforce client for sw tree
# P4ROOT_SW filesystem path to sw tree
# SW_CL current changelist for sw tree
# FSF_TOP top of development directory
# FSF_TEST_DIR current FSF directory structure
#
# functions
#
#   sync_trees
#   sync_hw_tree
#   sync_sw_tree
#
# bin/t_make -build chiplib_e
# generate_hw_chiplib_e /home/scratch.mwoodpatrick/fsf/p4_crucible/runspaces/chiplib_e_cl_${HW_CL}
# build_fmodel
# needed to find tools contains .nvprojectname & .p4config
# see also gv100, twobox_gv100, forge_gv100, aio_gv100,
# export CSL="[enable]chiplib_e,[enable]CPUModel"
# cd /home/pascal_bringup/mlwp/tests/comp_one_tri
#   command.sh
#   export HWCHIP_DEBUG=1
# p4 describe -S 19130989|less
# change 37146554 has Some hooks for debugging CSL corruption issue see bug 1811911 & 1810957
# change 19130989 Hack to report A-model crc's rather than f-model's for use with amodel as fmodel using env var NVTEE_FORCE_AMODEL_CRC
# change 20476044 Add -echip option to use chiplib_e
# change 21484487 Disable lock mapping
# p4 sync //sw/...@${SW_CL}
# p4shelved

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
alias ds=dirs
alias forge='/home/nv/utils/forge/1.0/bin/forge.pl $*'
alias gv100r='cd /home/scratch.emu_gv100/gv100/regressions/systems'
alias h=history
alias ht='history | tail -50'
alias hl='history | less'
alias ltr="ls -ltr"
alias ltrt="ls -ltr | tail"
# alias m=less # conflicts with android build function :-)
alias pe=printenv
alias rs='eval `resize`'
alias hssh="ssh c823543-a.stcla1.sfba.home.com"
alias s='cmd /c "start $1"'
alias soc="source ~/.bashrc"
alias up='cd ..'
alias via="vi ~/.bash_aliases ; source ~/.bash_aliases"
alias myps='ps -w -f -u $USER'
alias mydf='df -k | grep "$USER"'

# FSA_MAIN FSA repository for scripts, apps, os builds, drivers
export FSA_MAIN=/home/scratch.mwoodpatrick_inf/fsa

# start VNC session see https://wiki.nvidia.com/engit/index.php/VNC_EE_5.1.1/Linux
# runs applications in .vnc/xstartup
# ubuntu fails with Unrecognized option: PasswordFile=/home/mwoodpatrick/.vnc/passwd
# when using /home/tools/realvnc/vnc-E5_2_3-x64/bin/vncserver see INC0046327
# qsub --projectMode direct -P gpu_gp107_vlsi_pnr -q o_pri_interactive -J vnc /home/utils/bin/vncserver -nosetsid -alwaysshared -geometry 1600x1000 -depth 24
# The easiest way to start a VNCserver: /home/nv/bin/vncserver_high_ports.sh
#   /home/nv/bin/vncserver_high_ports.sh -alwaysshared -geometry 1600x1000 -depth 24
# To close a VNC session down, issue the following command (example only, replace relevant xterm and port as appropriate): 
#    $ ssh sc-xterm-13
#    $ vncserver -kill :23

# alias vnc="/home/utils/bin/vncserver -alwaysshared -geometry 1600x1000 -depth 24" 
# HR: INC0177722 https://nvidiaprod.service-now.com/nav_to.do?uri=incident.do%3Fsys_id=3be286e60f384300650babf8b1050e40%26sysparm_stack=incident_list.do%3Fsysparm_query=active=true
# qsub --projectMode direct -P gpu_gp107_vlsi_pnr -q o_pri_interactive -J vnc /home/utils/bin/vncserver -nosetsid -alwaysshared -geometry 1600x1000 -depth 24
alias vnc="/home/nv/bin/vncserver_high_ports.sh -alwaysshared -geometry 1600x1000 -depth 24" 
alias myvnc="grep $USER /tmp/vnc_totals"
# find a good machine: cat /etc/motd | grep xterm | sort -k 9 -n  | tail
# To close a VNC session down, issue the following command (example only, replace relevant xterm and port as appropriate): 
# $ ssh sc-xterm-10
# $ vncserver -kill :12
# Erik Welch <ewelch@nvidia.com>
# /home/utils/nagios/libexec/check_procs -u gpulab
# There is a script: /home/nv/bin/vncserver_high_ports.sh that can make selecting ports very easy. 
# Simply run that in place of vncserver (passes through arguments). It will find you an available port and start a server on that host.

alias j='jobs -l'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias demangle="c++filt"

function penv() {
    strings /proc/${1}/environ
}

# save changes to p4 clients since in general they are not being backed up
# https://wiki.nvidia.com/engwiki/index.php/Perforce#NVIDIA.27s_Client_Spec_Revision_Control
function p4c() {
    path=~/p4_client_history/`date +%b_%d_%y_%H_%M_%S`.txt
    p4 client
    p4 client -o &> $path
    mail -s "P4 Client Updated" mwoodpatrick@nvidia.com < $path
}

function lcbenv() {
    export PATH=/opt/openpower/p9/ecmd/x86_64/bin:/opt/openpower/p9/ecmd/bin:/opt/openpower/p9/cronus/p9/exe:/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/opt/openpower/p9/common/x86_64/bin:/local_home/lcbuser/bin
    export LD_LIBRARY_PATH=/opt/openpower/p9/cronus/ecommon/lib/x86_64/ftd2xx:/opt/openpower/p9/cronus/ecommon/lib/x86_64/riscwatch:/opt/openpower/p9/cronus/p9/exe/dev/prcd_d/:/opt/openpower/p9/cronus/p9/exe/dev/x86_64/:/opt/openpower/p9/cronus/p9/exe/dev/:/opt/openpower/p9/ecmd/x86_64/lib
}

##########################
#
# environment variable stuff
#
##########################
pd () { pg display=; }
pg () { env | grep -i $1; }
sd () { export DISPLAY=$1; }

ullp() { unset LD_LIBRARY_PATH; }

# https://wiki.nvidia.com/gpuhwdept/index.php/Infrastructure/QUASAR/Scripts/as2_task_info
# as2_task_info -list
# as2_task_info -list -golden
# as2_task_info -help

function as2_task_info () {
    /home/nv/utils/quasar/bin/as2_task_info.pl -tree $NVTEE_LITTER_DIR $*
}

function tufind {
    find $hw/doc/gpu/turing_info/ -exec grep -nH $1 {} \;|less
}

llp() { 
    export LD_LIBRARY_PATH=$1:$LD_LIBRARY_PATH;
	echo LD_LIBRARY_PATH is now $LD_LIBRARY_PATH;
}

##########################
#
# grep/find handy shortcuts
# find /home/scratch.mwoodpatrick/fsf/p4_crucible/hw/class/pascal/amod/ -name \*.h -o -name \*.cpp -exec grep -nH registerEventCallback {} \;
# http://www.tecmint.com/35-practical-examples-of-linux-find-command/
#
##########################
gi () { grep -i $*; }

# ff - find string in files. $1 = directory, $2 = pattern
ff ()
{
	find $1 -exec grep -si $2 \{\} \; -print
}


##########################
#
# ls stuff
#
##########################

lga () { ls -lga $*; }
lgat () { ls -lgat $*; }
lgath () { ls -lgat $* | head; }
lgad () { ls -lgad $*; }


##########################
#
# prmopt/cd stuff
#
##########################
update_prompt ()
{
	current_dir=$PWD;
}

cd ()
{
	old_dir=$PWD;
	builtin cd $1;
	update_prompt;
}

# ct - toggle between 2 directories 
ct () { cd $old_dir; }

pse () { command ps -eo user,pid,ppid,args $*; }
psh () { command ps -eHo user,pid,args $*; }
psu () { command ps -eo user,pid,ppid,args --sort user $*; }

# misc. shorthands

td () { tkdiff $*; }


# Chris Dragan <kdragan@nvidia.com> 
#   All MODS builds for x86_64 are now using gcc-7.3. It's documented in the makefiles, specifically:
#	    //sw/dev/gpu_drv/bugfix_main/drivers/common/build/mods/makedefs.inc line 935
#	    //sw/dev/gpu_drv/bugfix_main/drivers/common/build/nvUnixCommonRules.nvmk line 15
#
# Garrett Smith <gasmith@nvidia.com>
# For fmodel see $nvgpu/etc/tool_data.config in each tree (which can be accessed in scripts via. 
# NV::DefaultEnvironment or $TOT/bin/get_tool.pl)
# 
# http://stackoverflow.com/questions/2387040/how-to-retrieve-the-gcc-version-used-to-compile-a-given-elf-executable
# amodel & nvtee use gcc-4.6.0 (March 25, 2011)
# mods on Linux uses gcc-4.9.2 -std=c++11
# tot mods uses gcc-4.9.2 which requires gdb-7.10.1 or later to view symbols
# fmodel uses /home/utils/4.7.2 (Nov  7  2012) confirmed by running nvrun gcc --version
# https://wiki.nvidia.com/gpuhwdept/index.php/Fermi_fmodel_debug
# fmodel appears to use /home/utils/gdb-7.4/bin (24 Jan 2012) confirmed by running nvrun gdb --version
# fsf qemu built with 4.1.2
# fsf simproc built with 4.1.1

# call examples:
#   use_gcc 4.6.0
#   use_gcc 4.7.2
#   use_gcc 4.9.2
#   use_gcc 5.3.0
#   use_gcc 5.4.0
# looking at mods makefile looks like its using gcc-4.1 and make 3.81
function show_paths () {
    echo PATH=$PATH
    echo LD_LIBRARY_PATH=$LD_LIBRARY_PATH
    echo gcc=`which gcc`
    echo g++=`which g++`
    echo gdb=`which gdb`
    echo p4=`which p4`
}

# show parent process
function pp () {
    pstree -Alaps $1
}

# see: //hw/toolsrc/as2/tools/sync_open_traces.pl
function determine_changelists {
    echo "current changelists ... "
    cwd=`pwd`
    cd $hw
    p4 _revision
    p4 describe $HW_CL|head -1
    cd $sw
    p4 _revision
    p4 describe $SW_CL|head -1
    cd $cwd
    echo "platform: $NVTEE_PLATFORM chip: $NVTEE_CHIP litter: $NVTEE_LITTER litter root: $NVTEE_LITTER_ROOT"
    echo "HW_CL=$HW_CL (FSA_CL=$FSA_CL): P4CLIENT_HW=$P4CLIENT_HW: P4ROOT_HW=$P4ROOT_HW"
    (cd $nvgpu; echo "HW_CL:" `p4 describe $HW_CL|head -1`)
    echo "SW_CL=$SW_CL: P4CLIENT_SW=$P4CLIENT_SW: P4ROOT_SW=$P4ROOT_SW"
    (cd $sw; echo "SW_CL:" `p4 describe $SW_CL|head -1`)
    echo "MODS_RUNSPACE=$MODS_RUNSPACE"
    echo "run fsa_gh100_sync_integrate_build_and_test to update"
}

# https://confluence.nvidia.com/display/GPUTree/How+to+get+Support
# always sync your tree to a golden_cl. That guarantees that you will be able to build/run the fmodel for any chip.
#
#   https://confluence.nvidia.com/display/GPUTree/Working+in+the+NVGPU+Mainline#WorkingintheNVGPUMainline-SynctoaGoldenCL
#
# These are the fmodel regression tasks run by the golden_cl:
# 
# task nvgpu_fmodel_regress64:
#   Dependencies:
#      REQUIRED nvgpu_g000_fmodel_regress64_sw_sanity
#      REQUIRED nvgpu_g000_fmodel_regress64_switch_sanity
#      REQUIRED nvgpu_g000_fmodel_regress64_sanity
#      REQUIRED nvgpu_g000_fmodel_regress64_new_features_sanity
#      REQUIRED nvgpu_ga100_fmodel_regress64_sw_sanity
#      REQUIRED nvgpu_ga100_fmodel_regress64_new_features_sanity
#      REQUIRED nvgpu_ga100_fmodel_regress64_debug_sanity
#      REQUIRED nvgpu_ga102_fmodel_regress64_sw_sanity
#      REQUIRED nvgpu_gh100_fmodel_regress64_sw_sanity
#      REQUIRED nvgpu_display_regress_fmodel
#
#   https://wiki.nvidia.com/gpuhwdept/index.php/GoldenCl/UserDoc#Fetching_MODS
#       nvrun golden_cl status --customer nvgpu
#
# cl hw tree was last build with is in nvgpu/tmake.out

# alias gstatus="nvrun golden_cl status --customer $NVTEE_LITTER_DIR"

function gstatus () {
    nvrun golden_cl status --customer $NVTEE_LITTER_DIR
}

# /home/nv/utils/hsmb/bin/last_promotion_info.pl is used to determine fmodel CL to use for DVS runs
# sync_golden_hw_tree 2>&1 | tee sync_golden_hw_tree`date +%m_%d_%y__%H_%M_%S`_out.log
# https://as2/task.php?task=nvgpu_build_regress_golden
# DVS status can be checked by AXL history. For example: http://dvs/Query/User?which_user=component_history&build_component=gpu_drv_chips+Debug+CentOS6_64+ci7oc+none+DX0+nvgpu&which_category=AXL+Sanity
# see build_init
# HSMB contacts: Raghav Mathur <raghavm@nvidia.com>, hsmb-support <hsmb-support@exchange.nvidia.com>
# Note chips_hw is used to test against hardware cl not chips_a (so use chips_hw AS2)
# nvrun golden_cl status --customer nvgpu_gh100_hsmb
# https://confluence.nvidia.com/display/MSTS/HSMB+Promotions+Flow
# https://confluence.nvidia.com/display/MSTS/HSMB+Promotion+Cycle+Details
# How to fetch fmodel if you are a software engineer: https://confluence.nvidia.com/questions/282989886/answers/351575102
# How to know the swcl from chips_hw at which the "last" attempt for hw to sw mods promotion happened: https://confluence.nvidia.com/questions/283219939/answers/308645925
# Why is hsmb golden_cl so far behind golden: https://confluence.nvidia.com/display/HSMB/questions/937716136/why-is-hsmb-goldencl-so-far-behind-golden- 
# golden_cl get --customer  <customer> --type <type>  valid types are hw, sw, rules
# HW_CL=`nvrun golden_cl get --customer nvgpu_gh100_hsmb`

function sync_golden_hw_tree () {
    cd $nvgpu
    echo "synching changes in $P4ROOT_HW"
    echo "using p4 sync @_golden"
    p4 sync @_golden=$NVTEE_LITTER_DIR
    p4 resolve
    p4 sync @_golden=$NVTEE_LITTER_DIR
    p4 resolve
    local fcl=`./bin/get_autofetch_cl`
    echo -n "latest autofetch changelist: "
    p4 describe $fcl | head -n 1
    ./bin/get_autofetch_cl -verbose

    # local gcl_hw=`bin/get_good_changelist`
    local gcl_hw=`nvrun golden_cl get --customer $NVTEE_LITTER_DIR --type hw`
    local gcl_sw=`nvrun golden_cl get --customer $NVTEE_LITTER_DIR --type sw`
    echo -n "hw golden changelist: "
    p4 describe $gcl_hw | head -n 1

    echo -n "sw golden changelist: "
    cd $sw
    p4 describe $gcl_sw | head -n 1

    cd $nvgpu

    # validate tree
    # nvgpu_gmlit2_policy_check
    # http://as2.nvidia.com/task.php?task=nvgpu_gmlit2_policy_check
    bin/p4policy.pl

    echo "use command gstatus to get latest golden cl status"
    gstatus
    echo "platform: $NVTEE_PLATFORM chip: $NVTEE_CHIP litter: $NVTEE_LITTER litter root: $NVTEE_LITTER_ROOT"
    echo "use nvrun golden_cl status --customer $NVTEE_LITTER_DIR to get current GCL status"
    echo "now run build_fmodel"
    return

    $nvtee/bin/treeinfo

    # CAUTION: need to build mods to get our patched version
    # fetch_manuals
    build_manuals
    # In future you can run ./bin/get_autofetch_cl -verbose to find the most recent good autofetch cl and how old it is
    build_fmodel
    # fetch_amodel
    build_amodel
    # mods fetched in sync_sw_tree since we have local changes
    # //sw/dev/gpu_drv/chips_a/diag/mods/runspace/mods
    cd $NVTEE_LITTER_ROOT

    # configure_traces

    configure_testgen

    ls -l $NVTEE_LITTER_ROOT/clib/Linux_x86_64 | grep fmodel

    for type in Release Debug
    do
        target=$hw/class/$NVTEE_GPU_CLASS/amod/code/bin/Linux/${type}_gcc_46_x64/nv_amodel.so
        ls -l $target
    done
}

function clean_amodel () {
    echo "cleaning amodel ..."

    # clean the 64-bit linux Debug amodel
    cd $hw/class/$NVTEE_GPU_CLASS/amod
    make clean
    make clean_release
    # make RECIPE=linux_x86_64_gcc550 clean
    find . -name "*.o"
    find . -name "*.d"
    find . -name "*.a"
    find . -name "*.so"
    find . -name "Debug_gcc_*" -exec rm -rf {} \;
    find . -name "Release_gcc_*" -exec rm -rf {} \;
    rm -rf $MODS_RUNSPACE/nv_amodel.so
    find . -name Linux-x64-Release -exec rm -rf {} \;
    find . -name Linux-x64-Debug -exec rm -rf {} \;
    find . -name "*.so" -exec ls -l {} \;
}


# to build at an old cl may need to modify getmanualsAmodel.sh to add  -latest to getregsys command
# need .nvprojectname & .nvprojectname_default set to give project name
# see https://confluence.nvidia.com/display/HWINFFARM/GPUProjectTagging#GPUProjectTagging-NVBuildjobtaggingmechanism
# https://wiki.nvidia.com/gpuhwdept/index.php/GPU_Project_Naming_Quick_Start#Set_up_project_naming_for_your_chip_trees
# https://confluence.nvidia.com/display/HWINFCONTENT/Full+Stack+AModel#FullStackAModel-SyncingandbuildingF+AModel
# https://confluence.nvidia.com/display/AUS/Hopper+Amodel+Build+Instructions
# https://wiki.nvidia.com/gpuhwdept/index.php/AModel/Ampere_Amodel_Build_Instructions#Building_on_Linux
# https://wiki.nvidia.com/gpuhwdept/index.php/GPU_Infrastructure_Group/AModel#Building.2C_Fetching.2C_and_Regressions
# https://wiki.nvidia.com/gpuhwdept/index.php/AModel/Pascal_Amodel_Build_Instructions#Building_on_Linux
# https://wiki.nvidia.com/gpuhwdept/index.php/AModel/Volta_Amodel_Build_Instructions#Building_on_Linux
# https://wiki.nvidia.com/gpuhwdept/index.php/AModel/Turing_Amodel_Build_Instructions#From_the_AModel_tree_.2F.2Fhw.2Fclass.2Fturing.2Famod

function build_amodel () {
    # cd $hw/nvgpu # for both pascal & volta
    # rm -rf $MODS_RUNSPACE/nv_amodel.so

    pushd $hw/class/$NVTEE_GPU_CLASS/amod

    for type in Release Debug
    do
        if [ "${type}" == "Release" ]
	    then
            buildopt="release"
	    else
            buildopt="debug"
        fi

        # pascal amodel uses gcc 4.6.0
        # volta & turing amodel uses gcc 4.9.3
        # serial build useful when you encounter a build error
        # make $buildopt RECIPE=linux_x86_64_gcc460
        # By default a debug version is built. To build a release version, use "make -j8 release RECIPE=linux_x86_64_gcc460"
        # Concurrent build (best when you feel the need for speed)
        # qsub -Is -q o_cpu_2G_1H -n 4 -R 'span[hosts=1]' make -j8 $buildopt RECIPE=linux_x86_64_gcc460
        # cmd="qsub -Is -q o_cpu_2G_1H -n 8 -R 'span[hosts=1]' make -j8 $buildopt RECIPE=linux_x86_64_gcc460"
        # cmd="bin/t_make -leaveLogs -build amod -skipManuals -amodGcc gcc46_x64 -amodArch $NVTEE_GPU_CLASS $buildopt"
        # cmd="make RECIPE=linux_x86_64_gcc460"
        # To avoid symbol conflict issue between fmodel and amodel, -fvisibility=hidden is needed. 
        # Ampere amodel gcc550 build has supported this. build command line: 
        # make RECIPE=linux_x86_64_gcc550 VISIBILITY_HIDDEN=1

        local target

        if [ "$NVTEE_GPU_CLASS" == "ampere" ]; then
            cmd="make -j8 $buildopt RECIPE=linux_x86_64_gcc550 VISIBILITY_HIDDEN=1"
            target=$hw/class/$NVTEE_GPU_CLASS/amod/code/bin/Linux_x86_64/${type}_gcc_550_x64/nv_amodel.so
        else
            cmd="./build --dynamic-runtime $buildopt"
            target=$hw/class/$NVTEE_GPU_CLASS/amod/code/bin/Linux-x64-${type}/nv_amodel.so
        fi

        echo "building $target"

        local log=build_${type}_amodel_`date +%m_%d_%y__%H_%M_%S`.log
        echo "building $type $NVTEE_GPU_CLASS amodel $cmd: ..."
        time $cmd 2>&1 | tee $log
        echo "log file: $log"

        file $target
        ls -l $target
    done

    popd
}

function fetch_amodel () {
    # https://wiki.nvidia.com/gpuhwdept/index.php/GPU_Graphics_Infrastructure_Group/AModel/AmodelShortcutScripts
    # see /home/nv/utils/fetch/fetch-0.2/bin/get_ab2_amodel for more info on flow
    # qsub -K -q ${AS2_O_CPU_QUEUE}_2G_1H -o get_amodel.log bin/get_amodel.pl -latest -arch $arch $type -dest $MODS_RUNSPACE
    echo "fetching amodel ..."
    cd $NVTEE_LITTER_ROOT

    if [[ $DEBUG ]] ; then type="-norelease" ; else type="" ; fi

    bin/get_amodel.pl -latest -arch $NVTEE_SYSTYPE $type -dest $MODS_RUNSPACE
    ls -l $MODS_RUNSPACE/nv_amodel.so
    file $MODS_RUNSPACE/nv_amodel.so
}

function clobber_fsa () {
    clean_amodel
    clobber_fmodel
}

function build_fsa () {
    build_amodel
    build_fmodel
    cp -pr $AMODEL_LIBDIR/nv_amodel.so $nvgpu/clib/Linux_x86_64
    # copy files from nvmobile tree
    # should determine this by processing diag/chiplib_f/ghlit1_Linux_x86_64/ghlit1_ld_release_library_path.txt
    # as does //sw/dev/gpu_drv/chips_a/drivers/fsf/dvs/sync_fmodel.sh
    # It relies on //sw/dev/gpu_drv/chips_a/drivers/fsf/dvs/sync_fmodel.pl for submitting updated VRLParam to P4 if needed.
    # Source code is in //hw/nvmobile/tools/libgptuil
    cp -p /home/ip/nvmobile/inf/libgputil/49969195/Linux_x86_64/libgputil.so $nvgpu/clib/Linux_x86_64
    cp -p $FSA_MAIN/scripts2/backdoormem/th500/* $nvgpu/clib/Linux_x86_64/ghlit1

    # replace with amy's build (if necessary)

    # rm -rf $nvgpu/clib/Linux_x86_64/libth500_backdoormem.so
    # rm -rf $nvgpu/clib/Linux_x86_64/libth500_debug_backdoormem.so
    # cp -p /home/scratch.age_maxwell-info/FSA/nvmobile_genie_1/th500/pwas/backdoormem/output/backdoormem/th500_Linux_x86_64_mc50-arch_clib_backdoormem_ee/build-e704bd/ip/mss/mc/5.0/clib/backdoormem_ee/th500_Linux_x86_64/libth500_backdoormem.so $nvgpu/clib/Linux_x86_64

    # cp -p /home/scratch.age_maxwell-info/FSA/nvmobile_genie_1/th500/pwas/backdoormem/output/backdoormem/th500_debug_Linux_x86_64_mc50-arch_clib_backdoormem_ee/build-213bf0/ip/mss/mc/5.0/clib/backdoormem_ee/th500_debug_Linux_x86_64/libth500_debug_backdoormem.so $nvgpu/clib/Linux_x86_64
}

# https://confluence.nvidia.com/pages/viewpage.action?pageId=987474920#NVBuild/Tools_management-Howtoaccesstools
#   bin/get_tool_dir.pl gcc
# https://wiki.nvidia.com/gpuhwdept/index.php/GPU_Workflow_And_Know-how/Crucible
# https://wiki.nvidia.com/gpuhwdept/index.php/Get_Scripts
# https://wiki.nvidia.com/gpuhwdept/index.php/GPU_Infrastructure_Group/GPU_Infrastructure_Initiatives/GPU_Tmake_Autofetch
# Use `depth`/bin/get_autofetch_cl -verbose to find the most recent good autofetch cl and how old it is
# get_autofetch_cl uses p4 changes -m1 ...#have
# nvrun golden_cl status --customer nvgpu_gh100
# nvrun golden_cl status --customer nvgpu_gh100_hsmb

function fixup_amodel_build () {
    # p4 sync //hw/class/hopper/amod/amodel_common.cmake@58956388   # windows compiler
    # p4 sync //hw/class/hopper/amod/build@58956388 # linux/gcc compiler
    # p4 sync //hw/class/hopper/amod/code/src/main/CMakeLists.txt@58956388 # static link
    # see shelved cl 59747443
    # disable static linking
    p4 unshelve -s 59747443
    # change 59891978 on 2022/01/21 13:05:09 added option --dynamic-runtime to enable dynamic linking
}

function fsa_gh100_sync_integrate_build_and_test () {
    # gh100, fsa_gh100, fsa_gh100_tree2
	
    cd $nvgpu
    
    # https://as2/task.php?task=nvgpu_build_regress_golden
    # you can run ./bin/get_autofetch_cl -verbose to find the most recent good autofetch cl and how old it is
    # gstatus
    # Also run /home/nv/utils/hsmb/bin/last_promotion_info.pl this is used by DVS & FSF flow
    # sync_golden_hw_tree 2>&1 | tee sync_golden_hw_tree_`date +%m_%d_%y__%H_%M_%S`.log

    # update and source .bash_mlwp_aliases to set new HW_CL & SW_CL

	p4 sync @$HW_CL
	p4 resolve -am
	p4 resolve

    p4want $HW_CL
    p4 describe $HW_CL|head -1
    p4 describe $FSA_CL|head -1

    # p4 sync $nvgpu/...@$NVGPU_CL; p4 resolve
    # p4 _revision

    p4 sync //dev/inf/FullStackAmodel/...@$FSA_CL
    p4 changes -m 1 //dev/inf/FullStackAmodel...#have

    # fsa_integrate
	# p4 integ -b FullStackAmodel //dev/inf/FullStackAmodel/IDirectAmodel/...@$HW_CL 2>&1 | tee IDirectAmodel_`date +%m_%d_%y__%H_%M_%S`.log
    p4 integ -b FullStackAmodel.hopper.mainline //dev/inf/FullStackAmodel/hopper/...@$HW_CL 2>&1 | tee FullStackHopperAmodel`date +%m_%d_%y__%H_%M_%S`.log
	p4 resolve -am
	p4 resolve

	# p4 integ -b FullStackAmodel //dev/inf/FullStackAmodel/hopper/...@$HW_CL 2>&1 | tee FullStackHopperAmodel`date +%m_%d_%y__%H_%M_%S`.log
	# p4 resolve -am
	# p4 resolve

    p4 sync //hw/nvgpu/...@$NVGPU_CL
    p4 sync //dev/inf/FullStackAmodel/nvgpu/...@$NVGPU_CL

    # nvgpu

    p4 integrate -n -b FullStackAmodelNvgpu //dev/inf/FullStackAmodel/nvgpu/...@$NVGPU_CL 2>&1 | tee integrate_changes.plan
	p4 integrate -b FullStackAmodelNvgpu //dev/inf/FullStackAmodel/nvgpu/...@$NVGPU_CL | tee FullStackAmodelNvgpu`date +%m_%d_%y__%H_%M_%S`.log

    # nvgpu_gh100

    p4 integrate -n -b FullStackAmodelNvgpu_gh100 //dev/inf/FullStackAmodel/nvgpu_gh100/...@$NVGPU_CL 2>&1 | tee integrate_changes.plan
	p4 integrate -b FullStackAmodelNvgpu_gh100 //dev/inf/FullStackAmodel/nvgpu_gh100/...@$NVGPU_CL | tee FullStackAmodelNvgpu`date +%m_%d_%y__%H_%M_%S`.log

	p4 resolve -am
	p4 resolve 

    clobber_fsa
    # clean_amodel
    # clobber_fmodel

    build_fsa
    # build_fmodel
    # build_amodel
    # copy files

    # build switch
    cd $nvswitch
    p4 sync //...@$HW_CL; p4 resolve
    p4want $HW_CL

    p4 integ -b FullStackAmodelNvgpu_ls10 //...@$HW_CL 2>&1 | tee switch_`date +%m_%d_%y__%H_%M_%S`.log
	p4 resolve -am
	p4 resolve

    clobber_switch_fmodel
    build_switch_fmodel

    cd $sw
    source ~/.bash_mlwp_aliases
    p4 describe $SW_CL|head -1
    p4 sync @$SW_CL
    p4 resolve
    p4 _revision
    p4want $SW_CL

    clobber_mods

    build_mods

    # fsa_test
    # see https://confluence.nvidia.com/display/HWINFCONTENT/Full+Stack+AModel#FullStackAModel-MaintainingNvgpuBranch
    # fmodel: `depth`/fsa/launchTests --chip gh100 --tgenArgs "-nosandbox -maxFileSize 0 -modsRunspace $MODS_RUNSPACE"
    # fsa:    `depth`/fsa/launchTests $AMODEL_LIBDIR --chip gh100 --tgenArgs "-nosandbox -maxFileSize 0 -modsRunspace $MODS_RUNSPACE"
    # also see $nvgpu/diag/testgen/myruns/hopper/gh100
    # $nvgpu/diag/testgen/myruns/hopper/gh100/switch_sanity/run.sh

    # see $FSA_MAIN/scripts/fsa_host.sh
    #
    # Create code review using swarm: https://confluence.nvidia.com/pages/viewpage.action?pageId=89383742 
    #   #review @erchi, @kevzhang, @saml, @age

    # Test gpu fmodel in nvgpu_gh100 tree 
    # 
    # `depth`/fsa/launchTests fsa --chip gh100 --tgenArgs "-nosandbox -maxFileSize 0 -modsRunspace $MODS_RUNSPACE" xxx
    #
    # Test FSA gpu fmodel in nvgpu_gh100 tree
    #
    # `depth`/fsa/launchTests $AMODEL_LIBDIR --chip gh100 --tgenArgs "-nosandbox -maxFileSize 0 -modsRunspace $MODS_RUNSPACE"
    
    #
    # cd diag/testgen/myruns/hopper/g000/switch_sanity/
    # run.sh
    #
    # `depth`/fsa/launchTests $AMODEL_LIBDIR --chip gh100 --tgenArgs "-nosandbox -maxFileSize 0 -modsRunspace $MODS_RUNSPACE"

    cd $nvswitch
    p4 describe $HW_CL|head -1
    p4 sync @$HW_CL
    p4 resolve -am
	p4 resolve

    p4 integ -n -b FullStackAmodelNvgpu_ls10 @$HW_CL 2>&1 | tee FullStackAmodelNvgpu_ls10_`date +%m_%d_%y__%H_%M_%S`.plan
    p4 integ -b FullStackAmodelNvgpu_ls10 @$HW_CL 2>&1 | tee FullStackAmodelNvgpu_ls10_`date +%m_%d_%y__%H_%M_%S`.log
	p4 resolve -am
	p4 resolve
    clobber_switch_fmodel
    build_switch_fmodel

    cd $nvswitch/diag/testgen/myruns/switch_standalone_as2
    ./run.sh
    cd $nvswitch/diag/testgen/myruns/switch_sanity
    ./run.sh

    # run_driver_tests
}

# https://confluence.nvidia.com/display/HWINFCONTENT/Full+Stack+AModel#FullStackAModel-SyncingandbuildingF+AModel
function fsa_ga100_sync_integrate_build_and_test () {
    # ga100 integrates are frozen always sync nvgpu_ga100 to 49582000 and sync //hw/class/... and //dev/inf/FullStackAmodel/... to TOT
	
    cd $nvgpu

    p4 sync @49582000
	p4 sync //hw/class/...
	p4 sync  //dev/inf/FullStackAmodel/...

	p4 integ -b FullStackAmodel //dev/inf/FullStackAmodel/IDirectAmodel/... 2>&1 | tee IDirectAmodel_`date +%m_%d_%y__%H_%M_%S`.log
	p4 resolve -am
	p4 resolve

	p4 integ -b FullStackAmodel //dev/inf/FullStackAmodel/ampere/... 2>&1 | tee FullStackAmpereAmodel`date +%m_%d_%y__%H_%M_%S`.log
	p4 resolve -am
	p4 resolve

    build_and_test_fmodel
}

# Need .nvprojectname set at top of scratch
# Need to set PROJECT_TEAM := hwinf_content_class in tree.make
# https://wiki.nvidia.com/gpuhwdept/index.php/GPU_Project_Naming_Quick_Start#Set_up_project_naming_for_your_chip_trees
# https://wiki.nvidia.com/gpuhwdept/index.php/GPU_Infrastructure_Group/initiatives/Gfx_Inf_Project_Naming#GPU_Arch_MODS
# https://wiki.nvidia.com/engit/index.php/LSF_FAQ#How.2Fwhy_do_I_set_the_project_name_for_LSF.3F
# https://wiki.nvidia.com/gpuhwdept/index.php/Nvprojectname
#   determine what farmProject should be - gpu_inf_hwinf_chip_sim
# https://wiki.nvidia.com/gpuhwdept/index.php/NvBuild
# https://wiki.nvidia.com/gpuhwdept/index.php/NvBuild/Anatomy_of_a_Project_Name
# PROJECT_TEAM define in tree.make use hwinf_content_mods for mods to identify the GPU_Arch_MODS team
# validate using: 
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

function use_node {
    use_gcc 11.2.0
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
    # nvm install --lts
    nvm use --lts
    
}

# https://confluence.nvidia.com/display/GPUTree/Standard+Nvgpu+Crucible+Templates
function build_init () {
    echo "build_init ...nvgpu=$nvgpu"
    use_gcc
    use_node

    CPU=x86_64
    export BUILD_ARCH=amd64

    P4REVIEW=$P4ROOT_SW/sw/main/apps/p4review
    arch=$P4ROOT_HW/arch
    hw=$P4ROOT_HW/hw
    dev=$P4ROOT_HW/dev
    sw=$P4ROOT_SW/sw
    gpu_drv=$sw/dev/gpu_drv
    export MODS_DIR=$swb/diag/mods

    export FSA_SW_ROOT=$sw

    export NVTEE_LITTER_ROOT=$hw/$NVTEE_LITTER_DIR
    export NVTEE_SWITCH_ROOT=$P4ROOT_SWITCH_HW/hw/$NVTEE_SWITCH_DIR

    export nvgpu=$NVTEE_LITTER_ROOT
    export nvswitch=$NVTEE_SWITCH_ROOT

    echo "nvswitch: nvswitch=$NVTEE_SWITCH_ROOT"

    export MODS_RUNSPACE=$P4ROOT_SW/runspaces/nvgpu_mods/${MODS_BRANCH}_${SW_CL}

    echo "setting AMODEL_LOG_DIR nvgpu=$nvgpu"
    export AMODEL_LOG_DIR=$nvgpu/fsa
    echo "AMODEL_LOG_DIR=$AMODEL_LOG_DIR"

    # see fsa_gh100_sync_integrate_build_and_test
   
    # https://engwiki/index.php/Linux_graphics/unix-build
    # cd /develop/fsf/p4/sw/dev/gpu_drv/chips_a/drivers/vgpu/tools/vmiop-simproc
    # use p4 _templates to get list of templates
    # Run p4 help commands to find the listing of additional crucible commands, and p4 help _templates to find out how to use it.

    if [ "$OSTYPE" == "Win32" ]; then
        echo "running on windows not tested yet"
        return
        arch="Win32"
        archExtraArgs="-a amodWin32"
        visualizations=$P4ROOT_HW/hw/class/$NVTEE_GPU_CLASS/inf/cem/1.1/bin/win32/visualizations.dl
    elif [ "$OSTYPE" == "Win64" ]; then
        echo "running on windows not tested yet"
        return
        arch="Win64"
        archExtraArgs="-a amodWin64"
        visualizations=$P4ROOT_HW/hw/class/$NVTEE_GPU_CLASS/inf/cem/1.1/bin/win64/visualizations.dll
    elif [ `hostname` == "mwoodpatrick--dt-ubuntu" ]; then
        IS_RUNNING_ON_LSF="0"
        arch="Linux"
        archExtraArgs=""
        visualizations=$P4ROOT_HW/hw/class/$NVTEE_GPU_CLASS/inf/cem/1.1/bin/linux32/visualizations.so
        export NVTEE_SYSTYPE=Linux_x86_64
        export NVTEE_PROJECT="gpu_${NVTEE_PLATFORM}_hwinf_content_class"
    else
        # for FSF run need to be on i-sim-11-122, i-sim-11-123, l-sim-152-086
        IS_RUNNING_ON_LSF="1"
        arch="Linux_x86_64"
        archExtraArgs=""
        visualizations=$P4ROOT_HW/hw/class/$NVTEE_GPU_CLASS/inf/cem/1.1/bin/linux32/visualizations.so

        # see record_projectname to setup project naming for new scratch or chip

        export NVTEE_PROJECT=`nvprojectname resolve`
        export NVTEE_SYSTYPE=$arch
    fi

    # export NVTEE_RESULTROOT=$NVTEE_DEVROOT/results
    export NVTEE_RESULTROOT=$nvgpu/diag/testgen/myruns
    mkdir -p $NVTEE_RESULTROOT

    
    if [ ! -d $NVTEE_LITTER_ROOT ]; then
        echo "Invalid litter root $NVTEE_LITTER_ROOT NVTEE_LITTER_DIR=$NVTEE_LITTER_DIR using $altroot!"
    fi

    cd $NVTEE_LITTER_ROOT

    if [ -x bin/getlitters ]; then
        export NVTEE_LITTER=`bin/getlitters $NVTEE_CHIP`
    elif  [ -x bin/rtl/getlitters ]; then
        export NVTEE_LITTER=`bin/rtl/getlitters $NVTEE_CHIP`
    else
        echo "could not determine litter in: $NVTEE_LITTER_ROOT!"
        export NVTEE_LITTER=unknown
    fi

    echo "arch: $BUILD_ARCH platform: $NVTEE_PLATFORM chip: $NVTEE_CHIP litter: $NVTEE_LITTER root: $NVTEE_LITTER_ROOT"

    FMODEL_CHIPLIB_RELEASE=${NVTEE_LITTER}_fmodel_64
    FMODEL_CHIPLIB_DEBUG=${NVTEE_LITTER}_debug_fmodel_64

    clib=$nvgpu/clib
    O_CPU_QUEUE="o_cpu"
    O_IDLE_QUEUE="o_cpu_idle"
    
    NV_PARALLELMAKE=1

    PS1="nvtee $NVTEE_PLATFORM \t> "

    echo "PROJECT=$NVTEE_PROJECT class=$NVTEE_GPU_CLASS"

    export AS2_O_CPU_QUEUE=o_cpu

    # https://wiki.nvidia.com/engwiki/index.php/P4review_on_Linux
    # p4rmerge -text /home/scratch.mwoodpatrick/fsf/diffs/cl-30817674.p4r

    # alias p4review='$P4REVIEW/p4review.pl'
    # alias p4rmerge='$P4REVIEW/p4rmerge.pl -text' # -text <p4rpath>
    export P4REVIEW=$sw/main/apps/p4review
    # export PATH=$sw/mods/tools/hm:/home/utils/vim-7.4/bin:$MODS_RUNSPACE:$hw/tools/imgtools/bin:$P4REVIEW:/home/nv/utils/hwmeth/bin:$PATH_BASE
    # reset PATH to use gcc
    alias glivd=$hw/tools/imgtools/bin/glivd
    unset NVTEE_PAUSE_ON_START
    echo "nvtee initialized hw=$hw sw=$sw runspace=$MODS_RUNSPACE"

    NVTEE_FMODEL_DIR=$NVTEE_LITTER_ROOT
    export FSA_FMODEL=fsa_${HW_CL}_${FSA_CL}
    export FSF_FMODEL=${HW_CL}

# Handyman - versatile helper script
# https://confluence.nvidia.com/display/CORERM/RM+Handyman
# is bash script in //sw/mods/tools/hm/hm
# hm needs export P4ROOT=$P4ROOT_SW
# FYI many people on our team use a script to submit changes for review. This script does a couple of useful things:
# 1)	It runs a basic style checker on the files changed.
# 2)	It generates a P4R.
# 3)	It generates a Swarm review which includes the P4R in the description.

# Someone may find it useful.

# You have to sync //sw/mods/tools/hm/¿ and then invoke it like this:

# hm review

# It will ask you which local CL you want to submit for review. You can also pass CL number as argument. 
# hm review 22901954

# The script works both on Linux and Windows.
# setenv PATH "$PATH:$P4ROOT/sw/mods/tools/hm"
# handyman needs python3
# export PATH=/home/utils/Python-3.7.3/bin:$sw/dev/gpu_drv/chips_a/drivers/resman/tools/handyman:$PATH
    export PATH=/home/utils/tar-1.26/bin:/home/utils/Python-3.8.0/bin:$sw/dev/gpu_drv/chips_a/drivers/resman/tools/handyman:$PATH
            echo "setting P4ROOT=$P4ROOT_SW needed by handyman"
            export P4ROOT=$P4ROOT_SW

            determine_changelists
    export PROJECT_NAME=`nvprojectname resolve`
}

function clobber_fmodel () {
    cd $nvgpu
    nvmk clobber
}

# etc/gpu_to_litter.config contains mapping of gpu values to litter values
# https://confluence.nvidia.com/display/GPUTree/Working+in+the+NVGPU+Mainline#WorkingintheNVGPUMainline-Buildthetree
# https://wiki.nvidia.com/gpuhwmaxwell/index.php/Nvgpu_build
# https://wiki.nvidia.com/gpuhwdept/index.php/GoldenCl/UserDoc
# Make sure NV_ALWAYSDEBUGSYMBOLS is enabled in tree.make
# Ampere Host CSLs https://confluence.nvidia.com/display/AMPESCHED/Ampere+Host+CSLs
function build_fmodel () {
    # ensure we have resolved files before trying to build
    # need projectname set see record_projectname

    p4 resolve
    WD=$NVTEE_LITTER_ROOT
    echo "building fmodel in $WD ..."
    pushd $WD
    # rm -rf .tmake
    # does bin/t_make -build fmod -build rtl -project gm20b -project gm20b_debug
    # WARNING: -skipmods is obsolete option and will be removed soon, please use '-skip mods' instead

    # nvmk fmodel -skip mods -scheduler_args trace=.tmake/DagScheduler.log
    # bin/t_make -build fmod -skip mods 2>&1 | tee build_fmodel.log
    bin/t_make --noautofetch --nobuildchecksum --skiprtl -nodispatch --build fmod -skip mods 2>&1 | tee build_fmodel.log
    ls -l $NVTEE_LITTER_ROOT/clib/Linux_x86_64 | grep fmodel
    file $NVTEE_LITTER_ROOT/clib/Linux_x86_64/* | grep fmodel
    echo "see `pwd`/tmake.out for details"
    popd
}

function sync_switch_fmodel () {
    cd $nvswitch
    p4 sync $P4ROOT_SWITCH_HW/...@$HW_CL; p4 resolve
    p4 sync @$HW_CL
	p4 resolve -am
	p4 resolve
    p4 _revision
    p4 describe $HW_CL|head -1
}

function clobber_switch_fmodel () {
    cd $nvswitch
    nvmk clobber
}

# Chris Fairfax <cfairfax@nvidia.com>
# if you want to build chiplib_sf:
#
# cd //hw/nvgpu/diag/chiplib_sf/
# nvmk -c .

function build_switch_fmodel () {
    # ensure we have resolved files before trying to build
    cd $nvswitch;
    p4 resolve
    WD=$nvswitch
    echo "building fmodel in $WD ..."
    pushd $WD
    # rm -rf .tmake
    # does bin/t_make -build fmod -build rtl -project gm20b -project gm20b_debug
    # WARNING: -skipmods is obsolete option and will be removed soon, please use '-skip mods' instead

    # nvmk fmodel -skip mods -scheduler_args trace=.tmake/DagScheduler.log
    bin/t_make -build fmod -skip mods 2>&1 | tee build_switch_fmodel.log
    ls -l $NVTEE_LITTER_ROOT/clib/Linux_x86_64 | grep fmodel
    file $NVTEE_LITTER_ROOT/clib/Linux_x86_64/* | grep fmodel
    echo "see `pwd`/tmake.out for details"
    popd
}

function clobber_mods () {
    cd $MODS_DIR
    # make BUILD_OS=sim INCLUDE_MDIAG=true INCLUDE_OGL=true INCLUDE_RTAPI=false -j8 submake.resman.clean

    make INCLUDE_CUDA=false clean_all
    make INCLUDE_CUDA=false clobber_all
    rm -rf artifacts/
    make INCLUDE_CUDA=false check_client
    echo "need to update any custom chiplibs"
}

function build_sockchip_internal () {
    pushd $sw/mods/chiplib/sockchip
    echo building sockchip BUILD_CFG=$BUILD_CFG BUILD_ARCH=$BUILD_ARCH
    LOGPATH=`pwd`/build_sockchip_${BUILD_ARCH}_${BUILD_CFG}.log
    make SHOW_OUTPUT=true 2>&1 | tee $LOGPATH

    if [[ "$BUILD_CFG" = "release" ]] ;
    then
        p4 edit $swb/diag/mods/sim/$BUILD_ARCH/sockchip.so
        cp -p $swb/diag/mods/artifacts/release/sim/$BUILD_ARCH/sockchip/sockchip.so $swb/diag/mods/sim/$BUILD_ARCH/sockchip.so
        # make system seems to make sockchip.so executable but then fails building
        # mods if it is
        chmod uga-x $swb/diag/mods/sim/$BUILD_ARCH/sockchip.so
        p4 edit $swb/diag/mods/sim/$BUILD_ARCH/sockserv64
        cp -p $swb/diag/mods/artifacts/release/sim/$BUILD_ARCH/sockchip/sockserv $swb/diag/mods/sim/$BUILD_ARCH/sockserv64
    fi

    make SHOW_OUTPUT=true install 2>&1 | tee -a $LOGPATH

    cp -p $swb/diag/mods/artifacts/${BUILD_CFG}/sim/${BUILD_ARCH}/sockchip/sockserv $MODS_RUNSPACE/sockserv64
    cp -p $swb/diag/mods/artifacts/${BUILD_CFG}/sim/${BUILD_ARCH}/sockchip/sockchip.so $MODS_RUNSPACE

    echo "build log in $LOGPATH"
    popd
}

function build_release_sockchip () { # generate sockchip.so & sockserv64
    BUILD_CFG=release build_sockchip_internal
    cmp $sw/dev/gpu_drv/chips_a/diag/mods/artifacts/release/sim/$BUILD_ARCH/sockchip/sockchip.so $MODS_RUNSPACE/sockchip.so
    cmp $sw/dev/gpu_drv/chips_a/diag/mods/artifacts/release/sim/$BUILD_ARCH/sockchip/sockserv $MODS_RUNSPACE/sockserv64
}

function build_debug_sockchip () { # generate sockchip.so & sockserv64
    BUILD_CFG=debug build_sockchip_internal
    echo "copying debug sockchip files ..."
    chmod +w $MODS_RUNSPACE/sockchip.so
    cp -p $swb/diag/mods/artifacts/debug/sim/$BUILD_ARCH/sockchip/sockchip.so $MODS_RUNSPACE
    ls -l $MODS_RUNSPACE/sockchip.so
    chmod +w $MODS_RUNSPACE/sockserv64
    cp -p $swb/diag/mods/artifacts/debug/sim/$BUILD_ARCH/sockchip/sockserv $MODS_RUNSPACE/sockserv64
    ls -l $MODS_RUNSPACE/sockserv64
}

function build_hwchip2_internal () {
    cd $sw/mods/chiplib/hwchip2
    echo building hwchip2 BUILD_CFG=$BUILD_CFG BUILD_ARCH=$BUILD_ARCH
    LOGPATH=`pwd`/build_hwchip2_${BUILD_ARCH}_${BUILD_CFG}.log
    make SHOW_OUTPUT=true 2>&1 | tee $LOGPATH

    if [[ "$BUILD_CFG" = "release" ]] ;
    then 
        p4 edit $swb/diag/mods/sim/${BUILD_ARCH}/hwchip2.so
        cp -p $swb/diag/mods/artifacts/${BUILD_CFG}/sim/${BUILD_ARCH}/hwchip2/hwchip2.so $swb/diag/mods/sim/${BUILD_ARCH}/hwchip2.so
        chmod uga-x $swb/diag/mods/sim/${BUILD_ARCH}/hwchip2.so
    fi

    make SHOW_OUTPUT=true install 2>&1 | tee -a $LOGPATH

    cp -p $swb/diag/mods/artifacts/${BUILD_CFG}/sim/${BUILD_ARCH}/hwchip2/hwchip2.so $MODS_RUNSPACE

    echo "build log in $LOGPATH"
 }

function build_hwchip2 () {
    BUILD_CFG=release BUILD_ARCH=amd64 build_hwchip2_internal
    BUILD_CFG=debug BUILD_ARCH=amd64 build_hwchip2_internal
}

# https://wiki.nvidia.com/engwiki/index.php/MODS/Compiling_and_Running_MODS
function build_mods_internal () {
    cd $MODS_DIR
    echo SW_CL=${SW_CL}
    echo MODS_RUNSPACE=${MODS_RUNSPACE}
    # make BUILD_OS=sim INCLUDE_MDIAG=true INCLUDE_OGL=true INCLUDE_RTAPI=false INCLUDE_NVWATCH=false INCLUDE_CUDA=false -j8 build_all 2>&1 | tee build.log
    # make BUILD_OS=sim INCLUDE_MDIAG=true INCLUDE_RTAPI=false INCLUDE_NVWATCH=false -j8 build_all 2>&1 | tee build.log
    # INCLUDE_MDIAG=true INCLUDE_NVWATCH=true INCLUDE_RMTEST=true
    # INCLUDE_VGPU_PLUGIN=true BUILD_OS=sim INCLUDE_MDIAG=true INCLUDE_NVWATCH=true INCLUDE_RMTEST=true INCLUDE_OGL=false INCLUDE_CUDA=false make -j8 build_all
    INCLUDE_VGPU_PLUGIN=true BUILD_OS=sim INCLUDE_MDIAG=true INCLUDE_RMTEST=true INCLUDE_OGL=false INCLUDE_CUDA=false make -j8 build_all
    ls -lrt $MODS_RUNSPACE/mods

    # There is no hwchip.so in the MODS_RUNSPACE and we don't use that file but emu.pl complains if it does not exist
    echo creating dummy hwchip.so to keep emu.pl happy
    touch $MODS_RUNSPACE/hwchip.so
    echo created dummy hwchip.so to keep emu.pl happy

    # generate documentation
    LD_LIBRARY_PATH=$MODS_RUNSPACE $MODS_RUNSPACE/mods -h > $MODS_RUNSPACE/mods_options.txt
    ls -l $MODS_RUNSPACE/mods_options.txt

    LD_LIBRARY_PATH=$MODS_RUNSPACE $MODS_RUNSPACE/mods mdiag.js --tests > $MODS_RUNSPACE/mdiag.tests.txt
    ls -l $MODS_RUNSPACE/mdiag.tests.txt

    LD_LIBRARY_PATH=$MODS_RUNSPACE $MODS_RUNSPACE/mods mdiag.js --args mdiag > $MODS_RUNSPACE/mdiag_options.txt
    ls -l $MODS_RUNSPACE/mdiag_options.txt

    LD_LIBRARY_PATH=$MODS_RUNSPACE $MODS_RUNSPACE/mods mdiag.js --args gpu > $MODS_RUNSPACE/gpu_options.txt
    ls -l $MODS_RUNSPACE/gpu_options.txt

    LD_LIBRARY_PATH=$MODS_RUNSPACE $MODS_RUNSPACE/mods mdiag.js --args trace_3d > $MODS_RUNSPACE/trace_3d_options.txt
    ls -l $MODS_RUNSPACE/trace_3d_options.txt

    # LD_LIBRARY_PATH=.:$(NV_TOP)/clib/Linux_x86_64:$(MODS_RUNSPACE):/home/utils/gcc-4.6.0/lib64 ldd $(MODS_RUNSPACE)/mods &> ldd_mods.txt

    # use latest versions of chiplibs (not the ones checked in)

    build_hwchip2

    build_debug_sockchip

    # keep files from hw tree build seperate from sw tree build by default

    # need to build on machine with cronus headers
    # build_cronuschip

    # copy chiplib_e files
    # generate_hw_chiplib_e $MODS_RUNSPACE

    # build_and_install_trace_3d_plugins
}

# http://dvstransfer.nvidia.com/dvsshare/dvs-binaries/gpu_drv_r384_00_Debug_Linux_Mods_Simulator/
function build_mods () {
    p4 resolve
    mkdir -p $MODS_RUNSPACE
    date=`date +%b_%d_%H_%M_%S`
    LOGPATH=$MODS_RUNSPACE/build_mods_${date}.log
    build_mods_internal 2>&1 | tee $LOGPATH

    # doing this caused problems when nvsim got updated may want to review doing this
    # also caused problems when using someone else's fmodel
    # cp -pr $nvgpu/clib/Linux_x86_64/*.so $MODS_RUNSPACE
    # cp -p $nvgpu/clib/Linux_x86_64/sriov_test_64.so $MODS_RUNSPACE
    # ls -l $MODS_RUNSPACE/sriov_test_64.so
    # cp -p $nvgpu/clib/Linux_x86_64/cpu_access_compressed_surface_64.so $MODS_RUNSPACE
    # ls -l $MODS_RUNSPACE/cpu_access_compressed_surface_64.so
    # cp -p $nvgpu/clib/Linux_x86_64/sec_test_64.so $MODS_RUNSPACE
    # ls -l $MODS_RUNSPACE/sec_test_64.so
    # cp -p $nvgpu/clib/Linux_x86_64/ecc_error_containment_64.so $MODS_RUNSPACE
    # ls -l $MODS_RUNSPACE/ecc_error_containment_64.so
    # cp -p $swb/diag/mods/gpu/js/cur_comm.h $MODS_RUNSPACE
    # ls -l $MODS_RUNSPACE/cur_comm.h

    # copy all trace_3d plugins
    # doing this caused problems when nvsim got updated may want to review doing this
    # also caused problems when using someone else's fmodel
    # cp -p $nvgpu/clib/Linux_x86_64/*.so $MODS_RUNSPACE
    # need better process
    cp $MODS_RUNSPACE/hwchip2.so $MODS_RUNSPACE/hwchip.so
    ls -lrt $MODS_RUNSPACE/mods
    echo "build log in $LOGPATH"
}

function hopper_init () {
    echo "hopper_init ..."
    LEVEL=graphics_sanity
    export NVTEE_GPU_CLASS=hopper
    build_init
    export AMODEL_LIBDIR=$P4ROOT_HW/hw/class/$NVTEE_GPU_CLASS/amod/code/bin/Linux-x64-Debug/
}

function ampere_init () {
    echo "ampere_init ..."
    LEVEL=graphics_sanity
    export NVTEE_GPU_CLASS=ampere
    build_init
    export AMODEL_LIBDIR=$P4ROOT_HW/hw/class/$NVTEE_GPU_CLASS/amod/code/bin/Linux_x86_64/Debug_gcc_550_x64
}

function gh100_init () {
    echo "gh100_init ..."
    export NVTEE_CHIP=gh100
    export NVTEE_PLATFORM=gh100
    export NVTEE_LITTER_DIR=nvgpu_gh100

    export NVTEE_SWITCH_CHIP=ls10
    export NVTEE_SWITCH_PLATFORM=ls10
    export NVTEE_SWITCH_DIR=nvgpu_ls10
    
    hopper_init

    source $nvgpu/fsa/build_and_test_common.sh
}

function ga100_init () {
    echo "ga100_init ..."
    export NVTEE_CHIP=ga100
    export NVTEE_PLATFORM=ga100
    export NVTEE_LITTER_DIR=nvgpu_ga100

    export NVTEE_SWITCH=lr10
    export NVTEE_SWITCH_PLATFORM=lr10
    export NVTEE_SWITCH_DIR=nvgpu_lr10

    ampere_init
}

# 	nvrun -tool=echo gdb
#		Reports version in tool_data.config
# currently /home/utils/gdb-8.3.1-2/bin/gdb 

function use_gcc () {
    export GCC_VERSION=${1:-5.5.0}
    GCC_DIR=/home/utils/gcc-$GCC_VERSION
    # also see nvgdb https://wiki.nvidia.com/fermi/index.php/Infrastructure/FModel_Debugability/NVGDB
    # export PATH=$GCC_DIR/bin:$PATH_BASE
    echo ".bash_aliases: use_gcc (version=${GCC_VERSION}: Updating path was: $PATH"
    export PATH=$GCC_DIR/bin:$PATH_BASE
    # export PATH=/home/utils/gdb-7.12.1/bin:$PATH
    # export PATH=/home/utils/gdb-8.2.1/bin:$PATH
    # export PATH=/home/utils/gdb-8.3.1/bin:$PATH
    # export PATH=/home/utils/gdb-8.3.1-2/bin:$PATH
    # export PATH=/home/utils/gdb-9.2/bin:$PATH
    export MODS_GDB_PATH=/home/utils/gdb-10.1/bin
    export PATH=$MODS_GDB_PATH:$PATH
    export PATH=/home/utils/ddd-3.3.12/bin:$PATH
    export PATH=/home/utils/make-4.10/bin:$PATH
    export PATH=/home/utils/valgrind-3.11.0/bin:$PATH
    export PATH=/home/utils/ctags-5.8/bin:$PATH
    export PATH=/home/utils/git-2.35.1/bin:$PATH
    
    # ensure we are using crucible based p4
    # You should create a crucible client that uses one of the standard templates
    #   https://confluence.nvidia.com/display/GPUTree/Working+in+the+NVGPU+Mainline#WorkingintheNVGPUMainline-CreateaCrucibleClient
    #
    # For building/running fmodel tests use the "nvgpu.arch_fmodel" template:
    #   https://wiki.nvidia.com/gpuhwdept/index.php/Workflows/Crucible
    #   https://confluence.nvidia.com/display/GPUTree/Standard+Nvgpu+Crucible+Templates#StandardNvgpuCrucibleTemplates-Fmodel
    #   https://confluence.nvidia.com/display/SCMU/Contacting+the+SCM+Team+for+P4+and+Git+Support

    echo "using crucible based p4"
    export PATH=/home/nv/utils/crucible/1.0/bin:$PATH

    export LD_LIBRARY_PATH=$GCC_DIR/lib64:$LD_LIBRARY_PATH_BASE
    export CC=$GCC_DIR/bin/gcc
    export CXX=$GCC_DIR/bin/g++
    show_paths
}

# use_gcc # setup default version of gcc

# Meyers, Scott. Effective Modern C++: 42 Specific Ways to Improve Your Use of C++11 and C++14
# This https://gcc.gnu.org/projects/cxx-status.html#cxx14 says any version of g++ above 5.0 has full support, 
# and we have several of those versions under /home/utils/. 
# Nowadays compilers expect you to set the standard version on the command-line and not rely on the default dialect. 
# Once you do that, your extra benefit is that your code is less likely to break accidentally in the future, 
# you won't get your dialect upgraded without you choosing it.
# -std=c++11
# -std=c++14
#
# Clang++ is under /home/utils/llvm-{version}/bin.
# Except /home/utils/llvm-3.9.0, it seems.
#
# http://stackoverflow.com/questions/24813827/cmake-failing-to-detect-pthreads-due-to-warnings/25130590#25130590

function effcpp () {
    cd /home/mwoodpatrick/effective_c++
    # https://cmake.org/cmake/help/v3.6/manual/cmake.1.html
    # see https://cmake.org/Wiki/CMake_Useful_Variables
    # CMakeCache.txt contains the projects configuration
    use_gcc 5.3.0
    # Hopper uses boost 1.78.0 and the class tree in general uses boost 1.68.0
    export BOOST_ROOT=/home/mwoodpatrick/effective_c++/boost_1_62_0
    cmake-3.6.2-Linux-x86_64/bin/cmake Effective-Modern-Cpp-master
    # generates CMakeFiles/CMakeOutput.log CMakeFiles/CMakeError.log
    make -d -S 2>&1 | tee make.out  
    # make clean
}

fetch_ws() {
    export P4CLIENT_HW=mwoodpatrick_fetch_ws
    export P4ROOT_HW=/home/scratch.mwoodpatrick/fetch_ws
    . ~/nvtee_setup
    export NVTEE_CHIP=gp100
    export NVTEE_PLATFORM=gp100
    export NVTEE_LITTER_DIR=nvgpu_gmlit4
    # needed since otherwise run into using altroot in ~/nvtee_setup, remove this check
    export NVTEE_LITTER_ROOT=$P4ROOT_HW/hw/$NVTEE_LITTER_DIR
    pascal_init
    mkdir -p $P4ROOT_HW
    cd $P4ROOT_HW
}

# http://unix.stackexchange.com/questions/3961/how-to-understand-whats-taking-up-space
# http://www.makeuseof.com/tag/how-to-analyze-your-disk-usage-pattern-in-linux/
# du -s -m -x * | sort -n
function dus() {
    cd $1
    date=`date +%b_%d_%H_%M_%S`
    du  | sort  --reverse --numeric-sort --output=du_sorted_${date}.txt
}

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    # alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# TODO set DISPLAY env var to include hostname `hostname`$DISPLAY so that the new session has its DISPLAY environment session set correctly
# need to check if DISPLAY starts with a ':' in that case prepend with hostname see http://stackoverflow.com/questions/28514484/bash-how-to-check-if-a-string-starts-with and http://www.linuxjournal.com/content/return-values-bash-functions
# 
# /usr/bin/ssh -X forge14 does enable X11 forwarding 
# see http://askubuntu.com/questions/35512/what-is-the-difference-between-ssh-y-trusted-x11-forwarding-and-ssh-x-u
alias sshx='/usr/bin/ssh -X'

function fullDisplayName()
{
    local d=$DISPLAY

    if [[ $d = \:* ]] ; then
        d=`hostname`$d
    fi

    echo "$d"
}

# /home/utils/bin/konsole is a wrapper script required for "rel68" machine/xterm's and not for rel57 xterm's
# alt use dbus-launch gbk_8G tested with this
# https://nvidiaprod.service-now.com/nav_to.do?uri=%2Fincident.do%3Fsys_id%3Da22673d837102fc07be753b543990e21%26sysparm_stack%3Dincident_list.do%3Fsysparm_query%3Dactive%3Dtrue
# You are not required to specify a time limit, but will get somewhat better dispatch time. For testing a job or two, I would recommend using one of the o_pri_cpu queues. You can submit an interactive job (e.g., konsole) just like o_pri_interactive.
# 
# list_queues -p o_pri_cpu
# list_queues -p o_cpu_32G 
# rel5=old OS
# For multi gpu FSF testing use: sub -q o_pri_cpu_64G -n 6 -R 'span[hosts=1]' konsole
# CentOS 7
#   QSUB_DEFAULT_OS=rel75 qsub -q o_pri_interactive_cpu_16G -Is tcsh


# /home/utils/binutils-2.24/bin/readelf --debug-dump=info nv_tee.so > junk 
alias elfinfo="readelf --debug-dump=info"
# http://stackoverflow.com/questions/34732/how-do-i-list-the-symbols-in-a-so-file
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

# makepp contact Brian Walker <bwalker@nvidia.com>
# http://makepp.sourceforge.net/1.40/makepp_tutorial.html
# http://search.cpan.org/dist/makepp/pod/makepp_variables.pod
# http://search.cpan.org/~pfeiffer/makepp-2.0.98.3/pod/makepp_tutorial.pod
# http://search.cpan.org/~pfeiffer/makepp-2.0.98.3/pod/makepp_cookbook.pod
# alias makepp="nvrun makepp"
# alias makepp=/home/nv/utils/makepp/makepp-100712.hf27/bin/makepp
alias makepp=/home/nv/utils/makepp/makepp-120815.hf3/bin/makepp

# cp4 info
# cp4 set

unset P4DIFF
if [ `hostname` = "mwoodpatrick--dt-ubuntu.nvidia.com" ]; then
    echo "running on"  `hostname`
elif [ "$OSTYPE" = "Linux" ]; then
    # alias cp4="/home/nv/utils/crucible/1.0/bin/p4 -d \`/bin/pwd\`"
    # alias p4="/home/nv/utils/crucible/1.0/bin/p4 -d \`/bin/pwd\`"
    echo "running on"  `hostname`
fi

if [ -x depth ] && -f "`depth`/bin/make" ]; then
    alias make="`depth`/bin/make"
fi

# "lshosts" provides information about the machines that LSF is aware of.
# "bhosts" provides information about the status of those machines in the queue
#  bqueues 	displays information about queues
#  bjobs		displays information about LSF jobs
#  bkill <id>	sends signals to kill, suspend, or resume unfinished jobs
#  bpeek <id>   displays the stdout and stderr output of an unfinished job
#  bsub -Is csh start interactive shell for debugging.
# how lsf is ranking (prioritizing) the various queues (that you submitted to):
# bqueues -l medium

function gdb_path {
    if [ -d /home/utils ]; then
        export GDB_PATH="$(ls -d /home/utils/gdb-* | sort -g -t . -k 2 | tail -n 1)/bin"
        echo GDB_PATH=$GDB_PATH
    fi
}

# FSA Integrations:
# 
# instructions: https://confluence.nvidia.com/display/HWINFCONTENT/Full+Stack+AModel#FullStackAModel-MaintainingNvgpuBranch
# After submitting, please update CLs documented here: https://confluence.nvidia.com/display/HWINFCONTENT/Full+Stack+AModel#FullStackAModel-SyncingandbuildingF+AModel
# Log work for this here: https://jirasw.nvidia.com/browse/FSA-65
# Send mail to group notifying folks of change
#

function fsa_nvgpu_ga100_tree1 {
    export P4CLIENT_HW=mwoodpatrick_amodel.fullstack.ga100_tree1
    export P4ROOT_HW=/home/scratch.mwoodpatrick_gpu_1/trees/fsa_nvgpu_ga100

    export P4CLIENT_SWITCH_HW=mwoodpatrick_amodel.fullstack.lr10_tree1
    export P4ROOT_SWITCH_HW=/home/scratch.mwoodpatrick_gpu_1/trees/fsa_nvgpu_lr10

    export KVM_FSA_TOP_DIR=$P4ROOT_HW # used by $dev/inf/FullStackAmodel/AutoTesting/Scripts/host.sh

    # nvgpu_ga100 HW_CL is frozen to 49582000 we sync latest amodel changes
    export SW_CL=30294173 # to match gh100

    # see fsa_ga100_sync_integrate_build_and_test
}

function hw_cl_58782346 {
    # nvrun golden_cl status --customer nvgpu_gh100_hsmb
    #	HW_CL=58782346 SW_CL=30694596 Wed 11/24/21 02:52:26
    #
    # nvrun golden_cl status --customer nvgpu_gh100
    #   HW_CL=58706460 SW_CL=30680487 Sat 11/20/21 01:04:08

    export HW_CL=58782346 # 2021/11/23 23:47:16
    export SW_CL=30694596 # 2021/11/24 02:25:11

    export FSA_CL=$HW_CL
    export NVGPU_CL=$HW_CL

    echo "setting golden cl: HW_CL=$HW_CL  SW_CL=$SW_CL"
}

function hw_cl_58956388 {
    # nvrun golden_cl status --customer nvgpu_gh100_hsmb
    #	HW_CL=58956388 SW_CL=30735309 Fri 12/03/21 13:57:05
    #
    # nvrun golden_cl status --customer nvgpu_gh100
    #   HW_CL=58967998 SW_CL=30736610 Sun 12/05/21 01:08:21

    export HW_CL=58956388 # 2021/12/03 12:27:11
    export SW_CL=30735309 # 2021/12/03 12:59:32

    export FSA_CL=$HW_CL
    export NVGPU_CL=$HW_CL

    echo "setting golden cl: HW_CL=$HW_CL  SW_CL=$SW_CL"
}

function hw_cl_59129078 {
    # nvrun golden_cl status --customer nvgpu_gh100_hsmb
    #	HW_CL=59056856 SW_CL=30759862 Thu 12/09/21 11:53:42
    #
    # nvrun golden_cl status --customer nvgpu_gh100
    #   HW_CL=59129078 SW_CL=30774401 Tue 12/14/21 01:21:34

    export HW_CL=59129078 # 2021/12/14 00:30:31
    export SW_CL=30774401 # 2021/12/03 12:59:32

    export FSA_CL=$HW_CL
    export NVGPU_CL=$HW_CL

    echo "setting golden cl: HW_CL=$HW_CL  SW_CL=$SW_CL"
}

function hw_cl_59253580 {
    # nvrun golden_cl status --customer nvgpu_gh100_hsmb
    # HW_CL=59253580 SW_CL=30801403 Mon 12/20/21 16:51:55

    export HW_CL=59253580 # 2021/12/20 13:53:34
    export SW_CL=30801403 # 2021/12/20 14:25:05

    export FSA_CL=$HW_CL
    export NVGPU_CL=$HW_CL

    echo "setting golden cl: HW_CL=$HW_CL  SW_CL=$SW_CL"
}

function hw_cl_59480629 {
    # nvrun golden_cl status --customer nvgpu_gh100 (since customer nvgpu_gh100_hsmb is to old)
    # HW_CL=59480629 SW_CL=30832282 Tue 01/04/22 01:17:53

    export HW_CL=59480629 # 2022/01/04 00:14:04
    export SW_CL=30832282 # 2022/01/03 09:00:33

    export FSA_CL=$HW_CL
    export NVGPU_CL=$HW_CL

    echo "setting golden cl: HW_CL=$HW_CL  SW_CL=$SW_CL"
}

function hw_cl_59500318 {
    # nvrun golden_cl status --customer nvgpu_gh100_hsmb
    # HW_CL=59500318 SW_CL=30837330 Tue 01/04/22 20:53:20

    export HW_CL=59500318 # 2022/01/04 19:49:33
    export SW_CL=30837330 # 2022/01/04 19:49:32

    export FSA_CL=$HW_CL
    export NVGPU_CL=$HW_CL

    echo "setting golden cl: HW_CL=$HW_CL  SW_CL=$SW_CL"
}

function hw_cl_59676599 {
    # nvrun golden_cl status --customer nvgpu_gh100_hsmb
    # HW_CL=59676599 SW_CL=30867297 Wed 01/12/22 11:03:56

    export HW_CL=59676599 # 2022/01/12 10:49:16
    export SW_CL=30867297 # 2022/01/12 10:49:11

    export FSA_CL=$HW_CL
    export NVGPU_CL=$HW_CL

    echo "setting golden cl: HW_CL=$HW_CL  SW_CL=$SW_CL"
}

function hw_cl_59880475 {
    # nvrun golden_cl status --customer nvgpu_gh100
    # HW_CL=59837453 SW_CL=30890746 Thu 01/20/22 01:20:02

    export HW_CL=59880475 # my change for review 59278305 2022/01/21 03:43:21
    export SW_CL=30890746 # 2022/01/19 03:00:39

    export FSA_CL=$HW_CL
    export NVGPU_CL=$HW_CL

    echo "setting golden cl: HW_CL=$HW_CL  SW_CL=$SW_CL"
}

function hw_cl_59891978 {
    # nvrun golden_cl status --customer nvgpu_gh100
    # HW_CL=59837453 SW_CL=30890746 Thu 01/20/22 01:20:02

    export HW_CL=59891978 # change 59891978 on 2022/01/21 13:05:09 added option --dynamic-runtime to enable dynamic linking
    export SW_CL=30890746 # 2022/01/19 03:00:39

    export FSA_CL=$HW_CL
    export NVGPU_CL=$HW_CL

    echo "setting golden cl: HW_CL=$HW_CL  SW_CL=$SW_CL"
}

function hw_cl_59891978 {
    # nvrun golden_cl status --customer nvgpu_gh100
    # HW_CL=59938307 SW_CL=30906834 Mon 01/24/22 01:32:31
    # nvrun golden_cl status --customer nvgpu_gh100_hsmb
    # HW_CL=59859908 SW_CL=30896970 Thu 01/20/22 08:52:45

    export HW_CL=59938307 # 2022/01/23 22:34:35
    export SW_CL=30906834 # 2022/01/23 18:35:11

    export FSA_CL=$HW_CL
    export NVGPU_CL=$HW_CL

    echo "setting golden cl: HW_CL=$HW_CL  SW_CL=$SW_CL"
}

function fsa_nvgpu_gh100_tree1 {
    export P4CLIENT_HW=mwoodpatrick_amodel.fullstack.gh100_tree1
    export P4ROOT_HW=/home/scratch.mwoodpatrick_gpu/trees/fsa_nvgpu_gh100

    export P4CLIENT_SWITCH_HW=mwoodpatrick_amodel.fullstack.ls10_tree1
    export P4ROOT_SWITCH_HW=/home/scratch.mwoodpatrick_gpu_1/trees/fsa_nvgpu_ls10

    export KVM_FSA_TOP_DIR=$P4ROOT_HW # used by $dev/inf/FullStackAmodel/AutoTesting/Scripts/host.sh

    # hw_cl_59500318
    # hw_cl_59676599
    # hw_cl_59880475
    # hw_cl_59891978
    hw_cl_59891978
    
    # see fsa_gh100_sync_integrate_build_and_test
}

function fsa_nvgpu_gh100_tree2 {
    export P4CLIENT_HW=mwoodpatrick_amodel.fullstack.gh100_tree2
    export P4ROOT_HW=/home/scratch.mwoodpatrick_gpu/trees/fsa_nvgpu_gh100_tree2

    export P4CLIENT_SWITCH_HW=mwoodpatrick_amodel.fullstack.ls10_tree2
    export P4ROOT_SWITCH_HW=/home/scratch.mwoodpatrick_gpu_1/trees/fsa_nvgpu_ls10_tree2

    export KVM_FSA_TOP_DIR=$P4ROOT_HW # used by $dev/inf/FullStackAmodel/AutoTesting/Scripts/host.sh

    hw_cl_59253580

    # see fsa_gh100_sync_integrate_build_and_test
}

# https://confluence.nvidia.com/pages/viewpage.action?spaceKey=CSS&title=New+Team+Member+Guide#NewTeamMemberGuide-BuildingCUDADriver
# https://confluence.nvidia.com/display/CSS/nvmake+for+GPGPU contact Mark Vaz (mailto:mavaz@nvidia.com)
# https://confluence.nvidia.com/display/CORERM/unix-build+and+LSF
# https://wiki.nvidia.com/nvcompute/index.php/GPGPU/BuildingCuda#Building_the_CUDA_runtime.2C_libraries_and_tests
# Some of the information on the web page is outdated, and most of them remains useful. We also use this confluence page: 
# https://confluence.nvidia.com/display/CSSKB/Build+CUDA+Driver, although it mostly contains duplicate information.
# See One Note FSF Building components
# //sw/dev/gpu_drv/chips_a/diag/mods/tools/nvmake uses $P4ROOT/sw/tools/unix/hosts/Linux-x86/unix-build/bin/nvmake
# For more information, see https://nvbugs/3312795
# Send handyman questions to slack group

function launch_driver_konsole {
    QSUB_DEFAULT_OS=rel75 TMOUT=1800 qsub -U spike_unix_build -app affinity -q o_cpu_16G_8H -n 8 -R "select[defined(affinity)] span[hosts=1] affinity[core(1):membind=localprefer]" -S 32000 -Is konsole

    # QSUB_DEFAULT_OS=rel75 TMOUT=1800 qsub -U spike_unix_build -q o_cpu_16G_8H -n 8 -R "select[defined(affinity)] span[hosts=1] affinity[core(1):membind=localprefer]" -S 32000 -P ${PROJECT_NAME}
}

function driver_build_init {
    export DRV_BUILD_TYPE=debug
    export DRV_ARCH=amd64
    export DRV_SW_BRANCH=chips_a
    # old clients mwoodpatrick_tree_fsf_driver & mwoodpatrick_fsa_sw
    export DRV_P4_CLIENT=mwoodpatrick_tree_fsf_driver_build 
    export drv=/home/scratch.mwoodpatrick_sw/trees/cuda
    export DRV_ROOT=$drv/sw/dev/gpu_drv/$DRV_SW_BRANCH
    export DRIVER_ROOT=$DRV_ROOT
    export NV_TOOLS=$drv/sw/tools
    export PATH=$DRV_ROOT/drivers/resman/tools/handyman:$drv/sw/misc/linux:$NV_TOOLS/unix/hosts/Linux-x86/unix-build/bin:$sw/dev/gpu_drv/chips_a/drivers/resman/tools/handyman:/home/mwoodpatrick/.local/bin:/home/utils/Python-3.8.0/bin:$PATH

    export LD_LIBRARY_PATH=$LSF_DEFAULT_LD_LIBRARY_PATH:/home/ip/shared/inf/CryptoPP/7.0.0/20181022/GCC520/lib/Linux_x86_64
    export GPGPU_COMPILER_EXPORT_DIR=$drv/compiler/current
    # export GPGPU_COMPILER_EXPORT=$(GPGPU_COMPILER_EXPORT_DIR)/$(GPGPU_COMPILER_ARCH_OS_PREFIX)_$(BUILDTYPE)
    # export GPGPU_COMPILER_EXPORT=$drv/compiler/current/x86_64_Linux_release
    export PATH=$drv/sw/misc/linux:$PATH
}

function sync_driver {
    # see Bug 3389548 Linux NVML fails to build on LSF
    cd $drv/sw
    p4 sync @$FSF_DRIVER_CL
    p4 resolve
    p4 opened
    p4have
    resman.py check_client --branch $DRV_SW_BRANCH --client $DRV_P4_CLIENT --os unix --arch amd64
}

function clean_driver {
    cd $DRV_ROOT
    resman.py build --sweep 2>&1 | tee clean_driver.log
}

function check_driver_client {
    # verify unix-build & nvmake working in tree
    # unix-build --unshare-namespaces nvmake help
    resman.py check_client --branch $DRV_SW_BRANCH --client $DRV_P4_CLIENT --os unix --arch amd64
}

function build_driver {
    # see resman.py help build for build options
    # --output
    export CHANGELIST=$FSF_DRIVER_CL
    export NV_PARALLELMAKE=1
    outdir=$drv/sw/dev/gpu_drv/$DRV_SW_BRANCH/_out
    datestring=`date +%b_%d__%H_%M_%S`
    # destdir=$outdir/build_cl_${FSF_DRIVER_CL}_${DRV_BUILD_TYPE}
    destdir=$outdir

    mkdir -p $destdir
    mkdir -p $drv/sw/dev/gpu_drv/$DRV_SW_BRANCH/build_logs
    echo "results in $destdir"

    cd $drv/sw/dev/gpu_drv/$DRV_SW_BRANCH/drivers/resman
    env > $destdir/env_${datestring}.txt
    # $drv/sw/dev/gpu_drv/chips_a/drivers/resman/tools/handyman/resman.py build --args 'NV_SIM_BUILD=sim'  --build-type debug --dist --slim --output $destdir  2>&1 | tee $destdir/build_driver_${datestring}.log
    # $drv/sw/dev/gpu_drv/chips_a/drivers/resman/tools/handyman/resman.py build --dry-run --args 'NV_SIM_BUILD=sim'  --build-type debug --dist --slim --output $destdir  2>&1 | tee $destdir/build_driver_${datestring}.log
    # Use --dry-run to show the generated nvmake command, but don't run it 
    # resman.py build --args 'NV_SIM_BUILD=sim'  --tracing --develop-rm --build-type $DRV_BUILD_TYPE --dist --slim --output $destdir  2>&1 | tee $drv/sw/dev/gpu_drv/$DRV_SW_BRANCH/build_logs/build_driver_${datestring}.log
    # Generates $drv/sw/dev/gpu_drv/$DRV_SW_BRANCH/_out/Linux_amd64_debug/NVIDIA-Linux-x86_64-460.00-internal.run

    $drv/sw/misc/linux/unix-build \
        --tools $drv/sw/tools/ \
        --no-devrel \
        nvmake \
            NV_SIM_BUILD=sim \
            NV_COLOR_OUTPUT=0 \
            NV_FAST_PACKAGE_COMPRESSION=1 \
            NV_COMPRESS_THREADS=32 \
            NV_EXCLUDE_BUILD_MODULES="compiler ngx nvcuvid egl encodeapi ngx opticalflow optix raytracing vgpu gpgpu gpgpucomp" \
            $@ 2>&1 | tee $drv/sw/dev/gpu_drv/$DRV_SW_BRANCH/build_logs/build_driver_${datestring}.log

    ls -l $destdir/Linux_amd64_${DRV_BUILD_TYPE}/*.run
    echo "results in $destdir"
}

# build the runtime, libaries and tools
# https://wiki.nvidia.com/nvcompute/index.php/GPGPU/BuildingCuda
# https://nvidia.sharepoint.com/sites/mwoodpatrick/_layouts/OneNote.aspx?id=%2Fsites%2Fmwoodpatrick%2FShared%20Documents%2FSharepointCore&wd=target%28FSF.one%7C5DF87375-2C40-402D-B244-303C6312F037%2FBuilding%20Cuda%7CA5FAB032-371C-4284-9672-44981166CB99%2F%29
# onenote:https://nvidia.sharepoint.com/sites/mwoodpatrick/Shared%20Documents/SharepointCore/FSF.one#Building%20Cuda&section-id={5DF87375-2C40-402D-B244-303C6312F037}&page-id={A5FAB032-371C-4284-9672-44981166CB99}&end
# we build driver in chips_a
# contact: Chetan Gokhale <CGOKHALE@nvidia.com>, David Fontaine <dfontaine@nvidia.com>, Andrew Foote <afoote@nvidia.com>
# needs perl 5.8.8 or use export USE_AGNOSTIC_TOOLCHAIN=1 
# build the CUDA apps using currentl golden sw cl & DIRECTAMODEL=1 to change some of the test logic/loops/constants, etc. 
# (It doesn�t change how the apps interact with any drivers) so that tests will run more quickly.

function build_cuda_app ()
{
    local app=$1
    local log=build_${app}_`date +"%m_%d_%y__%H%M"`.log

    cd $drv/sw/gpgpu/cuda/apps
    # ../../build/make-3.81 acos.clean
    make ${app}.clean
    make ${app}.debug DIRECTAMODEL=1 VERBOSE=1 2>&1 | tee $log
    ls -l $drv/sw/gpgpu/bin/x86_64_Linux_debug/${app}
    # make ${app}.release DIRECTAMODEL=1 VERBOSE=1  2>&1 | tee build_${app}_`date +"%m_%d_%y__%H%M"`.log
    echo "see $log for details"
}

function build_cuda_runtime_and_apps () {
    # setup environment
    driver_build_init
    export PATH=/home/utils/perl-5.8.8/bin:$PATH
    # fetch compiler
    # http://dvstransfer.nvidia.com/dvs-binaries/gpu_drv_cuda_a_Release_Linux_AMD64_GPGPU_COMPILER/

    mkdir -p $drv/compiler
	cd $drv/compiler
    # requires beautifulsoup4 https://pypi.org/project/beautifulsoup4/
    # https://www.geeksforgeeks.org/beautifulsoup-installation-python/
    # pip install beautifulsoup4
	$drv/sw/pvt/mwoodpatrick/fetchCompiler.py
	export GPGPU_COMPILER_EXPORT_DIR=`pwd`/current

    # build cuda runtime

	cd $drv/sw/gpgpu
	export DRIVER_ROOT=$drv/sw/dev/gpu_drv/$DRV_SW_BRANCH
	export PATH=$drv/sw/misc/linux:$PATH
    build/make-3.81 clean
	NVCFG_VERBOSE=verbose VERBOSE=1 build/make-3.81 cuda debug 2>&1 | tee build_cuda_runtime_`date +%m_%d_%y__%H_%M_%S`.log

    #  build cuda apps
    # build all apps
    # ../../build/make-3.81 [debug|release]

    build_cuda_app p2p_bandwidth
    build_cuda_app acos
    build_cuda_app cuP2P
}

function run_driver_tests {
    launch_driver_konsole
    driver_build_init
    sync_driver
    clean_driver
    build_driver

    snapshotFSAModel
    useFModel gh100 fmodel
    launch_2gpu_guest
    ssh -p 20005 root@10.126.64.200 # see qemu.log for details
    source /root/host-shared/input/fsa_common_guest.sh 
    initSetup

    # Calling nvidiaPersistence, it will keep RM in persistence mode. This will greatly reducing the time required for the tests to completion
    enableNvidiaPersistence
    runDeviceTest
    runTopologyQuery kills FSA passes with chip arg -amodel_ignore_page_tables
    runNvlinkTest
    runSMI
    runSMILink
    runAcos
    runP2P generated errors
    runP2PBW generated errors
    # 
    # TODO:
    # Add device & smctest
    #
    # runSMITopology kills fmodel bug 3358410
}

# TODO 11/6/2020 Has info in building cuda runtime need to keep or maybe integrate
function tree_fsa_dev_sw {
    export P4CLIENT_SW=mwoodpatrick_tree_fsf_driver
    export P4ROOT_SW=/home/scratch.mwoodpatrick_inf/p4/driver
    export SW_BRANCH=chips_a
    export NV_PARALLELMAKE=1
    swb=$P4ROOT_SW/sw/dev/gpu_drv/chips_a
    swc=$P4ROOT_SW/sw/dev/gpu_drv/cuda_a

    # p4 sync $P4ROOT_SW/...@$SW_CL;p4 resolve
    # python3 $sw/dev/gpu_drv/chips_a/drivers/resman/tools/handyman/resman.py check_client --branch $SW_BRANCH --client $P4CLIENT_SW --os unix --arch amd64 2>&1 | tee client.txt
    
    # currently this tree is used to build cuda driver, no mods build
    # export MODS_RUNSPACE=$P4ROOT_SW/runspaces/forge_mods_chipsa_${SW_CL}
}

# TODO 11/6/2020 This is client for building drivers look into this one further
# https://wiki.nvidia.com/engwiki/index.php/Linux_graphics/Build_environment
# https://wiki.nvidia.com/engwiki/index.php/Nvmake/Command_Details
# https://confluence.nvidia.com/display/CORERM/RM+Handyman

function tree_fsa_dev_resman {
    export P4_RESMAN_CLIENT=mwoodpatrick_tree_resman_build
    export P4_RESMAN_ROOT=/home/scratch.mwoodpatrick_inf/p4/resman_build
    export RESMAN_SW_BRANCH=chips_a
    export NV_PARALLELMAKE=1
    export PATH=$P4_RESMAN_ROOT/sw/misc/linux:/home/utils/Python-3.8.0/bin:/home/nv/utils/crucible/1.0/bin:$PATH

    cd $P4_RESMAN_ROOT/sw/dev/gpu_drv/chips_a/drivers/resman
    # python3 $P4_RESMAN_ROOT/sw/dev/gpu_drv/chips_a/drivers/resman/tools/handyman/resman.py check_client --branch $RESMAN_SW_BRANCH --client $P4_RESMAN_CLIENT --os unix --arch amd64 2>&1 | tee client.txt
    # resman.py build --args 'NV_SIM_BUILD=sim'  --build-type debug --dist --slim 2>&1 | tee build_driver_`date +%m_%d_%y__%H_%M_%S`.log
    # Generates $P4_RESMAN_ROOT/sw/dev/gpu_drv/chips_a/_out/Linux_amd64_debug/NVIDIA-Linux-x86_64-460.00-internal.run

}

# TODO 11/6/2020 this one is for building cuda, look into this further
function tree_fsa_dev_cuda {
    export P4_CUDA_CLIENT=mwoodpatrick_tree_cuda_build
    export P4_CUDA_ROOT=/home/scratch.mwoodpatrick_inf/p4/cuda_build
    export CUDA_SW_BRANCH=chips_a
    export NV_PARALLELMAKE=1
    export PATH=$P4_CUDA_ROOT/sw/misc/linux:$P4_CUDA_ROOT/sw/automation/dvs/tools/localbuild/bin:/home/utils/Python-3.8.0/bin:/home/nv/utils/crucible/1.0/bin:$PATH
	export BUILD_TOOLS_DIR=$P4_CUDA_ROOT/sw/tools
	export TOOLSDIR=$BUILD_TOOLS_DIR
    export GPGPU_COMPILER_ROOT=$P4_CUDA_ROOT/cuda_compiler
    export GPGPU_COMPILER_EXPORT=$GPGPU_COMPILER_ROOT/x86_64_Linux_release
    export P4CLIENT=$P4_CUDA_CLIENT
    export P4PORT=p4proxy-sc:2006
    export P4USER=mwoodpatrick

    cd $P4_CUDA_ROOT/sw/dev/gpu_drv/chips_a/drivers/gpgpu/cuda

    # ** Building Driver **
    # 24G     /home/scratch.mwoodpatrick_inf/p4/cuda_build/
    # mkdir $GPGPU_COMPILER_ROOT                                                                                                  
    # pushd $GPGPU_COMPILER_ROOT                                                                                                  
    # wget http://dvstransfer.nvidia.com/dvs-binaries/gpu_drv_cuda_a_Release_Linux_AMD64_GPGPU_COMPILER/SW_28872810.0_gpu_drv_cuda_a_Release_Linux_AMD64_GPGPU_COMPILER.tgz
    # tar xvf SW_28872810.0_gpu_drv_cuda_a_Release_Linux_AMD64_GPGPU_COMPILER.tgz                                                                                          
    # tar xvf assemblerRESULT.tar
    # tar xvf nvvmRESULT.tar
    # tar xvf toolsRESULT.tar
    # export GPGPU_COMPILER_EXPORT=$GPGPU_COMPILER_ROOT/x86_64_Linux
    # $GPGPU_COMPILER_EXPORT/bin/nvcc --version
    # unix-build --unshare-namespaces --no-read-only-bind-mounts nvmake cuda -j16 debug
    # Generates /home/scratch.mwoodpatrick_inf/p4/cuda_build/sw/dev/gpu_drv/chips_a/drivers/gpgpu/_out/Linux_x86_debug/libcuda.so
    # unix-build --unshare-namespaces --no-read-only-bind-mounts nvmake cuda -j16 release
    # Generates /home/scratch.mwoodpatrick_inf/p4/cuda_build/sw/dev/gpu_drv/chips_a/drivers/gpgpu/_out/Linux_x86_release/libcuda.so
    #
    # ** Building the CUDA runtime, libraries and tests **
    #
    #

}

# TODO: 11/6/2020 do we need this?
# my sw tree for FSA debug on /home/scratch.mwoodpatrick
function fsa_cuda {
    export P4CLIENT_SW=mwoodpatrick_tree_cuda
    export P4ROOT_SW=/home/scratch.mwoodpatrick/trees/cuda
    export sw=$P4ROOT_SW/sw
    export swb=$sw/dev/gpu_drv/cuda_a
    export DRIVER_ROOT=$swb
    ampere_init
}

# https://confluence.nvidia.com/display/GPUTree/Standard+Nvgpu+Crucible+Templates
function tree1_nvgpu_hw {
    export P4CLIENT_HW=mwoodpatrick_nvgpu_crucible
    # export P4ROOT_HW=/home/scratch.mwoodpatrick/trees/nvgpu
    export P4ROOT_HW=/home/scratch.mwoodpatrick/trees/tree1/nvgpu
    export NVTEE_LITTER_DIR=nvgpu

    # This tree is synced to 54548030, latest autofetch change is 54548030, submitted 0.06 hours before your cl
    # hw golden changelist: Change 54548030 by yiyangf@AS2_client10599820_2001 on 2021/04/30 15:24:23
    # sw golden changelist: Change 29910895 by yrao@AS2_client10598549_2006 on 2021/04/30 08:03:42

    # Nvgpu CL used for integrate     - 54561563  //hw/nvgpu/ 2021/05/01 20:59:24
    # looks like closest SW_CL is 29915213

    export HW_CL=54561563

    # see fsa_gh100_sync_integrate_build_and_test
}

# tree for gh100 fmodel
function tree1_nvgpu_gh100 {
    export P4CLIENT_HW=crucible_mwoodpatrick_nvgpu_gh100
    export P4ROOT_HW=/home/scratch.mwoodpatrick/trees/tree1/nvgpu_gh100
    export NVTEE_LITTER_DIR=nvgpu_gh100

    export P4CLIENT_SWITCH_HW=crucible_mwoodpatrick_nvgpu_ls10
    export P4ROOT_SWITCH_HW=/home/scratch.mwoodpatrick/trees/tree1/nvgpu_ls10
    export NVTEE_SWITCH_DIR=nvgpu_ls10

    hw_cl_59253580

    # see fsa_gh100_sync_integrate_build_and_test
}

function tree_nvgpu_sw2() {
    # sw tree for gh100/ga100 mods testing
    # sw golden changelist: Change 29927674 by seanx@AS2_client10611426_2006 on 2021/05/04 23:54:20

    export P4CLIENT_SW=mwoodpatrick_tree_nvgpu_sw2
    export P4ROOT_SW=/home/scratch.mwoodpatrick_inf/trees/nvgpu_sw 

    # Note chips_hw is used to test against hardware cl not chips_a (so use chips_hw AS2)

    export MODS_BRANCH=chips_hw

    export swb=$P4ROOT_SW/sw/dev/gpu_drv/chips_hw
}

function fsa_gh100() { # default client for gh100 FSA development
    fsa_nvgpu_gh100_tree1
    tree_nvgpu_sw2
    gh100_init
    export FSA_BUILD_ROOT=`dirname $hw`
    test_build_and_test_tree1
}

function fsa_gh100_tree2() { # alternate client for gh100 FSA development
    fsa_nvgpu_gh100_tree2
    tree_nvgpu_sw2
    gh100_init
    export FSA_BUILD_ROOT=`dirname $hw`
    test_build_and_test_tree2
}

function fsa_ga100() { # default client for ga100 FSA development
   # export FSF_TEST_DIR=/home/scratch.mwoodpatrick_inf/fsa/fsf_trees/Cuda_Test/494371181 # FSF from job 494371181 6/24/20
    fsa_nvgpu_ga100_tree1
    tree_nvgpu_sw2
    ga100_init
}

function download_fmodel()
{
    local cl=$1
    local log=download_fmodel_${cl}__`date +"%m_%d_%y__%H%"`

    echo "downloading fmodel $cl"
    pushd $FSF_INPUT_DIR

    # download & install fmodel see VRLParam.txt for cl used with job
    $FSF_INSTALLER --fmodel $FSF_FMODEL_GPU --cl $cl 2>&1 | tee $log
    popd
    echo "see log $log for details"
}

#
# Update the SMC Config file for chip
#
# @param[in] gpu       Chip type-gv000/gv100
#
# @returns Error: Score:0 ,tag INFRA_ERR and exits host script.
#                                       [Failing to update config file]
#
function updateSmcConfig ()
{
    local -a gpu=("${!1}")
    local smc_file_path="$KVM_FSF_TOP_DIR/conf/${gpu[@]}_displayless-dev_1-fmod.conf"

    # Updating the config FBP:12, GPC:7 and TPCS_PER_GPC:9
    sed -i "s|-num_fbps=1|-num_fbps=12|g" $smc_file_path
    sed -i "s|-num_ropltcs=1|-num_ropltcs=24|g" $smc_file_path
    sed -i "s|-fbp_en_mask=0x1|-fbp_en_mask=0xfff|g" $smc_file_path
    sed -i "s|-ltc_en_mask=0x1|-ltc_en_mask=0xffffff|g" $smc_file_path
    sed -i "s|-tpc_en_mask=0x1|-tpc_en_mask=0x1ff:0x1ff:0x1ff:0x1ff:0x1ff:0x1ff:0x1ff|g" $smc_file_path
    sed -i "s|-fbpa_en_mask=0x1|-fbpa_en_mask=0xffffff|g" $smc_file_path
    sed -i "s|-p2p_fullstack|-useVirtualization -p2p_fullstack|g" $smc_file_path

    if (( $? !=0 ))
    then
        addInfo " `TZ='America/Los_Angeles' date "+%T"`:\t Failed to update smc config file"
        outHost INFRA_ERR 0
    fi
}

function createSMCConfig() {
    GPU=(
        "gh100"
    )

    # generate config file (see host file for test)
	$FSF_INSTALLER --config --fmodel $FSF_FMODEL_GPU --display displayless

    #Update the smc config
    updateSmcConfig GPU[@]
}

function gh100() { # default one to use for hopper
    # tree1_nvgpu_hw
    tree1_nvgpu_gh100
    tree_nvgpu_sw2
    gh100_init
}

function ga100() { # default one to use for ampere
    export BUILD_ARCH=amd64
    
    tree1_nvgpu_hw
    tree_nvgpu_sw2

    . ~/nvtee_setup
    ga100_init

    # fullstack fmodel stuff
    export FSF_TOP=/home/scratch.mwoodpatrick_inf/fsa1
    # export FSF_TEST_DIR=$FSF_TOP/fsf_trees/sysmem_fix/020719_0618
    # export FSF_TEST_DIR=$FSF_TOP/fsf_trees/SW_25830920
    # export FSF_TEST_DIR=$FSF_TOP/fsf_trees/SW_25910303
    export FSF_OS_IMG=/home/scratch.mwoodpatrick_gpu/fsa/fsf_trees/Mark__2GPU_acos/fsf-tree/guests/Linux_AMD64_FSF_Official-003.img
    . $FSA_MAIN/scripts/fsa_host.sh
}

# TODO: 11/6/2020 we probably don't need this volume but review wikis and client
function fsa_dev_rno() { # init for build on VM mwoodpatrick-dev-rno
    # https://confluence.nvidia.com/display/CORERM/RM+Handyman#tab-LSF+Handyman+Setup
    # https://confluence.nvidia.com/display/GFW/unix-build
    # p4 _template <name>
    # ViewTemplates:
    #   fsa_cuda.template (about 78G)
    #   qemu.template (about 42G)
    export PATH=$sw/misc/linux:$PATH
    export PATH=$sw/tools/unix/hosts/Linux-x86/unix-build/bin:$PATH
    export PATH=/home/utils/Python-3.8.0/bin:$PATH
    export PATH=/home/mwoodpatrick/.local/bin:$PATH
    export PATH=/home/scratch.mwoodpatrick_sw/p4/driver/sw/misc/linux:$PATH
    export P4USER=mwoodpatrick
    export P4PORT=p4proxy-sc:2006
    export P4CLIENT_SW=mwoodpatrick_tree_dc6_fsf_driver
    export P4ROOT=/home/scratch.mwoodpatrick_sw/p4/driver
    export P4CLIENT=mwoodpatrick_tree_dc6_fsf_driver
    export NV_PARALLELMAKE=1
    export sw=/home/scratch.mwoodpatrick_sw/p4/driver/sw
	export swb=$sw/dev/gpu_drv/chips_a
    export SW_BRANCH=chips_a

    # python3 resman.py check_client --branch $SW_BRANCH --client $P4CLIENT --os unix --arch amd64
    # resman.py status
    # cp /home/scratch.mwoodpatrick_sw/p4/driver/sw/misc/linux/unix-build /tmp
    # sudo chown root /tmp/unix-build
    # sudo chmod u+s /tmp/unix-build
    # 
    # alias unixbuild='/tmp/unix-build --tools $sw/tools --devrel $sw/devrel/SDK/inc/GL'
    # unixbuild nvmake amd64 develop drivers dist NV_SIM_BUILD=sim NV_EXCLUDE_BUILD_MODULES="compiler vgpu nvcuvid nvfbc vdpau nvifr encodeapi" -j16 2>&1 | tee drv_build_`date +%m_%d_%y__%H_%M_%S`.log
	# cd $sw/dev/gpu_drv/chips_a/drivers/resman
	# tools/handyman/resman.py build --args 'NV_SIM_BUILD=sim'  --build-type debug --dist --slim 2>&1 | tee build_driver_`date +%m_%d_%y__%H_%M_%S`.log
}

function build_th500_backdoor() {
    # code in /home/scratch.mwoodpatrick_gpu/trees/nvmobile/th500/pwas/backdoormem/hw/nvmobile/ip/mss/mc/5.0/clib/backdoormem
    # points to a directory where you want all PWAs to live
    export GENIE_PWA_HOME=/home/scratch.mwoodpatrick_gpu/trees/nvmobile/th500/pwas
    pwa sync --verbose
    # @Syncing @58218804
    # do clean
   	rm -rf /home/scratch.mwoodpatrick_gpu/trees/nvmobile/th500/pwas/backdoormem/output
    # do build
	# Source code should have some change otherwise Genie build will fetch binary, not build one from your local tree.
	umake th500_Linux_x86_64_mc50-arch_clib_backdoormem_ee.build 2>&1 | tee my_th500_build_`date +%m_%d_%y__%H_%M_%S`.log

    cp -p $FSA_MAIN/scripts2/backdoormem/th500/* /home/arch_traces_kepler/apptracing/fsa/backdoormem/gh100/
}

function snapshotFModel ()
{
    dst=$KVM_FSF_TOP_DIR/fmodel/$NVTEE_CHIP/${HW_CL}

    echo "creating fmodel snapshot: $dst from $nvgpu"

    mkdir $dst
    mkdir $dst/fmod
    cp -pr $nvgpu/fmod/lib $dst/fmod
    mkdir $dst/clib
    cp -pr $nvgpu/clib/Linux_x86_64 $dst/clib
    echo "fmodel snapshot directory generated: $dst"
}

# Need to copy clib/Linux_x86_64/ghlit1_fmodel_64.so
# diag/chiplib_f/ghlit1_Linux_x86_64/ghlit1_ld_release_library_path.txt has LD_LIBRARY_PATH to use
# Need to copy libgputil.so to fmodel dir for FSA/FSF runs
# see bug 200757991 & //sw/dev/gpu_drv/chips_a/drivers/fsf/dvs/sync_fmodel.:
#   diag/chiplib_f/ghlit1_Linux_x86_64/ghlit1_ld_release_library_path.txt
# cp -p /home/ip/nvmobile/inf/libgputil/49969195/Linux_x86_64/libgputil.so fsf-tree/fmodel/gh100/fsa_55739597_55739597/clib/Linux_x86_64

function linkFModelToFSF ()
{
    dst=$KVM_FSF_TOP_DIR/chip/$NVTEE_CHIP
    rm $dst
    ln -s $nvgpu $dst

    echo "linking: $dst from $nvgpu"
}

function copyFSAModel ()
{
    local dst=$1

    if [ -d $dst ]; then
        savedir=${dst}_`date +"%m_%d_%y__%H%M"`
        echo "saving $dst to $savedir"
        mv $dst $savedir
    fi

    echo "creating FSA snapshot: $dst from $nvgpu"

    mkdir -p $dst
    mkdir $dst/fmod
    cp -pr $nvgpu/fmod/lib $dst/fmod
    mkdir $dst/clib
    cp -pr $nvgpu/clib/Linux_x86_64 $dst/clib
    cp -pr $AMODEL_LIBDIR/nv_amodel.so $dst/clib/Linux_x86_64
    # assunes we have done build_fsa to copy files from nvmobile tree into clib for original testing
    echo "FSA snapshot directory generated: $dst"
}

function snapshotFSAModel ()
{
    copyFSAModel $KVM_FSF_TOP_DIR/fmodel/$NVTEE_CHIP/fsa_${HW_CL}_${FSA_CL}$1
}

function show_proc_env ()
{
    xargs -0 printf %s\\n < /proc/$1/environ 
}

function useFModel ()
{
    chip=$1
    fmodel=$2

    fpath=$KVM_FSF_TOP_DIR/fmodel/$chip/$fmodel

    echo "using fmodel $fpath for $chip"

    rm -f $KVM_FSF_TOP_DIR/chip/$chip
    ln -s $fpath $KVM_FSF_TOP_DIR/chip/$chip
    ls -l $KVM_FSF_TOP_DIR/chip/$chip
}

function launch_1gpu_guest {
    runProlog -f $FSF_FMODEL_GPU
    $KVM_FSF_TOP_DIR/scripts/run_guest.sh -g Linux -x 1024 -y 2048 -f $FSF_FMODEL_GPU -o $KVM_FSF_TOP_DIR/guests/Linux_AMD64_FSF_Official-003.img -z $FSF_OUTPUT_DIR/qemu_serial.log --disable_iommu -d displayless 2>&1 | tee $FSF_OUTPUT_DIR/qemu.log
}

function launch_2gpu_guest {
    runProlog -f $FSF_FMODEL_GPU -f $FSF_FMODEL_GPU
    $KVM_FSF_TOP_DIR/scripts/run_guest.sh -g Linux -x 1024 -y 2048 -f $FSF_FMODEL_GPU -f $FSF_FMODEL_GPU -o $KVM_FSF_TOP_DIR/guests/Linux_AMD64_FSF_Official-003.img -z $FSF_OUTPUT_DIR/qemu_serial.log --disable_iommu -d displayless 2>&1 | tee $FSF_OUTPUT_DIR/qemu.log
}

function launch_4gpu_guest {
    runProlog -f $FSF_FMODEL_GPU -f $FSF_FMODEL_GPU -f $FSF_FMODEL_GPU -f $FSF_FMODEL_GPU
    $KVM_FSF_TOP_DIR/scripts/run_guest.sh -g Linux -x 1024 -y 2048 -f $FSF_FMODEL_GPU -f $FSF_FMODEL_GPU -f $FSF_FMODEL_GPU -f $FSF_FMODEL_GPU -o $KVM_FSF_TOP_DIR/guests/Linux_AMD64_FSF_Official-003.img -z $FSF_OUTPUT_DIR/qemu_serial.log --disable_iommu -d displayless 2>&1 | tee $FSF_OUTPUT_DIR/qemu.log
}

function launch_2gpu_amodel_guest {
    runProlog
    $KVM_FSF_TOP_DIR/scripts/run_guest.sh -g Linux -x 1024 -y 2048 -f $FSF_FMODEL_GPU -f $FSF_FMODEL_GPU -o $KVM_FSF_TOP_DIR/guests/Linux_AMD64_FSF_Official-003.img -z $FSF_OUTPUT_DIR/qemu_serial.log --disable_iommu -d displayless -j _amodel 2>&1 | tee $FSF_OUTPUT_DIR/qemu.log
}

function find_core_files()
{
    local log="found_cores.log"
    
    find /home/scratch.mwoodpatrick_inf/fsa/fsf_trees -name "core.[0-9]*" | grep runspace 2>&1 | tee found_cores.log

    echo "see results in found_cores.log"
}

# check if .so will load using current LD_LIBRARY_PATH
function ldd_check ()
{
	LD_BIND_NOW=1 LD_PRELOAD=${1} /bin/true
}

# log all symbols and whether they are resolved
function ldd_trace ()
{
	LD_BIND_NOW=1 LD_TRACE_LOADED_OBJECTS=1 LD_WARN=1 LD_DEBUG=bindings LD_PRELOAD=${1} /bin/true 2>&1 | /usr/bin/c++filt > ldd_trace_`date +"%m_%d_%y__%H%M"`.out
}

# https://www.tecmint.com/install-visual-studio-code-on-linux/
function install_vscode () {
    sudo apt update
    sudo apt install software-properties-common apt-transport-https

    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
   
    sudo apt update
    
    sudo apt install code
    sudo apt install code-insiders

    #  https://www.codegrepper.com/code-examples/whatever/export+vscode+settings+and+extensions
    #  code --list-extensions | xargs -L 1 echo code --install-extension

    code --install-extension bmewburn.vscode-intelephense-client
    code --install-extension bradlc.vscode-tailwindcss
    code --install-extension dbaeumer.vscode-eslint
    code --install-extension eamodio.gitlens
    code --install-extension EditorConfig.EditorConfig
    code --install-extension esbenp.prettier-vscode
    code --install-extension felixfbecker.php-debug
    code --install-extension firsttris.vscode-jest-runner
    code --install-extension GitHub.vscode-pull-request-github
    code --install-extension ms-azuretools.vscode-docker
    code --install-extension ms-vscode.js-debug-nightly
    code --install-extension nrwl.angular-console
    code --install-extension octref.vetur
    code --install-extension snipsnapdev.snipsnap-vscode
    code --install-extension stylelint.vscode-stylelint
    code --install-extension tungvn.wordpress-snippet
    code --install-extension vscode.docker
    code --install-extension vscode.yaml
}

function build_and_test_common {
    # export FSA_BUILD_RESULT_ROOT=$FSA_BUILD_REGRESS_ROOT/build__${HW_CL}__`date +%m_%d_%y__%H_%M_%S`

    cd $nvgpu

    mkdir -p logs

    source fsa/build_and_test_common.sh

    echo "FSA_BUILD_FETCH_FSF_PACKAGE=$FSA_BUILD_FETCH_FSF_PACKAGE"

    # validate_inputs
    # determine_cl
    # setup_result_root

    # sync_tree 

    # integrate_changes

    # clobber_fsa

    # build_fsa

    # setup_tests
}

function do_fsa_regression_run {
    time start_fsa_regression_run 2>&1 | tee logs/build_and_test_`date +%m_%d_%y__%H_%M_%S`.log
}

function test_build_and_test_tree1 {
    export FSA_BUILD_REGRESS_ROOT=/home/hwinf-fsa/regress/tree1
    export FSA_BUILD_SKIP_CLOBBER=1 # skipping clobber phase of buiuld

    # defaults
    export FSA_BUILD_REGRESS=0 # doing regression run will revert any changes in tree before synching
    export FSA_BUILD_SKIP_SYNC=0 # skipping sync phase
    export FSA_BUILD_SKIP_INTEGRATE=0 # skipping sync phase
    # export FSA_BUILD_BASE_CL=60705945 # cl to sync entire tree to. Can be GOLDEN, TOT, changelist number
    # export FSA_BUILD_FSA_CL=60705945 # cl to sync //dev/inf/FullStackAmodel/.... Can be GOLDEN, TOT, changelist number
    export FSA_BUILD_BASE_CL=TOT
    export FSA_BUILD_FSA_CL=TOT
    export FSA_BUILD_FSF_PACKAGE=/home/hwinf-fsa/packages/golden_Linux_AMD64_FSF_PKG.tgz
    export FSA_BUILD_FSF_DRIVER_PATH=/home/hwinf-fsa/packages/golden_gpu_Linux_AMD64_Driver.tgz
    export FSA_BUILD_FSF_DRIVER_TESTS_PATH=/home/hwinf-fsa/packages/golden_Linux_AMD64_CUDA_DVS_Test.tgz
    export FSA_BUILD_SW_ROOT=/home/hwinf-fsa/build/trees/tree1/nvgpu_sw/sw
    unset FSA_BUILD_FETCH_FSF_PACKAGE
    # export FSA_BUILD_FETCH_FSF_PACKAGE=http://dvstransfer.nvidia.com/dvsshare/dvs-binaries-vol1/gpu_drv_chips_Debug_Linux_AMD64_FSF_PKG/SW_31103814.1_gpu_drv_chips_Debug_Linux_AMD64_FSF_PKG.tgz

    build_and_test_common
}

function test_build_and_test_tree2 {
    export FSA_BUILD_REGRESS_ROOT=/home/hwinf-fsa/regress/tree2
    export FSA_BUILD_REGRESS=0 # doing regression run will revert any changes in tree before synching
    export FSA_BUILD_SKIP_CLOBBER=1 # skipping clobber phase of buiuld
    export FSA_BUILD_SKIP_SYNC=0 # skipping sync phase
    export FSA_BUILD_SKIP_INTEGRATE=0 # skipping sync phase
    export FSA_BUILD_BASE_CL=TOT
    export FSA_BUILD_FSA_CL=TOT
    # export FSA_BUILD_BASE_CL=60705945 # cl to sync entire tree to. Can be GOLDEN, TOT, changelist number
    # export FSA_BUILD_FSA_CL=60705945 # cl to sync //dev/inf/FullStackAmodel/.... Can be GOLDEN, TOT, changelist number
    # export FSA_BUILD_FSF_PACKAGE=/home/hwinf-fsa/packages/golden_Linux_AMD64_FSF_PKG.tgz
    # export FSA_BUILD_FSF_DRIVER_PATH=/home/hwinf-fsa/packages/golden_gpu_Linux_AMD64_Driver.tgz
    # export FSA_BUILD_FSF_DRIVER_TESTS_PATH=/home/hwinf-fsa/packages/golden_Linux_AMD64_CUDA_DVS_Test.tgz
    export FSA_BUILD_SW_ROOT=/home/hwinf-fsa/build/trees/tree1/nvgpu_sw/sw
    unset FSA_BUILD_FETCH_FSF_PACKAGE
    export FSA_BUILD_FETCH_FSF_PACKAGE=http://dvstransfer.nvidia.com/dvsshare/dvs-binaries-vol1/gpu_drv_chips_Debug_Linux_AMD64_FSF_PKG/SW_31103814.1_gpu_drv_chips_Debug_Linux_AMD64_FSF_PKG.tgz

    build_and_test_common
}

function diff_build_and_test {
    cd $nvgpu

    diff /home/scratch.mwoodpatrick_gpu/trees/fsa_nvgpu_gh100/hw/nvgpu_gh100/fsa/build_and_test.sh /home/scratch.mwoodpatrick_gpu/trees/fsa_nvgpu_gh100_tree2/hw/nvgpu_gh100/fsa/build_and_test.sh
    diff /home/scratch.mwoodpatrick_gpu/trees/fsa_nvgpu_gh100/hw/nvgpu_gh100/fsa/build_and_test_common.sh /home/scratch.mwoodpatrick_gpu/trees/fsa_nvgpu_gh100_tree2/hw/nvgpu_gh100/fsa/build_and_test_common.sh
    diff fsa/launchTests /home/scratch.mwoodpatrick_gpu/trees/fsa_nvgpu_gh100/hw/nvgpu_gh100/fsa/launchTests
    diff /home/scratch.mwoodpatrick_gpu/trees/fsa_nvgpu_gh100/hw/nvgpu_gh100/fsa/launchTests /home/scratch.mwoodpatrick_gpu/trees/fsa_nvgpu_gh100_tree2/hw/nvgpu_gh100/fsa/launchTests
}

function copy_build_and_test {
    pushd $nvgpu

    local savedir=fsa_`date +"%m_%d_%y__%H%M"`
    echo "saving to $savedir"
    mkdir -p $savedir
    mv fsa/build_and_test* fsa/launchTests $savedir

    cp -p /home/scratch.mwoodpatrick_gpu/trees/fsa_nvgpu_gh100/hw/nvgpu_gh100/fsa/build_and_test.sh /home/scratch.mwoodpatrick_gpu/trees/fsa_nvgpu_gh100_tree2/hw/nvgpu_gh100/fsa
    cp -p /home/scratch.mwoodpatrick_gpu/trees/fsa_nvgpu_gh100/hw/nvgpu_gh100/fsa/build_and_test_common.sh /home/scratch.mwoodpatrick_gpu/trees/fsa_nvgpu_gh100_tree2/hw/nvgpu_gh100/fsa
    cp -p /home/scratch.mwoodpatrick_gpu/trees/fsa_nvgpu_gh100/hw/nvgpu_gh100/fsa/launchTests /home/scratch.mwoodpatrick_gpu/trees/fsa_nvgpu_gh100_tree2/hw/nvgpu_gh100/fsa
    source fsa/build_and_test_common.sh
    popd
}

function build_simproc {
    # see: https://confluence.nvidia.com/display/FSF/Building+FSF+Locally
    # Run on mwoodpatrick-dev-sc
    # Client: mwoodpatrick_tree_fsf_driver_build
    export P4ROOT=/home/scratch.mwoodpatrick_sw/trees/cuda
    ${P4ROOT}/sw/misc/linux/unix-build --tools ${P4ROOT}/sw/tools --devrel ${P4ROOT}/sw/devrel/SDK/inc/GL --extra ${P4ROOT}/sw/tools/linux --extra ${P4ROOT}/sw/tools/kvm --unshare-namespaces
    nvmake simproc amd64 debug build
    chmod uga+x  $P4ROOT/sw/dev/gpu_drv/chips_a/drivers/fsf/simproc/_out/Linux_amd64_debug/vmiop-simproc
    ls -l $P4ROOT/sw/dev/gpu_drv/chips_a/drivers/fsf/simproc/_out/Linux_amd64_debug/vmiop-simproc
}

function update_ubuntu () 
{
    sudo ntpdate time.windows.com
    sudo apt update # Refresh repository index
    # sudo apt upgrade # Upgrades all upgradable packages
    sudo apt upgrade # Upgrades all upgradable packages
    # sudo apt full-upgrade # Upgrades packages with auto-handling of dependencies
    sudo apt full-upgrade # Upgrades packages with auto-handling of dependencies
    # sudo apt list # Lists packages with criteria (installed, upgradable etc)
}

function svc-hwinf-fsa {
    su -l svc-hwinf-fsa
}

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

export PATH=$PATH_BASE
