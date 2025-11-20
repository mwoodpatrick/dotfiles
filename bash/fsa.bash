# echo "sourcing $BASH_SOURCE"
# also see build_sw.bash

function stacktrace {
    local i=0
    echo "started stacktrace"
    while caller $i; do
        ((i++))
    done
    echo "after stacktrace"
}

if [[ -e ~/svc-hwinf-fsa/.bashrc ]]; then
    source ~/svc-hwinf-fsa/.bashrc
fi

alias rpwd="realpath `pwd`"

function check_message_queue {
    # see [Package Setup](onenote:https://nvidia.sharepoint.com/sites/mwoodpatrick/Shared%20Documents/OneNote/SharepointCore2022/FSF.one#Package%20setup&section-id={5DF87375-2C40-402D-B244-303C6312F037}&page-id={D7140D1E-692D-4424-8B5D-7CF8E273F521}&object-id={93B3A8CE-3EEC-0429-24CB-D2A188A1CD5F}&12)]
    #
    # [Bug 200213527 FSF: Increase POSIX message queue limit to support multi GPU sessions on LSF machines.] (https://nvbugswb.nvidia.com/NvBugs5/ArchBug.aspx?bugid=200213527)
    #
    # [Bug 3941572 FSA: mwoodpatrick : Request for dedicated host](https://nvbugswb.nvidia.com/NvBugs5/HWBug.aspx?bugid=3941572)
    # HR 424923 

    # check the maximum number of bytes in POSIX message queues
    # [How to Use the ulimit Linux Command](https://phoenixnap.com/kb/ulimit-linux-command)
    echo "ulimit -Hq expected to be 3276800 actual $(ulimit -Hq)"
    echo "ulimit -Sq expected to be 3276800 actual $(ulimit -Sq)"
    echo "msg_max: expected 2048 actual $(cat /proc/sys/fs/mqueue/msg_max)"
    echo "msgsize_max: expected 16384 actual $(cat /proc/sys/fs/mqueue/msgsize_max)"

    cat /proc/$$/limits

    local max_bytes=$(ulimit -q)

    if (( $max_bytes < 3276800 )); then
        echo "Message queue space check failed (got $max_bytes expected 3276800)!" 
    else
        echo "Message queue space check passed" 
    fi
}

alias killsim='rm -rf /dev/mqueue/* ; kill -9 `pgrep vmiop\|qemu` ; '

# ga100 is no longer supported need to cleanup
ga100_tree1=/home/scratch.mwoodpatrick_gpu_1/trees/fsa_nvgpu_ga100

# sw tree for gh100/ga100 mods testing
# This is currently used for gh100_tree1 needs cleanup
function sw_dev {
    export P4CLIENT_SW=mwoodpatrick_tree_nvgpu_sw3
    swdev=$FSA_BUILD_MOUNT_DIR/scratch.mwoodpatrick_inf/trees/nvgpu_sw3
    export FSA_BUILD_SW_ROOT=$swdev/sw
    sw=$FSA_BUILD_SW_ROOT
    simproc=$swdev/sw/dev/gpu_drv/chips_a/drivers/fsf/vmioplugin/plugins/display
    # cd $sw
}

unset FSA_BUILD_SKIP_CLOBBER
unset FSA_BUILD_FETCH_FSF_PACKAGE
unset FSA_BUILD_USE_PACKAGE_DRIVER
unset FSA_BUILD_USE_PACKAGE_TESTS

function diff_build_and_test {
    cd $nvgpu

    diff ../fsa_build_and_test/common.sh $ga100_tree1/hw/fsa_build_and_test/common.sh
    diff fsa/launchTests $ga100_tree1/hw/nvgpu_gh100/fsa/launchTests

    for file in $ga100_tree1/hw/nvgpu_ga100/fsa/*
    do
        # echo "Working on $file file..."
        diff $file ../nvgpu_ga100/fsa/`basename $file`
    done
}

function copy_build_and_test {
    cd $nvgpu

    for file in $ga100_tree1/hw/nvgpu_ga100/fsa/*
    do
        # echo "Working on $file file..."
        cp -p $file ../nvgpu_ga100/fsa/`basename $file`
    done
}





function save_run {
    local savedir=save_`date +%b_%d__%H_%M_%S`
    echo "saving run to $savedir"
    mkdir $savedir
    mv host/runspace/* guest *.log *.env $savedir
    mkdir guest
} 

function resetup_driver_tests {
    local rroot=$1
    local config=${rroot}/config.bash

    if [[ -z "$rroot" ]]; then
        echo "Must specify result root"
        return 1;
    elif [[ ! -f $config ]]; then
        echo "invalid result root $rroot"
        return 1;
    fi

    source $hw/fsa_build_and_test/common.sh
    source $hw/fsa_build_and_test/utils.sh

    export FSA_BUILD_RESULT_ROOT=${rroot}
    echo "sourcing: $config"
    source $config
    fsa_build::setup_driver_tests 2>&1 |tee $FSA_BUILD_RESULT_ROOT/setup_driver_tests.log
}

function rerun_driver_tests {
    fsa_build::run_driver_tests 2>&1 | tee $FSA_BUILD_RESULT_ROOT/run_driver_tests.log
}

function fsa_ga100_tree1 {
    export P4CLIENT_HW=mwoodpatrick_amodel.fullstack.ga100_tree1
    export FSA_BUILD_ROOT=/home/scratch.mwoodpatrick_gpu_1/trees/fsa_nvgpu_ga100
    export FSA_BUILD_REGRESS_ROOT=/home/hwinf-fsa/regress/mwoodpatrick/ga100/tree1
    source $FSA_BUILD_ROOT/hw/nvgpu_ga100/fsa/build_and_test
}

function fmodel_gh100_tree1 {
    # TODO:
	# Don't clean/build amodel
	# Don't run ACE captures

    export FSA_BUILD_FMODEL_ONLY=1
    export P4CLIENT_HW=crucible_mwoodpatrick_nvgpu_gh100
    export FSA_BUILD_ROOT=/home/scratch.mwoodpatrick/trees/tree1/nvgpu_gh100
    export FSA_BUILD_REGRESS_ROOT=/home/hwinf-fsa/regress/mwoodpatrick/gh100_fmodel/tree1
    source $FSA_BUILD_ROOT/hw/nvgpu_gh100/fsa/build_and_test
    source $hw/fsa_build_and_test/utils.sh

    # fsa_build::clobber_fmodel
    # fsa_build::build_fmodel
    # fsa_build::setup_mods_tests
    # fsa_build::run_mods_tests
}

function fsa_gh100_tree1 {
    # gh100 build requires rel75, should run at TOT if GOLDEN_CL is not being updated
    export FSA_BUILD_BASE_CL=TOT
    export FSA_BUILD_FSA_CL=TOT
    export P4CLIENT_HW=mwoodpatrick_amodel.fullstack.gh100_tree1
    export FSA_BUILD_ROOT=/home/scratch.mwoodpatrick_gpu/trees/fsa_nvgpu_gh100
    # export FSA_BUILD_REGRESS_ROOT=/home/hwinf-fsa/regress/mwoodpatrick/gh100/tree1
    export FSA_BUILD_REGRESS_ROOT=/home/scratch.mwoodpatrick_sw/regress/mwoodpatrick/gh100/tree1
    source $FSA_BUILD_ROOT/hw/nvgpu_gh100/fsa/build_and_test
    source $hw/fsa_build_and_test/utils.sh
    fsa_common
}

function fsa_gh100_tree2 {
    # gh100 build requires rel75, should run at TOT if GOLDEN_CL is not being updated
    export FSA_BUILD_BASE_CL=TOT
    export FSA_BUILD_FSA_CL=TOT
    export P4CLIENT_HW=mwoodpatrick_amodel.fullstack.gh100_tree2
    export FSA_BUILD_ROOT=/home/scratch.mwoodpatrick_gpu/trees/fsa_nvgpu_gh100_tree2
    export FSA_BUILD_SW_ROOT=/home/scratch.mwoodpatrick_inf/trees/nvgpu_sw/sw
    export sw=$FSA_BUILD_SW_ROOT
    export FSA_BUILD_REGRESS_ROOT=/home/scratch.mwoodpatrick_sw/regress/mwoodpatrick/gh100/tree2
    source $FSA_BUILD_ROOT/hw/nvgpu_gh100/fsa/build_and_test
    source $hw/fsa_build_and_test/utils.sh
}

function fsa_gh180_tree1 {
    # gh100 build requires rel75, should run at TOT if GOLDEN_CL is not being updated
    export FSA_BUILD_BASE_CL=TOT
    export FSA_BUILD_FSA_CL=TOT
    export P4CLIENT_HW=mwoodpatrick_amodel.fullstack.gh180_tree1
    export FSA_BUILD_ROOT=/home/scratch.mwoodpatrick_gpu_1/trees/fsa_nvgpu_gh180
    export FSA_BUILD_REGRESS_ROOT=/home/hwinf-fsa/regress/mwoodpatrick/gh180/tree1

    # scsim
    # use host mwoodpatrick-dev-sc-2
    # get latest passing package from http://ausvrl.nvidia.com/jobs.php?&testname=ap_sim_compute_acos_level_1&os=l4t%25
    # export FSA_BUILD_SCSIM_ROOT=/fsa_regressions/scsim
    # export SCSIM_VERSION=th500_net12

    # export FSA_BUILD_SCSIM_JOB_ID=699899733
    # export FSA_BUILD_SCSIM_PACKAGE_ID=127022970
    # export FSA_BUILD_SCSIM_PACKAGE_URL="http://buildbrain/storage/virtual/dev-main_l4t_t186ref_int_kstable_sanity-pkg_git-master_aarch64_debug/127022970/latest/tests_output.tbz2# "
    # export FSA_BUILD_SCSIM_SECTIONS_URL="https://sc-ipp-ftp-01.nvidia.com/jobs/699899/699899733/sections.xml"

    # export FSA_BUILD_SCSIM_JOB_ID=703648394
    # export FSA_BUILD_SCSIM_PACKAGE_ID=128115538
    # export FSA_BUILD_SCSIM_FSA_ROOT=$FSA_BUILD_ROOT/scsim/${FSA_BUILD_SCSIM_PACKAGE_ID}
    # export FSA_BUILD_SCSIM_PACKAGE_URL="http://buildbrain/mapr-storage/automatic/stage-main_l4t_generic_int_kstable_sanity-pkg_git-master_aarch64_debug/128115538/latest/tests_output.tbz2"
    # export FSA_BUILD_SCSIM_SECTIONS_URL="https://sc-ipp-ftp-01.nvidia.com/jobs/703648/703648394/sections.xml"

    # export FSA_BUILD_BASE_CL=70065235
    # export FSA_BUILD_FSA_CL=$FSA_BUILD_BASE_CL

    source $FSA_BUILD_ROOT/hw/nvgpu_gh180/fsa/build_and_test 
    # source $FSA_BUILD_ROOT/hw/fsa_build_and_test/scsim.sh
    source $hw/fsa_build_and_test/utils.sh
}

function fsa_gh180_tree2 {
    export P4CLIENT_HW=mwoodpatrick_amodel.fullstack.gh180_tree2
    export FSA_BUILD_ROOT=/home/scratch.mwoodpatrick_gpu_1/trees/fsa_nvgpu_gh180_tree2
    export FSA_BUILD_REGRESS_ROOT=/home/hwinf-fsa/regress/mwoodpatrick/gh180/tree2

    # scsim
    # use host mwoodpatrick-dev-sc-2
    # get latest passing package from http://ausvrl.nvidia.com/jobs.php?&testname=ap_sim_compute_acos_level_1&os=l4t%25
    export FSA_BUILD_SCSIM_ROOT=/fsa_regressions/scsim
    export SCSIM_VERSION=th500_net12

    # export FSA_BUILD_SCSIM_JOB_ID=699899733
    # export FSA_BUILD_SCSIM_PACKAGE_ID=127022970
    # export FSA_BUILD_SCSIM_PACKAGE_URL="http://buildbrain/storage/virtual/dev-main_l4t_t186ref_int_kstable_sanity-pkg_git-master_aarch64_debug/127022970/latest/tests_output.tbz2"
    # export FSA_BUILD_SCSIM_SECTIONS_URL="https://sc-ipp-ftp-01.nvidia.com/jobs/699899/699899733/sections.xml"

    export FSA_BUILD_SCSIM_JOB_ID=703648394
    export FSA_BUILD_SCSIM_PACKAGE_ID=128115538
    export FSA_BUILD_SCSIM_FSA_ROOT=$FSA_BUILD_ROOT/scsim/${FSA_BUILD_SCSIM_PACKAGE_ID}
    export FSA_BUILD_SCSIM_PACKAGE_URL="http://buildbrain/mapr-storage/automatic/stage-main_l4t_generic_int_kstable_sanity-pkg_git-master_aarch64_debug/128115538/latest/tests_output.tbz2"
    export FSA_BUILD_SCSIM_SECTIONS_URL="https://sc-ipp-ftp-01.nvidia.com/jobs/703648/703648394/sections.xml"

    source $FSA_BUILD_ROOT/hw/nvgpu_gh180/fsa/build_and_test && source $FSA_BUILD_ROOT/hw/fsa_build_and_test/scsim.sh
    source $hw/fsa_build_and_test/utils.sh
}

# don’t use the -P option. Better to setup .nvprojectname files. 
# Our LSF jobs should use hwinf_content_class project names for accounting purposes.
# Eric documented here: https://confluence.nvidia.com/display/HWINFCONTENT/FSA+on+FSF#FSAonFSF-Executionenvironment
# but his command line does not select the LSF hosts configured with the increased message queue size needed for FSA
# https://confluence.nvidia.com/display/HWINFFARM/Nvprojectname
# nvprojectname save_default . gpu_gb102_hwinf_content_class

function rel68_load {
    lsload -o kernelversion -R 'select[relversion==6.8]'|sort|uniq -c|sort -n
}

function rel75_load {
    # from Eric Welch
    lsload -o kernelversion -R 'select[defined(affinity) && relversion==7.5]'|sort|uniq -c|sort -n
}

function myjobs {
    # Output fields for bjobs
    # queue app pend_reason start_time exec_host
    # bjobs -rusage "resource1"
    #
    # list running jobs
    # bj -r
    #
    # list pending jobs
    # bj -p
    # bj -o "user id submit_time pend_reason exec_host"
    bj -o "user id submit_time app pend_reason exec_host queue"
}

function my_pending_jobs {
    bj -p -o "user id submit_time app pend_reason exec_host queue"
}

function rel75_fsa_jobs {
    bjobs -o 'jobid cresreq pend_reason exec_host' |grep "kernelversion = 5.4.152"
}   

function rel75_pending_fsa_jobs {
    bjobs -p -o 'jobid cresreq' |grep "kernelversion = 5.4.152"
}   

function myjob {
    echo "LSB_JOBID=$LSB_JOBID"
}

function check_kvm {
    local s=`ps -e | grep kvm`
    if [[ -z "$s" ]]; then
        echo "ps -e | grep kvm gave no output" 
        echo "KVM not enabled"
        return 1
    else
        echo "ps -e | grep kvm gives $s" 
        echo "KVM enabled"
        return 0
    fi
}

function fsa_build::launch_test {
    fsa_build::launch_script $hw/fsa_build_and_test/test_launch_fsf_tests.bash o_build_cpu_pri_32G_16H
    fsa_build::launch_script $hw/fsa_build_and_test/test_launch_fsf_tests.bash o_pri_interactive_cpu_16G
}

function fsa_build::launch_driver_tests {
    fsa_build::log_event "Installing package $FSA_BUILD_PACKAGE_ROOT in $FSA_BUILD_FSF_TEST_ROOT/testing " &&
    fsa_build::launch_script $hw/fsa_build_and_test/launch_fsf_tests.bash o_build_cpu_pri_32G_16H
}

# Need to ensure Colossus host is shared with svc-hwinf-fsa so that we can determine the uid, gid for that user
# Check automounter is running
# (Running FSA on Colossus)[https://confluence.nvidia.com/display/HWINFCONTENT/Running+FSA+on+Colossus]
function fsa_mount_all {
    # for info on mouting volume r/w on Linux desktop see HR 827633 
    #   https://ppm.nvidia.com/itg/web/knta/crt/RequestDetail.jsp?REQUEST_ID=827633
    # sudo mount.cifs -o dom=NVIDIA.com,user=mwoodpatrick,rw,uid=mwoodpatrick,forceuid,gid=30,forcegid //netapp39/linuxbuilds /home/linuxbuilds
    # sudo mount.cifs -o dom=NVIDIA.com,user=mwoodpatrick,rw,uid=mwoodpatrick,forceuid,gid=30,forcegid //sc-netapp1/scratch.mwoodpatrick /home/scratch.mwoodpatrick
    echo "Mounting all volumes"
    fsa_check_mounted dc2-cdot80-scr01-lif8a hwinf-fsa svc-hwinf-fsa
    fsa_check_mounted dc2-netapp86 scratch.mwoodpatrick_inf
    fsa_check_mounted dc2-cdot80-scr01-lif8b scratch.mwoodpatrick_sw
    fsa_check_mounted dc2-cdot61-scr01-lif2a scratch.mwoodpatrick_gpu
    fsa_check_mounted dc2-cdot74-scr01 scratch.mwoodpatrick_gpu_1
    fsa_check_mounted dc2-cdot92-scr01-lif4b scratch.mwoodpatrick_gpu_2
    fsa_check_mounted dc2-cdot92-scr01-lif3a scratch.mwoodpatrick_gpu_3
    fsa_check_mounted dc7-cdot02-scr08 scratch.mwoodpatrick_gpu_4 
    fsa_check_mounted dc7-cdot04-crit01 ip
}

function fsa_check_mounted {
    local server=$1
    local volume=$2
    local user=${3:-$USER}
    local uid=$(id -u $user)
    local gid=$(id -g $user)

    # findmnt exits with 0 if found, non-zero otherwise.
    # echo "running: findmnt --mountpoint /mnt/$volume"
    if findmnt --mountpoint "/mnt/$volume" 2>&1 > /dev/null; then
        echo "'/mnt/$volume' is mounted."
    else
        echo "Mounting volume $volume from $server on /mnt/$volume using user $uid group $gid"
        sudo mkdir -p /mnt/$volume
        sudo mount -t cifs -o username=$user,uid=$uid,gid=$gid,rw,file_mode=0770,dir_mode=0770,vers=2.0,sec=ntlmv2,domain=nvidia.com //$server/$volume /mnt/$volume
    fi
}

function fsa_gb102_common {
    if grep Ubuntu /etc/os-release 2>&1 > /dev/null; then
        FSA_BUILD_MOUNT_DIR="/mnt"
        fsa_mount_all
    else
        FSA_BUILD_MOUNT_DIR="/home"
    fi
    echo "FSA_BUILD_MOUNT_DIR=$FSA_BUILD_MOUNT_DIR"
    export FSA_BUILD_SKIP_SYNC=0
    export FSA_BUILD_SKIP_CLOBBER=0
    export FSA_BUILD_SKIP_INTEGRATE=0
    export FSA_BUILD_REGRESS=0 # setting to 1 will revert any changes in tree and set FSA_BUILD_BASE_CL to to FSA_BUILD_HW_GOLDEN_CL
    # export FSA_BUILD_BASE_CL=69675448
    # export FSA_BUILD_FSA_CL=69713736
    # export FSA_BUILD_BASE_CL=69675448
    export FSA_BUILD_BASE_CL=TOT # "GOLDEN" # FSA_BUILD_FSA_CL is set to golden
    export FSA_BUILD_FSA_CL=TOT
    export FSA_BUILD_FSFPKG_SHELVED_CL=31721306
    sw_dev
}

function fsa_gr102_common {
    if grep Ubuntu /etc/os-release 2>&1 > /dev/null; then
        FSA_BUILD_MOUNT_DIR="/mnt"
        fsa_mount_all
    else
        FSA_BUILD_MOUNT_DIR="/home"
    fi
    echo "FSA_BUILD_MOUNT_DIR=$FSA_BUILD_MOUNT_DIR"
    export FSA_BUILD_SKIP_SYNC=0
    export FSA_BUILD_SKIP_CLOBBER=0
    export FSA_BUILD_SKIP_INTEGRATE=0
    export FSA_BUILD_REGRESS=0 # setting to 1 will revert any changes in tree and set FSA_BUILD_BASE_CL to to FSA_BUILD_HW_GOLDEN_CL
    # export FSA_BUILD_BASE_CL=69675448
    # export FSA_BUILD_FSA_CL=69713736
    # export FSA_BUILD_BASE_CL=69675448
    export FSA_BUILD_BASE_CL=TOT # "GOLDEN" # FSA_BUILD_FSA_CL is set to golden
    export FSA_BUILD_FSA_CL=TOT
    export FSA_BUILD_FSFPKG_SHELVED_CL=31721306
    sw_dev
}

function fsa_build::sync_fmodel {
    p4 sync //hw/...@$FSA_BUILD_EFFECTIVE_BASE_CL
    p4 sync //dev/inf/FullStackAmodel/...@$FSA_BUILD_EFFECTIVE_FSA_CL

    # ensure we have resolved files before trying to build
    p4 resolve -am

    # cleanup any files which match current cl
    as2 cleanup
}

# see fsa_build::package_fmodel
function fsa_build::rebuild_fmodel {
    local prefix=fsf_build__${FSA_BUILD_EFFECTIVE_FSA_CL}__`date +%m_%d_%y__%H_%M_%S`
    export FSA_BUILD_RESULT_ROOT=$FSA_BUILD_REGRESS_ROOT/$prefix
    export NV_BUILD_LIBGPUTIL=1
    cd $nvgpu
    export FSA_BUILD_HW_GOLDEN_CL=`nvrun golden_cl get --customer nvgpu_${FSA_BUILD_GPU_CHIP}_hsmb --type hw`
    fsa_build::sync_fmodel
    fsa_build::clobber_fmodel
    $nvgpu/fsa/build_fmodel.csh 2>&1 | tee build_fmodel.log
    ls -l clib/Linux_x86_64/gblit1_fmodel_64.so
    ls -l clib/Linux_x86_64/gblit1_debug_fmodel_64.so
    LD_LIBRARY_PATH=fmod/lib/Linux_x86_64:clib/Linux_x86_64/gblit1:$LD_LIBRARY_PATH ldd clib/Linux_x86_64/gblit1_debug_fmodel_64.so|grep  libgputil.so
    echo fsa_build::package_fmodel
}

function fsa_build::check_fmodel
{
    local d=$1

    local libs=(
        clib/Linux_x86_64/external_libs/gblit1/libnvURA_std_930.so
        clib/Linux_x86_64/external_libs/gblit1/libnvsim_64.so
        clib/Linux_x86_64/external_libs/gblit1/libnvURA_std_930.so
        clib/Linux_x86_64/external_libs/gblit1/libnvsim_64.so
        clib/Linux_x86_64/external_libs/gblit1/libnvmath_64.so
        clib/Linux_x86_64/external_libs/gblit1/libevent_cover_64.so
        clib/Linux_x86_64/external_libs/gblit1/libevent_cover_shared_64.so
        clib/Linux_x86_64/external_libs/gblit1/libsystemc-2.3.3.so
        clib/Linux_x86_64/external_libs/gblit1/libfmt.so.9
        clib/Linux_x86_64/external_libs/gblit1/libcryptopp.so.8
    )

    for lib in "${libs[@]}"
    do
        if [[ ! -e $d/$lib ]];then
            echo "$lib missing!"
            return 1
        else
            echo "$d/$lib found"
            ls -lh $d/$lib
        fi
    done
        
    echo "All files present"
    return 0
}

# see fsa_build::rebuild_fmodel
function fsa_build::package_fmodel {
    local name=fmodel-${FSA_BUILD_GPU_CHIP}-${FSA_BUILD_EFFECTIVE_BASE_CL}
    local dst=$nvgpu/builds/$name
    local tarpath=$nvgpu/builds/${name}.tgz
    local log=$nvgpu/builds/${name}.log
    local clib=$dst/clib
    local fmod=$dst/fmod

    # find /home/ip/nvmobile/inf/libgputil/ -name libgputil.so -exec ls -l {} \;|grep Linux_x86_64

    fsa_build::log_event "packaging fmodel in $dst"

    rm -rf $dst &&
    rm -f builds/build.tgz &&
    rm -f $tarpath &&
    mkdir -p "$dst" &&
    fsa_build::copy "$nvgpu/clib/Linux_x86_64" "$clib" &&
    fsa_build::copy "$nvgpu/clib/Linux_GCCR5XC" "$clib" &&
    mkdir -p "$fmod/lib" &&
    fsa_build::copy "$nvgpu/fmod/lib/Linux_x86_64" "$fmod/lib" &&
    fsa_build::copy $nvgpu/include $dst &&
    fsa_build::copy /home/ip/nvmobile/inf/libgputil/67146932_debug/Linux_x86_64/libgputil.so "$clib/Linux_x86_64" &&
    fsa_build::copy /home/ip/nvmobile/inf/libgputil/67146932/Linux_x86_64/libgputil.so "$clib/Linux_x86_64" &&
    fsa_build::package_external_libs $dst &&
    fsa_build::check_fmodel $dst &&
    find $dst -name libgputil.so &&
    pushd $dst &&
    tar cvzf $tarpath * 2>&1 | tee $log &&
    cd ..
    ln -s $name.tgz build.tgz &&
    popd

    local status=$?
    fsa_build::log_event "packaged fmodel in tarpath=${tarpath} $dst see $log for details (status=$status)"
}

function fsf_setup_nvlink_tests {
    fsa_build::setup_mods_tests
}

# suffix=`date +"%m_%d_%y__%H%M"`
# $nvgpu/fsa/launchFmodelTests ${FSA_BUILD_AMODEL_LIBDIR} --gccDir /home/utils/gcc-12.2.0/lib64 --chip gb102 --tgenArgs "-nosandbox -maxFileSize 0 -modsRunspace $MODS_RUNSPACE -mailto mwoodpatrick@nvidia.com -traceRoot $FSA_BUILD_TRACE_CACHE_CL" --wait --outDir  $FSA_BUILD_RESULT_ROOT/mods_test_new_${suffix}
function fsf_run_nvlink_tests {
    # fsf_gb102_tree1
    local suffix=`date +"%m_%d_%y__%H%M"`
    local outDir=$FSA_BUILD_RESULT_ROOT/mods_test_new_${suffix}
    # export FSA_DRY_RUN=1
    local cmd="$nvgpu/fsa/launchFmodelTests ${FSA_BUILD_AMODEL_LIBDIR} --gccDir /home/utils/${GCC_VERSION}/lib64 --chip ${FSA_BUILD_GPU_CHIP} --tgenArgs \"-traceRoot $FSA_BUILD_TRACE_CACHE_CL/arch/traces -nosandbox -maxFileSize 0 -modsRunspace ${MODS_RUNSPACE} -mailto ${USER}@nvidia.com\" --wait --outDir ${outDir}" 
    echo "running $cmd" | tee launch_command_${suffix}
    $cmd 2>&1 | tee nvlink_tests_${suffix}.log
}

# [Perforce First Time Users](https://confluence.nvidia.com/display/SCMU/Perforce+First+Time+Users#PerforceFirstTimeUsers-Findoutwhichinstanceandwhatfilesyouwillneedtoworkon)
# /home/nv/utils/p4mapper/latest/bin/p4mapper best --complex p4hw
# /home/nv/utils/p4mapper/latest/bin/p4mapper best --complex p4sw
# export P4PORT=p4proxy-sc:4101
# alias p4sw="p4 -p p4proxy-sc:4106"

function fsa_common {
    export FSA_BUILD_DGX_TOP=/fsa/dgx
    local desc=`p4 changes -s submitted -m 1`
}

# fmodel tests to run
# fsa/gb102/run_nvlink_tests.sh
# fsa/gb102/run_multi_gpu_mse_autoconfig_chipsim.sh
# fsa/gb102/run_multi_gpu_mse_autoconfig_stub.sh
# fsa/gb102/run_single_gpu_mse_autoconfig_chipsim.sh
# fsa/gb102/run_single_gpu_mse_autoconfig_stub.sh

function fmodel::setup_result_root {
    local prefix=build__${FSA_BUILD_EFFECTIVE_FSA_CL}__`date +%m_%d_%y__%H_%M_%S`
    export FSA_BUILD_RESULT_ROOT=$FSA_BUILD_REGRESS_ROOT/$prefix
    echo "FSA_BUILD_RESULT_ROOT=$FSA_BUILD_RESULT_ROOT"
}

function fmodel::run_mods_test {
    local outdir=$FSA_BUILD_RESULT_ROOT/mods_test__`date +%m_%d_%y__%H_%M_%S`
    diag/testgen/tgen.pl -chip gb102 -level nvlink/feature/single_gpu_mse -nosandbox -only autoconfig -only _chipsim -maxFileSize 1600000 -clobber -outDir $outdir
    echo "results in $outdir"
}

# gvim -S /home/mwoodpatrick/gvim.sessions/fsf_gb102.gvim
# Build full fmodel: fsa_build::build_fmodel
# Rebuild only nvlc5: ./bin/t_make --sol --only nvlc5-fmod_nvlc -skip mods -noforce_retry_on_fail --projects gb102
# list symbols in .so: nm /home/scratch.mwoodpatrick_gpu_1/trees/fsa_nvgpu_gb102_tree2/hw/nvgpu_gb102/fmod/lib/Linux_x86_64/libgblit1_nvlc_64.so | grep _Z32amodelNVIRNVLinkAccessPeerMemorymPvmb13BDAddressTypeiim
# Add -C to demangle symbols (reports symbol type “T” for exported symbols)
# ip/nvif/nvlc/6.0/fmod/nvlc/nvlc_config.h#25
alias fmodel::build=fsa_build::build_fmodel

function fsf_gb102_tree1 {
    fsa_gb102_common
    export FSA_BUILD_REGRESS_ROOT=/home/hwinf-fsa/regress/mwoodpatrick/gb102/fsf-tree1
    # Building at same cl as latest gb102 fsa build)
    export FSA_BUILD_EFFECTIVE_BASE_CL="77710733"
    export FSA_BUILD_EFFECTIVE_FSA_CL="77710733"
    # p4 sync @$FSA_BUILD_EFFECTIVE_BASE_CL
    export P4CLIENT_HW=mwoodpatrick_fmodel.fullstack.gb102_tree1
    export FSA_BUILD_ROOT=$FSA_BUILD_MOUNT_DIR/scratch.mwoodpatrick_gpu_1/trees/fsf_nvgpu_gb102
    echo "FSA_BUILD_ROOT=$FSA_BUILD_ROOT"
    export hw=$FSA_BUILD_ROOT/hw
    export nvgpu=$hw/nvgpu_gb102
    # can we use these?
    source $FSA_BUILD_ROOT/hw/nvgpu_gb102/fsa/build_and_test
    source $hw/fsa_build_and_test/utils.sh
    # local prefix=build__fsf_${FSA_BUILD_HW_GOLDEN_CL}__`date +%m_%d_%y__%H_%M_%S`
    # export FSA_BUILD_RESULT_ROOT=$FSA_BUILD_REGRESS_ROOT/$prefix
    fsa_common
    # export FSA_BUILD_RESULT_ROOT=/home/hwinf-fsa/regress/mwoodpatrick/gb102/tree1/build__71260123__10_08_23__04_35_06
    export FSA_BUILD_RESULT_ROOT=/home/hwinf-fsa/regress/mwoodpatrick/gb102/tree2/build__71260123__10_09_23__12_22_05
    echo "FSA_BUILD_RESULT_ROOT=$FSA_BUILD_RESULT_ROOT"
    echo -n "FSA_BUILD_EFFECTIVE_BASE_CL: "
    p4 describe $FSA_BUILD_EFFECTIVE_BASE_CL|head -1
    echo -n "FSA_BUILD_EFFECTIVE_FSA_CL: "
    p4 describe $FSA_BUILD_EFFECTIVE_FSA_CL|head -1

    export P4CLIENT_SW=mwoodpatrick_tree_nvgpu_gb102_claire
    swdev=/home/hwinf-fsa/regress/mwoodpatrick/gb102/fsf-tree1/fsf_client
    # export FSA_BUILD_SW_ROOT=$swdev/sw
    sw=$FSA_BUILD_SW_ROOT
    simproc=$swdev/sw/dev/gpu_drv/chips_a/drivers/fsf/vmioplugin/plugins/display
}

function fsa_colossus_mount {
    mkdir -p /mnt/scratch.mwoodpatrick_gpu
sudo mount -t cifs -o username=mwoodpatrick,uid=1807,gid=30,rw,file_mode=0770,dir_mode=0770,vers=2.0,sec=ntlmv2,domain=nvidia.com //dc2-cdot61-scr01-lif2a/scratch.mwoodpatrick_gpu  /mnt/scratch.mwoodpatrick_gpu

    sudo mkdir -p /mnt/scratch.mwoodpatrick_gpu_1
    sudo mount -t cifs -o username=mwoodpatrick,uid=1807,gid=30,rw,file_mode=0770,dir_mode=0770,vers=2.0,sec=ntlmv2,domain=nvidia.com //dc2-cdot74-scr01/scratch.mwoodpatrick_gpu_1 /mnt/scratch.mwoodpatrick_gpu_1

    sudo mkdir -p /mnt/scratch.mwoodpatrick_sw
    sudo mount -t cifs -o username=mwoodpatrick,uid=1807,gid=30,rw,vers=2.0,sec=ntlmv2,domain=nvidia.com //dc2-cdot80-scr01-lif8b/scratch.mwoodpatrick_sw /mnt/scratch.mwoodpatrick_sw

    sudo mkdir -p /mnt/scratch.mwoodpatrick_inf
    sudo mount -t cifs -o username=mwoodpatrick,uid=1807,gid=30,rw,file_mode=0770,dir_mode=0770,vers=2.0,sec=ntlmv2,domain=nvidia.com //dc2-netapp86/scratch.mwoodpatrick_inf /mnt/scratch.mwoodpatrick_inf

    # user svc-hwinf-fsa
    sudo mkdir -p /mnt/hwinf-fsa
    sudo mount -t cifs -o username=svc-hwinf-fsa,uid=45470,gid=30,rw,file_mode=0770,dir_mode=0770,vers=2.0,sec=ntlmv2,domain=nvidia.com //dc2-cdot80-scr01-lif8b/hwinf-fsa /mnt/hwinf-fsa

    df -h /mnt/*
}

function fsa_gb102_tree1 {  # old gb102 FSA support tree not curently used
    fsa_gb102_common
    export FSA_BUILD_REGRESS_ROOT=$FSA_BUILD_MOUNT_DIR/hwinf-fsa/regress/mwoodpatrick/gb102/tree1
    export P4CLIENT_HW=mwoodpatrick_amodel.fullstack.gb102_tree1
    export FSA_BUILD_ROOT=$FSA_BUILD_MOUNT_DIR/scratch.mwoodpatrick_gpu_1/trees/fsa_nvgpu_gb102
    source $FSA_BUILD_ROOT/hw/nvgpu_gb102/fsa/build_and_test
    source $hw/fsa_build_and_test/utils.sh
    FSA_BUILD_BASE_CL=TOT # GOLDEN|TOT
    echo FSA_BUILD_BASE_CL=$FSA_BUILD_BASE_CL 
    echo FSA_BUILD_FSA_CL=$FSA_BUILD_FSA_CL
    fsa_common
}

function fsa_gb102_tree2 { # old gb102 FSA support tree not curently use
    fsa_gb102_common
    export FSA_BUILD_REGRESS_ROOT=/home/hwinf-fsa/regress/mwoodpatrick/gb102/tree2
    export P4CLIENT_HW=mwoodpatrick_amodel.fullstack.gb102_tree2
    export FSA_BUILD_ROOT=/home/scratch.mwoodpatrick_gpu_1/trees/fsa_nvgpu_gb102_tree2
    source $FSA_BUILD_ROOT/hw/nvgpu_gb102/fsa/build_and_test
    source $hw/fsa_build_and_test/utils.sh
    # FSA_BUILD_BASE_CL=71260123 # GOLDEN|TOT
    # FSA_BUILD_FSA_CL=71260123
    FSA_BUILD_BASE_CL=TOT # GOLDEN|TOT
    echo FSA_BUILD_BASE_CL=$FSA_BUILD_BASE_CL 
    echo FSA_BUILD_FSA_CL=$FSA_BUILD_FSA_CL
    # export FSA_BUILD_EFFECTIVE_BASE_CL="71260123"
    # export FSA_BUILD_EFFECTIVE_FSA_CL="71260123"
    # default sw root see fsa_build::validate_inputs
    # export FSA_BUILD_SW_ROOT=${FSA_BUILD_SW_ROOT:-/home/hwinf-fsa/build/trees/tree1/nvgpu_sw/sw}
    # export FSA_BUILD_SW_ROOT=/home/hwinf-fsa/build/trees/tree1/nvgpu_sw/sw
    fsa_common
    export sw=$FSA_BUILD_SW_ROOT
}

function fsa_gb102_tree3 { # current FSA support tree
    fsa_gb102_common
    export FSA_BUILD_REGRESS_ROOT=/home/scratch.mwoodpatrick_gpu_2/trees/fsa_nvgpu_gb102_tree3_regress
    export P4CLIENT_HW=mwoodpatrick_amodel.fullstack.gb102_tree3
    export FSA_BUILD_ROOT=/home/scratch.mwoodpatrick_gpu_2/trees/fsa_nvgpu_gb102_tree3
    source $FSA_BUILD_ROOT/hw/nvgpu_gb102/fsa/build_and_test
    source $hw/fsa_build_and_test/utils.sh
    FSA_BUILD_BASE_CL=TOT # GOLDEN|TOT
    echo FSA_BUILD_BASE_CL=$FSA_BUILD_BASE_CL 
    echo FSA_BUILD_FSA_CL=$FSA_BUILD_FSA_CL
    fsa_common
}

function fsa_gb102_tree4 {  # not in current use was used for nvlink5
    fsa_gb102_common
    export FSA_BUILD_REGRESS_ROOT=/home/scratch.mwoodpatrick_gpu_2/trees/fsa_nvgpu_gb102_tree4_regress
    export P4CLIENT_HW=mwoodpatrick_amodel.fullstack.gb102_tree4
    export FSA_BUILD_ROOT=/home/scratch.mwoodpatrick_gpu_2/trees/fsa_nvgpu_gb102_tree4
    source $FSA_BUILD_ROOT/hw/nvgpu_gb102/fsa/build_and_test
    source $hw/fsa_build_and_test/utils.sh
    FSA_BUILD_BASE_CL=TOT # GOLDEN|TOT
    echo FSA_BUILD_BASE_CL=$FSA_BUILD_BASE_CL 
    echo FSA_BUILD_FSA_CL=$FSA_BUILD_FSA_CL
    fsa_common
}

function fsa_gb102_tree5 { # secondary nvlibk5 tree
    fsa_gb102_common
    export FSA_BUILD_REGRESS_ROOT=/home/scratch.mwoodpatrick_gpu_3/trees/fsa_nvgpu_gb102_tree5_regress
    export P4CLIENT_HW=mwoodpatrick_amodel.fullstack.gb102_tree5
    export FSA_BUILD_ROOT=/home/scratch.mwoodpatrick_gpu_3/trees/fsa_nvgpu_gb102_tree5
    source $FSA_BUILD_ROOT/hw/nvgpu_gb102/fsa/build_and_test
    source $hw/fsa_build_and_test/utils.sh
    FSA_BUILD_BASE_CL=TOT # GOLDEN|TOT
    echo FSA_BUILD_BASE_CL=$FSA_BUILD_BASE_CL 
    echo FSA_BUILD_FSA_CL=$FSA_BUILD_FSA_CL
    fsa_common
}

function fsa_gb102_tree6 { # primary nvlink5 tree
    fsa_gb102_common
    export FSA_BUILD_REGRESS_ROOT=/home/scratch.mwoodpatrick_gpu_3/trees/fsa_nvgpu_gb102_tree6_regress
    export P4CLIENT_HW=mwoodpatrick_amodel.fullstack.gb102_tree6
    export FSA_BUILD_ROOT=/home/scratch.mwoodpatrick_gpu_3/trees/fsa_nvgpu_gb102_tree6
    source $FSA_BUILD_ROOT/hw/nvgpu_gb102/fsa/build_and_test
    source $hw/fsa_build_and_test/utils.sh
    FSA_BUILD_BASE_CL=TOT # GOLDEN|TOT
    echo FSA_BUILD_BASE_CL=$FSA_BUILD_BASE_CL 
    echo FSA_BUILD_FSA_CL=$FSA_BUILD_FSA_CL
    fsa_common
}

# [Building the tree](https://confluence.nvidia.com/display/RUBINSMARCH/Rubin+New+Architect+Ramp-up#RubinNewArchitectRampup-Buildingthetree)
function fsa_init_tree {
    mkdir -p $FSA_BUILD_ROOT
    cd $FSA_BUILD_ROOT
    echo "P4CLIENT=${P4CLIENT_HW}" > .p4config
    echo "P4PORT=p4hw:2001" >> .p4config
}

# Sam is currently using the nvgpu tree, Peter is using the nvgpu_gr102s tree
function fsa_gr102_tree1 {  # primary FSA support tree for gr102
    set +x
    fsa_gr102_common
    export FSA_BUILD_REGRESS_ROOT=$FSA_BUILD_MOUNT_DIR/scratch.mwoodpatrick_gpu_4/regress/mwoodpatrick/gr102/tree1
    export P4CLIENT_HW=mwoodpatrick_amodel.fullstack.gr102_tree1
    export FSA_BUILD_ROOT=$FSA_BUILD_MOUNT_DIR/scratch.mwoodpatrick_gpu_4/trees/fsa_nvgpu_gr102_tree1
    source $FSA_BUILD_ROOT/hw/nvgpu_gr102s/fsa/build_and_test
    echo "FSA_BUILD_ROOT=$FSA_BUILD_ROOT"
    export hw=$FSA_BUILD_ROOT/hw
    export nvgpu=$hw/nvgpu_gr102s
    source $nvgpu/fsa/fsa_build_and_test/utils.sh
    FSA_BUILD_BASE_CL=TOT # GOLDEN|TOT
    echo FSA_BUILD_BASE_CL=$FSA_BUILD_BASE_CL 
    echo FSA_BUILD_FSA_CL=$FSA_BUILD_FSA_CL
    fsa_common
}

function fsa_gb102_ipp2-2324_tree1 {
    # see fsa_colossus_mount
    fsa_gb102_common
    export P4CLIENT_HW=mwoodpatrick_amodel.fullstack.gb102_ipp2-2324
    # export FSA_BUILD_ROOT=/fsa/fsa_nvgpu_gb102
    export FSA_BUILD_ROOT=/mnt/scratch.mwoodpatrick_gpu_1/trees/fsa_nvgpu_gb102
    source $FSA_BUILD_ROOT/hw/nvgpu_gb102/fsa/build_and_test
    source $hw/fsa_build_and_test/utils.sh
    FSA_BUILD_BASE_CL=GOLDEN
    echo FSA_BUILD_BASE_CL=$FSA_BUILD_BASE_CL # GOLDEN|TOT
    echo FSA_BUILD_FSA_CL=$FSA_BUILD_FSA_CL
    fsa_common
}

function fsa_gb102_ipp2-2324_tree2 {
    # see fsa_colossus_mount
    fsa_gb102_common
    export P4CLIENT_HW=mwoodpatrick_amodel.fullstack.gb102_ipp2-2324
    # export FSA_BUILD_ROOT=/fsa/fsa_nvgpu_gb102
    export FSA_BUILD_ROOT=/mnt/scratch.mwoodpatrick_gpu_1/trees/fsa_nvgpu_gb102_tree2
    source $FSA_BUILD_ROOT/hw/nvgpu_gb102/fsa/build_and_test
    source $hw/fsa_build_and_test/utils.sh
    FSA_BUILD_BASE_CL=GOLDEN
    echo FSA_BUILD_BASE_CL=$FSA_BUILD_BASE_CL # GOLDEN|TOT
    echo FSA_BUILD_FSA_CL=$FSA_BUILD_FSA_CL
    fsa_common
}

function build_fsf_components {
    # see: https://confluence.nvidia.com/display/FSF/Building+FSF+Locally
    # Run on mwoodpatrick-dev-sc
    # Client: mwoodpatrick_tree_fsf_driver_build
    # export P4ROOT=/home/scratch.mwoodpatrick_sw/trees/cuda
    export P4ROOT=/home/scratch.mwoodpatrick_inf/trees/nvgpu_sw3
    ${P4ROOT}/sw/misc/linux/unix-build --tools ${P4ROOT}/sw/tools --devrel ${P4ROOT}/sw/devrel/SDK/inc/GL --extra ${P4ROOT}/sw/tools/linux --extra ${P4ROOT}/sw/tools/kvm --unshare-namespaces
    nv_source=$sw/dev/gpu_drv/chips_a
    simproc_dir=${nv_source}/drivers/fsf/simproc

    # build QEMU
    nvmake qemu amd64 debug build
    ls -l ${P4ROOT}/sw/dev/gpu_drv/chips_a/drivers/fsf/kvm/_out/Linux_amd64_debug/

    # build Vmioplugin
    nvmake vmioplugin amd64 debug build
    ls -l ${P4ROOT}/sw/dev/gpu_drv/chips_a/drivers/fsf/vmioplugin/plugins/display/_out/Linux_amd64_debug/vmiop-display.so

    # build simproc
    nvmake simproc amd64 debug build
    chmod uga+x  $P4ROOT/sw/dev/gpu_drv/chips_a/drivers/fsf/simproc/_out/Linux_amd64_debug/vmiop-simproc
    ls -l $P4ROOT/sw/dev/gpu_drv/chips_a/drivers/fsf/simproc/_out/Linux_amd64_debug/vmiop-simproc
}

function build_simproc {
    # see: https://confluence.nvidia.com/display/FSF/Building+FSF+Locally
    # Run on mwoodpatrick-dev-sc
    # Client: mwoodpatrick_tree_nvgpu_sw3
    # gvim -S ~/gvim.sessions/simproc.gvim
    cd $swdev/sw/dev/gpu_drv/chips_a/drivers/fsf
    ${swdev}/sw/misc/linux/unix-build --tools ${swdev}/sw/tools --devrel ${swdev}/sw/devrel/SDK/inc/GL --extra ${swdev}/sw/tools/linux --extra ${swdev}/sw/tools/kvm --unshare-namespaces 
    chmod uga+x  $swdev/sw/dev/gpu_drv/chips_a/drivers/fsf/simproc/_out/Linux_amd64_debug/vmiop-simproc
    ls -l $swdev/sw/dev/gpu_drv/chips_a/drivers/fsf/simproc/_out/Linux_amd64_debug/vmiop-simproc

    nvmake simproc amd64 debug clobber
    INC_MSG_QUEUE_SIZE=1 nvmake simproc amd64 debug build
    ls -l ./simproc/_out/Linux_amd64_debug/vmiop-simproc
    nvmake vmioplugin amd64 debug clobber
    INC_MSG_QUEUE_SIZE=1 nvmake vmioplugin amd64 debug build
    ls -l ./vmioplugin/plugins/display/_out/Linux_amd64_debug/vmiop-display.so
}

function update_simproc {
    local orig=orig_$(date +%m_%d_%y__%H_%M_%S)
    mv $KVM_FSF_TOP_DIR/tools/vmiop-simproc $KVM_FSF_TOP_DIR/tools/vmiop-simproc.${orig}
    cp -p $swdev/sw/dev/gpu_drv/chips_a/drivers/fsf/simproc/_out/Linux_amd64_debug/vmiop-simproc $KVM_FSF_TOP_DIR/tools/vmiop-simproc
    ls -l $KVM_FSF_TOP_DIR/tools/vmiop-simproc

    mv $KVM_FSF_TOP_DIR/plugins/vmiop-display.so $KVM_FSF_TOP_DIR/plugins/vmiop-display.so.${orig}
    cp -p $swdev/sw/dev/gpu_drv/chips_a/drivers/fsf/vmioplugin/plugins/display/_out/Linux_amd64_debug/vmiop-display.so $KVM_FSF_TOP_DIR/plugins/vmiop-display.so
    ls -l $KVM_FSF_TOP_DIR/plugins/vmiop-display.so

    mv $KVM_FSF_TOP_DIR/src/qemu-4.2.0.devel.vpath $KVM_FSF_TOP_DIR/src/qemu-4.2.0.devel.vpath.${orig}
    cp -pr $swdev/sw/dev/gpu_drv/chips_a/drivers/fsf/kvm/_out/Linux_amd64_debug/qemu-4.2.0.devel.vpath $KVM_FSF_TOP_DIR/src/
}

function build_fsf_package
{
    # *** Make sure shelved cl 31721306 is upto date
    # also make the changelist match the current change
    # https://confluence.nvidia.com/display/FSF/Building+FSF+Locally
    # see: https://confluence.nvidia.com/display/FSF/FSF+Build+Instructions+for+FSA+Team
    # p4 sync //sw/dev/gpu_drv/chips_a/drivers/fsf/dvs/dvs.sh
    # modify run_nvmake ${vmioplugin_dir} INC_MSG_QUEUE_SIZE=1
    # shelved cl 31072580 https://p4sw-swarm.nvidia.com/changes/31072580
    # shelved cl 31464412
    # create cl with description "Create an FSF package with message queue size 2048"
    # //sw/automation/dvs/dvsbuild/
    # TODO update fsa_build::build_fsf_package

    sw_dev
    cd $swdev/sw/dev/gpu_drv/chips_a/drivers/fsf
    local cl=31721306
    p4 diff @=$cl
    p4 shelve -r -c $cl
    $swdev/sw/automation/dvs/dvsbuild/Linux-x86_64/dvsbuild -c $cl -kw DVS_BUILD_ALL
}

function du_regress {
    cd /home/hwinf-fsa/regress
    local log=$(pwd)/du__$(date +%m_%d_%y__%H_%M_%S).log
    du -hs */*/*/* 2>&1 $log
    see $log
}

# //sw/dev/gpu_drv/chips_a/drivers/fsf/dvs/dvs.sh#13 - edit change 31721306 (text+x)

function execute_fsf_changes 
{
    local action=$1
    local sw=$2

    pushd $sw
    $action $sw/dev/gpu_drv/chips_a/drivers/fsf/tree/install.sh $sw/pvt/svc-hwinf-fsa/fsf/tree/install.sh
    $action $sw/dev/gpu_drv/chips_a/drivers/fsf/tree/scripts/run_guest.sh $sw/pvt/svc-hwinf-fsa/fsf/tree/scripts/run_guest.sh
    $action $sw/dev/gpu_drv/chips_a/drivers/fsf/tree/conf/template.conf $sw/pvt/svc-hwinf-fsa/fsf/tree/conf/template.conf
    $action $sw/dev/gpu_drv/chips_a/drivers/fsf/dvs/common_guest.sh $sw/pvt/svc-hwinf-fsa/fsf/dvs/common_guest.sh
    $action $sw/dev/gpu_drv/chips_a/drivers/fsf/vmioplugin/plugins/display/sim/vmiop-simulation.c $sw/pvt/svc-hwinf-fsa/fsf/vmioplugin/plugins/display/sim/vmiop-simulation.c
    popd
}

function diff_fsf_changes 
{
    execute_fsf_changes "echo diff -s" $swdev/sw
}

function link_tot {
    local src=$KVM_FSF_TOP_DIR/chip/$FSA_BUILD_GPU_CHIP
    local dst=$KVM_FSF_TOP_DIR/fmodel/$FSA_BUILD_GPU_CHIP/fsa-${FSA_BUILD_GPU_CHIP}-tot

    if [[ ! -e $src ]];then
        echo "$src does not exist need to start with FSF fully setup"
        return 0
    fi

    if [[ -d $dst ]];then
        echo "$dst already exists shipping"
        return 0
    fi

    echo "creating and linking $dst" &&
    cp -pr $src $dst &&
    pushd $dst &&
	rm -rf clib fmod amodel &&
	ln -s $nvgpu/clib/ . &&
	ln -s $nvgpu/fmod/ . &&
	ln -s $nvgpu/amodel . &&
	rm  $src &&
	ln -s $dst $src &&
    echo "linked FSA to tot" &&
    popd
} 

# list shared libraries used by process
# https://www.baeldung.com/linux/show-shared-libraries-executables#:~:text=If%20the%20program%20is%20already%20running%2C%20we%20can,the%20library%20will%20show%20up%20in%20this%20file.
function ldd_proc {
    local pid=$1
    awk '$NF!~/\.so/{next} {$0=$NF} !a[$0]++' /proc/${pid}/maps
}

# get shell on machine where I can run unix-build: https://confluence.nvidia.com/display/CORERM/unix-build+and+LSF.
# Best way to find the specs is to look at what DVS is syncing for such a build. From 
#   https://p4viewer.nvidia.com/get///sw/automation/DVS%202.0/Build%20System/Classes/Datab[...]ease_Linux_AMD64_unix-build_Standalone_RM_Test.txt:
#   //sw/automation/DVS 2.0/Build System/Classes/Database_Mappings/gpu_drv_chips_a_hsmb_staging/Release_Linux_AMD64_unix-build_Standalone_RM_Test.txt
#   https://p4viewer.nvidia.com/get///sw/automation/DVS%202.0/Build%20System/Classes/Database_Mappings/gpu_drv_chips/Release_Linux_AMD64_unix-build_Standalone_RM_Test.txt
function sw_lsf {
    export QSUB_DEFAULT_OS=rel75
    export TMOUT=1800
    export PS1="sw_rel75: "
 
    qsub -U spike_unix_build -q o_cpu_16G_8H -n 8 -R "select[defined(affinity)] span[hosts=1] affinity[core(1):membind=localprefer]" -S 32000 -Is  bash
}

function build_nvlink {
    # sw_lsf
    cd $sw/dev/gpu_drv/chips_a/drivers/resman/tests
    $sw/misc/linux/unix-build -u --tools $sw/tools nvmake -j8 amd64 linux debug @nvlink NV_COLOR_OUTPUT=1 NV_FAST_PACKAGE_COMPRESSION=1 NV_COMPRESS_THREADS=16 NV_SPLIT_KERNEL_MODULE=1 2>&1 |tee nvlink_test_build.log
    # in /home/scratch.mwoodpatrick_inf/trees/nvgpu_sw3/sw
    pushd $sw/dev/gpu_drv/chips_a/drivers
        find $sw -type f -name nvlink -exec ls -l {} \;
    popd
    ls -l $sw/dev/gpu_drv/chips_a/drivers/gpgpu/compiler/gpgpu/export/bin/x86_64_Linux_develop/nvlink
}

function build_driver_resman_nvlink {
    cd $sw/dev/gpu_drv/chips_a/drivers/resman/tests
    export NV_TOOLS=$sw/tools

    $sw/misc/linux/unix-build -u --tools $sw/tools $VERBOSE_BUILD --extra $NV_TOOLS nvmake amd64 linux debug -j10 2>&1 |tee nvlink_test_build.log

    # cp _out/Linux_amd64_debug/nvlink $KVM_FSF_TOP_DIR/guest-shared/input/debug_rm_tests
}
    
# [NVSC for Simulator Developers - GPU Tools - Confluence (nvidia.com)](https://nam11.safelinks.protection.outlook.com/?url=https%3A%2F%2Fconfluence.nvidia.com%2Fdisplay%2FGPUTOOL%2FNVSC%2Bfor%2BSimulator%2BDevelopers&data=05%7C01%7Cmwoodpatrick%40nvidia.com%7C1a6b21054a164bc4e4d208dabcea71f2%7C43083d15727340c1b7db39efd9ccc17a%7C0%7C0%7C638030012364136689%7CUnknown%7CTWFpbGZsb3d8eyJWIjoiMC4wLjAwMDAiLCJQIjoiV2luMzIiLCJBTiI6Ik1haWwiLCJXVCI6Mn0%3D%7C3000%7C%7C%7C&sdata=%2FU0zzd53Vhcn4%2FsdJ2DK53DTon%2F2BwAe4jr7Q3H2tug%3D&reserved=0)
# [Debugging the sim in gdb - GPU Tools - Confluence (nvidia.com)](https://nam11.safelinks.protection.outlook.com/?url=https%3A%2F%2Fconfluence.nvidia.com%2Fpages%2Fviewpage.action%3FspaceKey%3DGPUTOOL%26title%3DDebugging%2Bthe%2Bsim%2Bin%2Bgdb%23Debuggingthesimingdb-WhatCommandLine%3F&data=05%7C01%7Cmwoodpatrick%40nvidia.com%7C1a6b21054a164bc4e4d208dabcea71f2%7C43083d15727340c1b7db39efd9ccc17a%7C0%7C0%7C638030012364136689%7CUnknown%7CTWFpbGZsb3d8eyJWIjoiMC4wLjAwMDAiLCJQIjoiV2luMzIiLCJBTiI6Ik1haWwiLCJXVCI6Mn0%3D%7C3000%7C%7C%7C&sdata=TKPADAfEpqa7xQ0MTJKxuxkbKKQIttHsSlD96pUzuI8%3D&reserved=0)
function print_nvsc_tool_dir {
    # get path
    echo "in gdb do dir $(nvrun get_tool_dir nvsc)/clib/nvsim"
}

function remove_regression_tree {
    for d in $@ 
    do
        if [[ -d "$d" ]]; then
            echo "will remove regression directory $d"
            # These kern.log files are links to files which may not exist and remove them first so we don't get error messages of the form
            #	
            #   lrwxrwxrwx 1 mwoodpatrick hardware 71 Nov  8 06:13 build__65159279__11_07_22__15_18_36/fsf_tests/testing_11_08_22__0418/fsf-tree/guest-shared/single_gpu/current/guest/kern.log -> /root/host-shared/single_gpu/current/guest/acos_11_08_22__0613_kern.log
            #	
            #   chmod: cannot access 'build__65099854__11_03_22__04_30_37/fsf_tests/testing_11_03_22__0958/fsf-tree/guest-shared/single_gpu/current/guest/kern.log': Permission denied
	
            find . -type l -exec rm {} \;
            find $d -name kern.log -exec rm {} \;
            find $d -exec chmod u+w {} \;
            rm -rf $d
        else
            echo "$d is not a directory!"
        fi
    done
}

# linux - Monitoring number of Open FDs per process efficiently? - Unix & Linux Stack Exchange
# https://unix.stackexchange.com/questions/365922/monitoring-number-of-open-fds-per-process-efficiently
# https://www.tecmint.com/increase-set-open-file-limits-in-linux/
# https://sysctl-explorer.net/fs/filemax%20&%20filenr/
#   The three values in file-nr denote the number of allocated file handles, the number of allocated but unused file handles, and the maximum number of file handles.
#   sysctl fs.file-nr | awk ' { print $3 } '
# cat /proc/sys/fs/file-max
#   

function check_mqueue {
    local log="mqueue.log"
    for f in /dev/mqueue/* ; do
        echo $f: `date +"%k:%M:%S"` >> $log
        cat $f >> $log
        echo -e "====\n" >> $log
    done;
}

function monitor_open_files {
    rm -f mqueue.log
    rm  -f fd_count.log
    for (( ; ; ))
    do
	    cat /proc/sys/fs/file-nr | awk ' { print $1 } ' | tee -a fd_count.log
        # cat /dev/mqueue/* >> mqueue.log
        # uniq mqueue.log uniq.out
        # mv uniq.out mqueue.log

        check_mqueue
	    sleep 10
    done
}

# package FSF fmodel files
# see slack thread with Aman Pradhan
function tar_fmodel_files {
    local dst=$1
    local srcdir=/home/scratch.mwoodpatrick_gpu_1/trees/fsf_nvgpu_gb102/hw/nvgpu_gb102
    local tarfile=$srcdir/${dst}.tgz
    local logfile=$srcdir/${dst}.log
    echo "Creating $tarfile"

    set -x
    {
        pushd $srcdir &&
        mkdir -p $dst/fmod/lib $dst/clib &&
        cp -pr clib/Linux_GCCR5XC/ $dst/clib &&
        cp -pr clib/Linux_x86_64 $dst/clib &&
        cp -pr fmod/lib/Linux_x86_64 $dst/fmod/lib &&
        p4have > $dst/changelist.txt &&
        tar -czvf $tarfile $dst
    } 2>&1 | tee $logfile
    echo "completed status $(echo $?) see $logfile for details"
    set +x
    popd
}
