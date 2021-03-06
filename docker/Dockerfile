FROM quay.io/pypa/manylinux1_x86_64:latest

# CMAKE
RUN curl -O -L https://cmake.org/files/v3.9/cmake-3.9.0.tar.gz && \
    tar -xf cmake-3.9.0.tar.gz && \
    cd cmake-3.9.0 && \
    #manylinux1 provides curl-devel equivalent and libcurl statically linked
    # against the same newer OpenSSL as other source-built tools
    # (1.0.2s as of this writing)
    yum -y install zlib-devel && \
    #configure does a bootstrap make under the hood
    export MAKEFLAGS=-j$(getconf _NPROCESSORS_ONLN) && \
    ./configure --system-curl && \
    make && \
    make install && \
    cd .. && \
    rm -rf cmake-3.9.0*

# https://trac.ffmpeg.org/wiki/CompilationGuide/Centos#GettheDependencies
# manylinux provides the toolchain and git; we provide cmake
RUN yum install freetype-devel bzip2-devel zlib-devel -y && \
    mkdir ~/ffmpeg_sources

# Newer openssl configure requires newer perl
RUN curl -O -L https://www.cpan.org/src/5.0/perl-5.20.1.tar.gz && \
    tar -xf perl-5.20.1.tar.gz && \
    cd perl-5.20.1 && \
    ./Configure -des -Dprefix="$HOME/openssl_build" && \
    #perl build scripts do much redundant work
    # if running "make install" separately
    make install -j$(getconf _NPROCESSORS_ONLN) && \
    cd .. && \
    rm -rf perl-5.20.1*

RUN cd ~/ffmpeg_sources && \
    curl -O -L https://github.com/openssl/openssl/archive/OpenSSL_1_1_1c.tar.gz && \
    tar -xf OpenSSL_1_1_1c.tar.gz && \
    cd openssl-OpenSSL_1_1_1c && \
    PERL="$HOME/openssl_build/bin/perl" ./config --prefix="$HOME/ffmpeg_build" --openssldir="$HOME/ffmpeg_build" shared zlib && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    #skip installing documentation
    make install_sw && \
    rm -rf ~/openssl_build

RUN cd ~/ffmpeg_sources && \
    curl -O -L http://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.bz2 && \
    tar -xf nasm-2.14.02.tar.bz2 && cd nasm-2.14.02 && ./autogen.sh && \
    ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install

RUN cd ~/ffmpeg_sources && \
    curl -O -L http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz && \
    tar -xf yasm-1.3.0.tar.gz && \
    cd yasm-1.3.0 && \
    ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install

RUN cd ~/ffmpeg_sources && \
    git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git && \
    cd libvpx && \
    ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm --enable-pic --enable-shared && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install

RUN cd ~/ffmpeg_sources && \
    curl -O -L https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
    tar -xf ffmpeg-snapshot.tar.bz2 && \
    cd ffmpeg && \
    PATH=~/bin:$PATH && \
    PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --extra-cflags="-I$HOME/ffmpeg_build/include" --extra-ldflags="-L$HOME/ffmpeg_build/lib" --enable-openssl --enable-libvpx --enable-shared --enable-pic --bindir="$HOME/bin" && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install && \
    echo "/root/ffmpeg_build/lib/" >> /etc/ld.so.conf && \
    ldconfig && \
    rm -rf ~/ffmpeg_sources

ENV PKG_CONFIG_PATH /usr/local/lib/pkgconfig:/root/ffmpeg_build/lib/pkgconfig
ENV LDFLAGS -L/root/ffmpeg_build/lib

RUN curl -O https://raw.githubusercontent.com/torvalds/linux/v4.14/include/uapi/linux/videodev2.h && \
    curl -O https://raw.githubusercontent.com/torvalds/linux/v4.14/include/uapi/linux/v4l2-common.h && \
    curl -O https://raw.githubusercontent.com/torvalds/linux/v4.14/include/uapi/linux/v4l2-controls.h && \
    curl -O https://raw.githubusercontent.com/torvalds/linux/v4.14/include/linux/compiler.h && \
    mv videodev2.h v4l2-common.h v4l2-controls.h compiler.h /usr/include/linux

ENV PATH "$HOME/bin:$PATH"