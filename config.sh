# Define custom utilities
# Test for macOS with [ -n "$IS_OSX" ]

function pre_build {
    # Any stuff that you need to do before you start building the wheels
    # Runs in the root directory of this repository.
    pushd decord
    mkdir build
    pushd build
    cmake ..
    make
    mkdir -p /tmp/build
    cp libdecord.so /tmp/build/libdecord.so
    popd
    popd
}

function repair_wheelhouse {
    local in_dir=$1
    local out_dir=${2:-$in_dir}
    for whl in $in_dir/*.whl; do
        auditwheel repair $whl -w $out_dir/
        # Remove unfixed if writing into same directory
        if [ "$in_dir" == "$out_dir" ]; then rm $whl; fi
    done
    chmod -R a+rwX $out_dir
}

function build_wheel_cmd {
    # Builds wheel with named command, puts into $WHEEL_SDIR
    #
    # Parameters:
    #     cmd  (optional, default "pip_wheel_cmd"
    #        Name of command for building wheel
    #     repo_dir  (optional, default $REPO_DIR)
    #
    # Depends on
    #     REPO_DIR  (or via input argument)
    #     WHEEL_SDIR  (optional, default "wheelhouse")
    #     BUILD_DEPENDS (optional, default "")
    #     MANYLINUX_URL (optional, default "") (via pip_opts function)
    pwd
    local cmd=${1:-pip_wheel_cmd}
    local repo_dir=${2:-$REPO_DIR}
    [ -z "$repo_dir" ] && echo "repo_dir not defined" && exit 1
    local wheelhouse=$(abspath ${WHEEL_SDIR:-wheelhouse})
    start_spinner
    if [ -n "$(is_function "pre_build")" ]; then pre_build; fi
    stop_spinner
    if [ -n "$BUILD_DEPENDS" ]; then
        pip install $(pip_opts) $BUILD_DEPENDS
    fi
    (cd decord/python && $cmd $wheelhouse)
    repair_wheelhouse $wheelhouse
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    python --version
    python -c 'import sys; import decord; sys.exit()'
}