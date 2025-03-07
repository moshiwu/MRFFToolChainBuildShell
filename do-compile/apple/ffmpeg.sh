#! /usr/bin/env bash
#
# Copyright (C) 2021 Matt Reach<qianlongxu@gmail.com>

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This script is based on projects below
# https://github.com/bilibili/ijkplayer

set -e

error_handler() {
    echo "An error occurred!"
    tail -n20 ${MR_BUILD_SOURCE}/ffbuild/config.log
}

trap 'error_handler' ERR

THIS_DIR=$(DIRNAME=$(dirname "$0"); cd "$DIRNAME"; pwd)
cd "$THIS_DIR"

# ffmpeg config options
source $MR_SHELL_CONFIGS_DIR/ffconfig/module.sh
source $MR_SHELL_CONFIGS_DIR/ffconfig/auto-detect-third-libs.sh

CFG_FLAGS=
CFG_FLAGS="$CFG_FLAGS $COMMON_FF_CFG_FLAGS"
CFG_FLAGS="$CFG_FLAGS $THIRD_CFG_FLAGS"

C_FLAGS="$MR_DEFAULT_CFLAGS"
EXTRA_LDFLAGS=
LDFLAGS="$C_FLAGS $EXTRA_LDFLAGS"
# C_FLAGS="$C_FLAGS -I/Users/matt/GitWorkspace/MoltenVK/Package/Release/MoltenVK/include"
# use system xml2 lib
# C_FLAGS="$C_FLAGS $(xml2-config --prefix=${MR_SYS_ROOT}/usr --cflags)"
# LDFLAGS="$C_FLAGS $(xml2-config --prefix=${MR_SYS_ROOT}/usr --libs)"

# LDFLAGS="$LDFLAGS -framework IOKit -framework Metal -framework IOSurface -framework CoreGraphics -framework QuartzCore -framework AppKit -framework Foundation -lc++ /Users/matt/GitWorkspace/MoltenVK/Package/Release/MoltenVK/static/MoltenVK.xcframework/macos-arm64_x86_64/libMoltenVK.a"
echo "----------------------"
echo "[*] configure"

if [[ ! -d $MR_BUILD_SOURCE ]]; then
    echo ""
    echo "!! ERROR"
    echo "!! Can not find $MR_BUILD_SOURCE directory for $MR_BUILD_NAME"
    echo "!! Run 'init-*.sh' first"
    echo ""
    exit 1
fi

cd $MR_BUILD_SOURCE
if [[ -f "./config.h" ]]; then
    echo 'reuse configure'
else
    echo
    echo "CC: $MR_CC"
    echo "CFLAGS: $C_FLAGS"
    echo "LDFLAG:$LDFLAGS"
    echo "FF_CFG_FLAGS: $CFG_FLAGS"
    echo

    # 设置PKG_CONFIG_PATH环境变量以便找到所有第三方库
    PKGCONFIG_DIRS=(
        "rubberband"
        "opus"
        "x264"
        "x265"
        "vpx"
        "fdk-aac"
        "lame"
        "aom"
        "dav1d"
        "openssl"
        "ass"
        "freetype"
        "fontconfig"
        "fribidi"
        "xml2"
        "bluray"
        "srt"
        "rist"
        "ssh"
        "zmq"
        "webp"
        "vorbis"
        "ogg"
        "uavs3d"
        "fftw3"
    )
    
    # 确定正确的架构名称和配置选项
    ACTUAL_ARCH="$MR_ARCH"
    ARCH_SPECIFIC_CONFIG=""
    
    if [[ "$MR_BUILD_NAME" == *"simulator"* ]]; then
        echo "检测到模拟器目标: $MR_BUILD_NAME"
        if [[ "$MR_BUILD_NAME" == *"arm64_simulator"* ]]; then
            ACTUAL_ARCH="arm64_simulator"
            echo "使用架构: arm64_simulator"
        elif [[ "$MR_BUILD_NAME" == *"x86_64_simulator"* ]]; then
            ACTUAL_ARCH="x86_64_simulator"
            echo "使用架构: x86_64_simulator"
            # 对于x86_64模拟器，禁用所有与ARM相关的特性
            ARCH_SPECIFIC_CONFIG="--disable-asm --disable-neon --disable-inline-asm"
            echo "禁用ARM特有指令以避免架构不兼容问题"
        fi
    fi
    
    PKG_CONFIG_PATH_NEW=""
    for lib in "${PKGCONFIG_DIRS[@]}"; do
        # 使用实际的架构名称
        lib_path="${MR_SHELL_ROOT_DIR}/build/product/ios/${lib}-${ACTUAL_ARCH}/lib/pkgconfig"
        if [[ -d "$lib_path" ]]; then
            if [[ -z "$PKG_CONFIG_PATH_NEW" ]]; then
                PKG_CONFIG_PATH_NEW="$lib_path"
            else
                PKG_CONFIG_PATH_NEW="$PKG_CONFIG_PATH_NEW:$lib_path"
            fi
            echo "添加库路径: $lib_path"
        fi
    done
    
    if [[ ! -z "$PKG_CONFIG_PATH_NEW" ]]; then
        export PKG_CONFIG_PATH="$PKG_CONFIG_PATH_NEW:$PKG_CONFIG_PATH"
    fi
    
    # 确保pkg-config使用静态库模式
    export PKG_CONFIG="pkg-config --static"
    echo "PKG_CONFIG_PATH: $PKG_CONFIG_PATH"

    # 准备包含路径和库路径
    EXTRA_CFLAGS_LIBS=""
    EXTRA_LDFLAGS_LIBS=""
    for lib in "${PKGCONFIG_DIRS[@]}"; do
        # 使用实际的架构名称
        lib_include_path="${MR_SHELL_ROOT_DIR}/build/product/ios/${lib}-${ACTUAL_ARCH}/include"
        lib_lib_path="${MR_SHELL_ROOT_DIR}/build/product/ios/${lib}-${ACTUAL_ARCH}/lib"
        
        if [[ -d "$lib_include_path" ]]; then
            EXTRA_CFLAGS_LIBS="$EXTRA_CFLAGS_LIBS -I$lib_include_path"
        fi
        if [[ -d "$lib_lib_path" ]]; then
            EXTRA_LDFLAGS_LIBS="$EXTRA_LDFLAGS_LIBS -L$lib_lib_path"
        fi
    done

    # 配置FFmpeg
    ./configure \
        $CFG_FLAGS \
        --prefix=$MR_BUILD_PREFIX \
        --cc="$MR_CC" \
        --cxx="$MR_CXX" \
        --as="$MR_AS" \
        --ld="$MR_LD" \
        --target-os=darwin \
        --arch=${FFARCH} \
        --extra-cflags="$C_FLAGS $EXTRA_CFLAGS_LIBS" \
        --extra-ldflags="$LDFLAGS $EXTRA_LDFLAGS_LIBS -framework Accelerate" \
        --enable-static \
        --enable-pic \
        --enable-librubberband \
        --enable-libopus \
        --disable-shared \
        --pkg-config-flags="--static" \
        $ARCH_SPECIFIC_CONFIG \
        $USER_CFG
fi

#----------------------
echo "----------------------"
echo "[*] compile"

make -j$MR_HOST_NPROC >/dev/null

cp config.* $MR_BUILD_PREFIX
make install >/dev/null
mkdir -p $MR_BUILD_PREFIX/include/libffmpeg
cp -f config.h $MR_BUILD_PREFIX/include/libffmpeg/
[ -e config_components.h ] && cp -f config_components.h $MR_BUILD_PREFIX/include/libffmpeg/
# copy private header for ffmpeg-kit.
[ -e $MR_BUILD_SOURCE/libavutil/getenv_utf8.h ] && cp -f $MR_BUILD_SOURCE/libavutil/getenv_utf8.h $MR_BUILD_PREFIX/include/libavutil/
cp -f $MR_BUILD_SOURCE/libavutil/internal.h $MR_BUILD_PREFIX/include/libavutil/
cp -f $MR_BUILD_SOURCE/libavutil/libm.h $MR_BUILD_PREFIX/include/libavutil/
[ -e $MR_BUILD_SOURCE/libavutil/attributes_internal.h ] && cp -f $MR_BUILD_SOURCE/libavutil/attributes_internal.h $MR_BUILD_PREFIX/include/libavutil/
cp -f $MR_BUILD_SOURCE/libavcodec/mathops.h $MR_BUILD_PREFIX/include/libavcodec/

mkdir -p $MR_BUILD_PREFIX/include/libavcodec/x86/
cp -f $MR_BUILD_SOURCE/libavcodec/x86/mathops.h $MR_BUILD_PREFIX/include/libavcodec/x86/
mkdir -p $MR_BUILD_PREFIX/include/libavutil/x86/
cp -f $MR_BUILD_SOURCE/libavutil/x86/asm.h $MR_BUILD_PREFIX/include/libavutil/x86/