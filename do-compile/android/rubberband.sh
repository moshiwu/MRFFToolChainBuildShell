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

set -e

error_handler() {
    echo "An error occurred!"
    tail -n20 ${MR_BUILD_SOURCE}/config.log
}

trap 'error_handler' ERR

THIS_DIR=$(DIRNAME=$(dirname "$0"); cd "$DIRNAME"; pwd)
cd "$THIS_DIR"

C_FLAGS="$MR_DEFAULT_CFLAGS"
EXTRA_LDFLAGS=
LDFLAGS="$C_FLAGS $EXTRA_LDFLAGS"

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

# 创建系统头文件符号链接
echo "创建系统头文件符号链接..."
if [ ! -d "src/system" ]; then
    mkdir -p "src/system"
fi

# 检查 sysutils.h 文件是否存在
if [ -f "src/common/sysutils.h" ]; then
    ln -sf "../common/sysutils.h" "src/system/sysutils.h"
    echo "系统头文件符号链接创建完成"
fi

if [[ -f "./config.h" ]]; then
    echo 'reuse configure'
else
    echo
    echo "CC: $MR_CC"
    echo "CFLAGS: $C_FLAGS"
    echo "LDFLAG:$LDFLAGS"
    echo
    ./configure \
        --prefix="$MR_BUILD_PREFIX" \
        --host="$MR_HOST" \
        --enable-shared=no \
        --cc="$MR_CC" \
        --cxx="$MR_CXX" \
        --extra-cflags="$C_FLAGS -DUSE_PTHREADS -DUSE_BUILTIN_FFT -DHAVE_BQRESAMPLER -DUSE_BQRESAMPLER -I./src -I./src/common" \
        --extra-cxxflags="$C_FLAGS -DUSE_PTHREADS -DUSE_BUILTIN_FFT -DHAVE_BQRESAMPLER -DUSE_BQRESAMPLER -I./src -I./src/common" \
        --extra-ldflags="$LDFLAGS"
fi

#----------------------
echo "----------------------"
echo "[*] compile"

make -j$MR_HOST_NPROC >/dev/null

cp config.* $MR_BUILD_PREFIX
make install >/dev/null

#----------------------
echo "----------------------"
echo "[*] copy headers"

mkdir -p $MR_BUILD_PREFIX/include/rubberband
cp -f $MR_BUILD_SOURCE/rubberband/rubberband-c.h $MR_BUILD_PREFIX/include/rubberband/
cp -f $MR_BUILD_SOURCE/rubberband/rubberband.h $MR_BUILD_PREFIX/include/rubberband/ 

# 创建pkgconfig目录和配置文件
echo "----------------------"
echo "[*] 创建 pkg-config 文件"

mkdir -p "$MR_BUILD_PREFIX/lib/pkgconfig"
cat > "$MR_BUILD_PREFIX/lib/pkgconfig/rubberband.pc" << EOF
prefix=$MR_BUILD_PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: rubberband
Description: Audio time-stretching and pitch-shifting library
Version: 4.0.0
Libs: -L\${libdir} -lrubberband -lstdc++
Cflags: -I\${includedir}
EOF

# 设置正确的权限
chmod 644 "$MR_BUILD_PREFIX/lib/pkgconfig/rubberband.pc"
echo "pkg-config 文件创建完成" 