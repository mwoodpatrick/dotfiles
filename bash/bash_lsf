# echo "sourcing $BASH_SOURCE"
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

# also check file $nvgpu/.qsubenv
#function rel75_base {
#    echo "rel75_base disabled clobbering QSUB_OVERRIDE_OS"
#    return 1
#    # qsub (/home/nv/bin/qsub) is an NVIDIA created utility to submit jobs to the LSF compute farms
#    # [Submitting a job](https://confluence.nvidia.com/display/HWINFFARM/Submitting+a+job)
#    # [Qsub](https://confluence.nvidia.com/display/HWINFFARM/Qsub)
#    # [Qsub::Envfile](https://confluence.nvidia.com/pages/viewpage.action?spaceKey=HWINFFARM&title=Qsub%3A%3AEnvfile)
#    # specify OS to use in qsub command see [Bug 1666429](http://nvbugs/1666429) //hw/nv/qsub/bin/qsub
#    # export QSUB_OVERRIDE_OS=rel75  
#    # Adds '-app LSFappName' argument to the job IF QSUB_APPLICATION or -app are not used
#    export QSUB_APPLICATION_DEFAULT=affinity   
#    unset QSUB_APPLICATION
#    # need to unset this otherwise konsole will not run
#    unset DBUS_SESSION_BUS_ADDRESS
#}
#
## This one launches within a minute or so
## adding -n 4 causes major delays in starting
#function rel75_16G {
#    rel75_base
#    qsub -m rel75 -Is -q o_pri_interactive_cpu_16G -app nodocker bash
#}
#
## These targeting a suitable LSF host for FSA take much much loner
#function rel75_16G_FSA {
#    rel75_base
#    echo "checking env"
#    env|grep QSUB_APP
#    echo "after env check"
#    echo "running /home/nv/qsub/bin/list_envfile"
#    /home/nv/qsub/bin/list_envfile
#    echo "after list_envfile"
#    (
#        set -x
#        qsub -R "select[define(affinity) && kernelversion=5.4.152]" -Is -q o_pri_interactive_cpu_16G -app nodocker bash 
#    )
#}
#
## o_pri_interactive_cpu_32G: No such queue. Job not submitted.
#function rel75_32G_FSA {
#    rel75_base
#    qsub -R "select[define(affinity) && kernelversion=5.4.152]" -m rel75 -Is -q o_pri_interactive_cpu_32G -app nodocker bash
#}
#
#function rel75_32G_4H_FSA {
#    rel75_base
#    qsub -R "select[define(affinity) && kernelversion=5.4.152]" -m rel75 -Is -q o_build_cpu_pri_32G_4H -app nodocker bash
#}
#
#function rel75_32G_16H_FSA {
#    rel75_base
#    qsub -R "select[define(affinity) && kernelversion=5.4.152]" -m rel75 -Is -q o_build_cpu_pri_32G_16H -app nodocker bash
#}
#
## add --debug to debug qsub commands
#function fsa_build::launch_script {
#    echo "fsa_build::launch_script disabled clobbering QSUB_OVERRIDE_OS"
#    return 1
#    local script=$1
#    local queue=$2
#    local launch_script="fsf_test_launch_cmd.sh"
#    local launch_cmd="env -i _TEST_ROOT=${FSA_BUILD_RESULT_ROOT}/fsf_tests _GPU_CHIP=${FSA_BUILD_GPU_CHIP} $script"
#    fsa_build::log_event "fsf launch command: $launch_cmd"
#
#    echo "#! /bin/env bash" > $launch_script &&
#    # echo "export QSUB_OVERRIDE_OS=rel75" >> $launch_script &&
#    echo "export QSUB_APPLICATION_DEFAULT=affinity"  >> $launch_script &&
#    echo "unset QSUB_APPLICATION" >> $launch_script &&
#    echo "qsub -R \"select[define(affinity) && kernelversion=5.4.152]\" -m rel75 -q $queue -app nodocker -Is $launch_cmd" >> $launch_script &&
#    echo "generated $launch_script"
#    chmod uga+x $launch_script &&
#    ./$launch_script 2>&1 | tee launch_fsf_tests.log
#}
#
#function launch_driver_konsole {
#    QSUB_DEFAULT_OS=rel75 TMOUT=1800 qsub -U spike_unix_build -app affinity -q o_cpu_16G_8H -n 8 -R "select[defined(affinity)] span[hosts=1] affinity[core(1):membind=localprefer]" -S 32000 -Is konsole
#
#    # QSUB_DEFAULT_OS=rel75 TMOUT=1800 qsub -U spike_unix_build -q o_cpu_16G_8H -n 8 -R "select[defined(affinity)] span[hosts=1] affinity[core(1):membind=localprefer]" -S 32000 -P ${PROJECT_NAME}
#}
#
#function rj() { 
#    local d=`date +%b-%d-%H:%M:%S`
#    # qsub -P $CHIP -q l_pri_cpu_2G -N -e rj_results_${d}.log2 -o rj_results_${d}.log $@
#    qsub -P $PROJECT -q o_cpu_4G_8H -N -e rj_results_${d}.log2 -o rj_results_${d}.log $@
#    echo "job started $d: $@"
#}
#
## brj vnc 
#function brj() {
#    local d=`date +%b-%d-%H:%M:%S`
#    qsub -P $CHIP -q o_pri_cpu_4G -N -e rj_results_${d}.log2 -o rj_results_${d}.log $@
#    echo "job started $d: $@"
#}
#
#function brj8() {
#    local d=`date +%b-%d-%H:%M:%S`
#    qsub -P $CHIP -q o_pri_cpu_8G -N -e rj_results_${d}.log2 -o rj_results_${d}.log $@
#    echo "job started $d: $@"
#}
#
#function rrj() { 
#    local d=`date +%b-%d-%H:%M:%S`
#    qsub -P $CHIP -q l_pri_vcs_.9G -N -e rj_results_${d}.log2 -o rj_results_${d}.log $@
#    echo "rtl job started queue l_pri_vcs_.9G $d: $@"
#}
#
## https://confluence.nvidia.com/display/FSF/LSF+Farm
## https://www.ibm.com/docs/en/spectrum-lsf/10.1.0?topic=bsub-options
## https://confluence.nvidia.com/display/HWINFFARM/Submitting+a+job
## Support: Erik Welch & Farm-Support
## bjobs -o cresreq <jobid>
## bjobs -o pend_reason  <jobid>
## uptime
#
## creates immediately with correct message queue size 3276800 (validate ulimit -q)
## cat /proc/sys/fs/mqueue/msgsize_max  # expected 32768
## cat /proc/sys/fs/mqueue/msg_max # expected 4096
#echo "setting gbk updated 4/5/2024"
#alias myjobid="echo $LSB_JOBID"
#
#alias gbx_vcs_32G="DISPLAY=$(fullDisplayName) qsub -q o_pri_interactive_vcs_32G xterm -sb -sl 2000 -g 80x60"
## request machine for fullstack fmodel work
## alias gbxfs="DISPLAY=$(fullDisplayName) qsub -R \"affinity[core(4)]\" -q o_pri_interactive_cpu_8G -Is bash"
## See also: ProjectNaming Quickstart Guide: https://wiki.nvidia.com/gpuhwdept/index.php/Project_Naming_Infrastructure/Quick_Start_Guide
#alias gbxfs="DISPLAY=$(fullDisplayName) qsub -R \"affinity[core(4)]\" -q o_pri_interactive_cpu_16G -m rel68 /home/utils/bin/konsole"
## request machine that supports SSE4.2 needed for tegrasim runs
#alias gbx_sse4.2="DISPLAY=$(fullDisplayName) qsub -q o_pri_interactive_cpu_4G -R 'select[model==IX5690]' /home/utils/bin/konsole"
#alias gbx_sse4.2_8G="DISPLAY=$(fullDisplayName) qsub -q o_pri_interactive_cpu_8G -R 'select[model==IX5690]' /home/utils/bin/konsole"
#alias gbx_sse4.2_16G="DISPLAY=$(fullDisplayName) qsub -q o_pri_interactive_cpu_16G -R 'select[model==IX5690]' /home/utils/bin/konsole"
## old command to launch kvm
## alias gbx_kvm="qsub -q o_pri_interactive_cpu_8G -R 'rusage[fsfres=1]' /home/utils/bin/konsole"
## original command to launch kvm
## qsub -q o_cpu_4G_4H -R "select[model=E52680] rusage[fsfres=1]" -Is tcsh
## experimental command to launch kvm
#alias gbx_kvm="DISPLAY=$(fullDisplayName) qsub -q o_pri_interactive_cpu_8G -R 'select[model=E52680] rusage[fsfres=1]' /home/utils/bin/konsole"
## alias gbx_kvm="qsub -q o_pri_interactive_cpu_8G -m rel57 -R 'select[defined(testing)]' /home/utils/bin/konsole"
## alias gbx_kvm_sw="qsub -q o_pri_interactive_cpu_4G -P software  -m rel57 -R 'select[defined(testing)]' /home/utils/bin/konsole"
#alias gbx64="DISPLAY=$(fullDisplayName) qsub -q o_pri_interactive_cpu_rel5_8G /home/utils/bin/konsole"
#
## dedicated LSF
## alias gbx_dedicated="QSUB_OVERRIDE_OS=rel7x QSUB_APPLICATION=nodocker qsub -Is -q o_regress_cpu_16G_7D -app fullchip_test -R \"select[dynamic_pool==dedicated13]\" xterm"
#
## qsub -Is -q o_regress_cpu_16G_7D -app fullchip_test  "/home/utils/bin/konsole"
#function gbk_dedicated()
#{
#    echo "gbk_dedicated disabled clobbering QSUB_OVERRIDE_OS"
#    return 1
#	# QSUB_OVERRIDE_OS=rel7x QSUB_APPLICATION=nodocker qsub -q o_regress_cpu_16G_7D -m rel75 -app fullchip_test -R "select[dynamic_pool==dedicated13]" -o /tmp/l.o -e /tmp/l.e "/home/utils/bin/konsole"
#
#    unset XDG_SESSION_ID
#    unset DBUS_SESSION_BUS_ADDRESS
#    unset XDG_RUNTIME_DIR
#    echo "DISPLAY=$DISPLAY"
#    # export QSUB_OVERRIDE_OS=rel7x 
#    export QSUB_APPLICATION=nodocker
#    qsub -q o_regress_cpu_16G_7D -m rel75 -app fullchip_test -R "select[dynamic_pool==dedicated13]" -o /tmp/l.o -e /tmp/l.e  /usr/bin/konsole
#}

# add --debug to debug qsub commands
# change to infinite duration 
# list_queues -p o_cpu_16G_inf -o mem_limit -o res_rusage -o run_limit -o real_queue
# [Scott Gales](mailto:sgales@nvidia.com): We limit the number of jobs and cores per user to 30.
# When requesting multiple cores, you should add “span[hosts=1]” to your resource request to ensure that all cores are allocated on the same machine rather than selected from different hosts
# [My Request - INC02406422](https://nvidia.service-now.com/esc?id=ticket&table=incident&sys_id=91f95cd24745a210afb00775d36d4323)
# Pls don't use "dbus-launch konsole &" instead you should replace it with "/home/utils/bin/konsole".
# ensure we are not running under docker
# ls -l /dev/kvm
# ulimit -q
# check message queue space see Bug 200213527 FSF: Increase POSIX message queue limit to support multi GPU sessions on LSF machines.
#   3276800
# 
# have //hw/nvgpu_gb102/.qsubenv which specifies to use docker by default
# Lizhong Tang <lizhongt@nvidia.com> You have this file: 
#   /home/scratch.mwoodpatrick_gpu_2/trees/fsa_nvgpu_gb102_tree3/hw/nvgpu_gb102/.qsubenv
# which has high priority than "-app nodocker" option.
# [Qsub::Envfile](https://confluence.nvidia.com/display/HWINFFARM/Qsub%3A%3AEnvfile)

function kvm_konsole {
    local queue=${1:-o_pri_cpu_32G}
    QSUB_IGNORE_QSUBENV=1 QSUB_OVERRIDE_OS=rel75 DISPLAY=$(fullDisplayName) qsub -q $queue -R "select[define(affinity) && kernelversion=5.4.152] span[hosts=1]" -I -n 4 -P gpu_gb102_hwinf_content_tracing /home/utils/bin/konsole
}

# [How To Test on Rocky 8](https://confluence.nvidia.com/pages/viewpage.action?spaceKey=GPUHWInfra&title=How+To+Test+on+Rocky+8)
# konsole 22.04.1 released 2022
function rocky_konsole {
    local queue=${1:-o_pri_cpu_32G}

    env QSUB_APPLICATION=nodocker QSUB_OVERRIDE_OS=rel8x QSUB_APPLICATION_DEFAULT=affinity DISPLAY=$(fullDisplayName) qsub -q $queue -I -n 4 -P gpu_gb102_hwinf_content_tracing /home/utils/bin/konsole
}

function r89_konsole { # launch 
    local queue=${1:-o_pri_cpu_32G}

    env QSUB_APPLICATION=r89docker QSUB_OVERRIDE_OS=rel8x QSUB_APPLICATION_DEFAULT=affinity DISPLAY=$(fullDisplayName) qsub -q $queue -I -n 4 -P gpu_gb102_hwinf_content_tracing /home/utils/bin/konsole
}

# DISPLAY=$(fullDisplayName) qsub -q o_pri_cpu_32G -R "select[define(affinity) && kernelversion=5.4.152] span[hosts=1]" -I -n 4 -P gpu_gb102_hwinf_content_tracing /home/utils/bin/konsole
# 
# amy Here is my cmd: 
# qsub -R "select[define(affinity) && kernelversion=5.4.152]" -n 4 -P gpu_gb102_hwinf_content_tracing -m rel75 -Is -q o_cpu_64G-app nodocker tcsh
# 
# To get rel7 host You can either export QSUB_DEFAULT_OS=rel7x Or add -m rel7x to your qsub
# alias gbk_rel7.5_32G_16H="DISPLAY=$(fullDisplayName) qsub -q o_pri_cpu_32G_16H -app affinity -I -m rel75 /home/utils/bin/konsole &"
alias gbk_rel75_32G_4CPU='DISPLAY=$(fullDisplayName) qsub -q o_pri_cpu_32G -R "select[define(affinity) && kernelversion=5.4.152] span[hosts=1]" -I -n 4 -P gpu_gb102_hwinf_content_tracing /home/utils/bin/konsole'
# alias gbk_rel75_32G_4CPU='DISPLAY=$(fullDisplayName) qsub -q o_pri_cpu_32G -R "select[define(affinity) && kernelversion=5.4.152] span[hosts=1]" -app affinity -I -n 4 -m rel75 /home/utils/bin/konsole &'
# alias gbk_rel75_32G_4CPU='DISPLAY=$(fullDisplayName) qsub -q o_pri_cpu_32G -R "select[define(affinity) && kernelversion=5.4.152] span[hosts=1]" -app affinity -I -n 4 -m rel75 /home/utils/bin/konsole &'

alias gbk_rel75_16G="DISPLAY=$(fullDisplayName) qsub -q o_cpu_16G_inf -app affinity -I -m rel75 /home/utils/bin/konsole &"

# qsub -q o_cpu_16G_4H --debug
alias gbk_rel8x_16G="DISPLAY=$(fullDisplayName) QSUB_APPLICATION=r89docker QSUB_OVERRIDE_OS=rel8x QSUB_APPLICATION_DEFAULT=affinity qsub -q o_cpu_16G_inf -app affinity -I /home/utils/bin/konsole &"

alias gbk_rel75_16G_4CPU='DISPLAY=$(fullDisplayName) qsub -q o_pri_cpu_16G -R "select[define(affinity) && kernelversion=5.4.152] span[hosts=1]" -app affinity -I -n 4 -m rel75 /home/utils/bin/konsole &'
# alias gbk_rel75_32G="DISPLAY=$(fullDisplayName) qsub -q o_pri_cpu_32G -app affinity -I -m rel75 /home/utils/bin/konsole &"
# need at least 4 cores to run FSA tests
# alias gbk_rel75_32G='DISPLAY=$(fullDisplayName) qsub -q o_pri_cpu_32G -R "select[define(affinity) && kernelversion=5.4.152]" -app affinity -I -m rel75 /home/utils/bin/konsole &'
alias gbk_rel75_64G_4CPU='DISPLAY=$(fullDisplayName) qsub -q o_pri_cpu_64G -R "select[define(affinity) && kernelversion=5.4.152] span[hosts=1]" -app affinity -I -n 4 -m rel75 /home/utils/bin/konsole &'
alias gbk_rel75_128G_4CPU='DISPLAY=$(fullDisplayName) qsub -q o_pri_cpu_128G -R "select[define(affinity) && kernelversion=5.4.152] span[hosts=1]" -app affinity -I -n 4 -m rel75 /home/utils/bin/konsole &'
# FSF team recommends: 8 cores to ensure functionality see mail thread from Aditya Sharma <adsharma@nvidia.com> on 7/12/2024
alias gbk_rel75_32G_8CPU='DISPLAY=$(fullDisplayName) qsub -q o_pri_cpu_32G -R "select[define(affinity) && kernelversion=5.4.152]" -app affinity -I -n 8 -m rel75 /home/utils/bin/konsole &'

function check_message_limits {
    echo -n "hostname: "
    hostname
    echo -n "uname -r: "
    uname -r
    echo -n "/proc/sys/fs/mqueue/msg_max (expecting 4096): "
    cat /proc/sys/fs/mqueue/msg_max
    echo -n "/proc/sys/fs/mqueue/msgsize_max (expecting 32768): "
    cat /proc/sys/fs/mqueue/msgsize_max
    echo "LSB_BIND_CPU_LIST=$LSB_BIND_CPU_LIST"
}

# echo ".bash_aliases: setting PATH=$PATH_BASE"
# alias | grep gbk
# bjobs -o cresreq $LSB_JOBID
# check_message_limits 
