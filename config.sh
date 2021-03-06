# Define custom utilities
# Test for macOS with [ -n "$IS_OSX" ]

function install_delocate {
    check_pip
    $PIP_CMD install git+https://github.com/zhreshold/delocate@fix-deep-init
}

function pre_build {
    # Any stuff that you need to do before you start building the wheels
    # Runs in the root directory of this repository.
    if [ -n "$IS_OSX" ]; then
        echo "pre_build on max..."
        export HOMEBREW_NO_GITHUB_API=1
        export HOMEBREW_NO_AUTO_UPDATE=1
        export HOMEBREW_NO_ANALYTICS=1
        # brew install ffmpeg
        # brew install x264 x265 xvid openjpeg libvpx lame yasm --ignore-dependencies
        brew tap homebrew-ffmpeg/ffmpeg
        brew install homebrew-ffmpeg/ffmpeg/ffmpeg
        brew unlink python
    else
        echo "pre_build on linux..."
    fi
    pushd decord
    mkdir build
    pushd build
    if [ -n "$IS_OSX" ]; then
        clang --version
        cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-arch x86_64" -DCMAKE_C_FLAGS="-arch x86_64" -DCMAKE_OSX_ARCHITECTURES="x86_64"
    else
        cmake .. -DCMAKE_BUILD_TYPE=Release
    fi
    make
    mkdir -p /tmp/build
    cp libdecord.* /tmp/build/
    export DECORD_LIBRARY_PATH=/tmp/build/
    popd
    popd
}

function repair_wheelhouse {
    local in_dir=$1
    local out_dir=${2:-$in_dir}
    echo $out_dir
    if [ -n "$IS_OSX" ]; then
        local wheelhouse=$1
        install_delocate
        delocate-wheel $wheelhouse/*.whl # copies library dependencies into wheel
    else
        for whl in $in_dir/*.whl; do
            # rename to py2.py3
            local new_whl=${whl//-py3/-py2.py3}
            mv $whl $new_whl

            auditwheel repair $new_whl -w $out_dir/
            # Remove unfixed if writing into same directory
            if [ "$in_dir" == "$out_dir" ]; then rm $new_whl; fi
            ls $out_dir/
        done
        chmod -R a+rwX $out_dir
    fi

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
    if [ -n "$IS_OSX" ]; then
        get_macpython_environment $MB_PYTHON_VERSION venv
        source venv/bin/activate
    fi
    if [ -n "$BUILD_DEPENDS" ]; then
        pip install $(pip_opts) $BUILD_DEPENDS
    fi
    # replace a modified version of setup.py
    cp setup.py decord/python/
    cat decord/python/setup.py
    (cd decord/python && $cmd $wheelhouse)
    repair_wheelhouse $wheelhouse
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    echo "Starting tests"

    if [ -n "$IS_OSX" ]; then
      echo "Running for OS X"
      cd ../tests/
    else
      echo "Running for linux"
      cd /io/tests/
    fi

    pwd
    ls
    python --version
    python -c 'import sys; import decord; sys.exit()'
    python -m unittest test
}

function clean_code {
    local repo_dir=${1:-$REPO_DIR}
    local build_commit=${2:-$BUILD_COMMIT}
    [ -z "$repo_dir" ] && echo "repo_dir not defined" && exit 1
    [ -z "$build_commit" ] && echo "build_commit not defined" && exit 1
    # The package $repo_dir may be a submodule. git submodules do not
    # have a .git directory. If $repo_dir is copied around, tools like
    # Versioneer which require that it be a git repository are unable
    # to determine the version.  Give submodule proper git directory
    fill_submodule "$repo_dir"
    (cd $repo_dir \
        && git fetch origin \
        && git checkout $build_commit \
        && git clean -fxd \
        && git reset --hard \
        && git pull \
        && git submodule update --init --recursive)
}

function remove_travis_ve_pip {
    # Remove travis installs of virtualenv and pip
    # FIXME: What if virtualenv is installed but pip is not?
    if [ "$(sudo which virtualenv)" == /usr/local/bin/virtualenv ] && [ "$(sudo which pip)" == /usr/local/bin/pip ]; then
        sudo pip uninstall -y virtualenv;
    fi
    # if [ "$(sudo which pip)" == /usr/local/bin/pip ]; then
    #     sudo pip uninstall -y pip;
    # fi
}
