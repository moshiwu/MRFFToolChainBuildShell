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
if [[ -f "./config.h" ]]; then
    echo 'reuse configure'
else
    echo
    echo "CC: $MR_CC"
    echo "CFLAGS: $C_FLAGS"
    echo "LDFLAG:$LDFLAGS"
    echo
    ./bootstrap.sh
    CC="$MR_CC" \
    CXX="$MR_CXX" \
    CFLAGS="$C_FLAGS" \
    CXXFLAGS="$C_FLAGS" \
    LDFLAGS="$LDFLAGS" \
    ./configure \
        --prefix="$MR_BUILD_PREFIX" \
        --host="$MR_HOST" \
        --enable-shared=no \
        --enable-single \
        --enable-threads
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

mkdir -p $MR_BUILD_PREFIX/include/fftw3
cp -f $MR_BUILD_SOURCE/api/fftw3.h $MR_BUILD_PREFIX/include/fftw3/
cp -f $MR_BUILD_SOURCE/api/fftw3.f $MR_BUILD_PREFIX/include/fftw3/
cp -f $MR_BUILD_SOURCE/api/fftw3l.f03 $MR_BUILD_PREFIX/include/fftw3/
cp -f $MR_BUILD_SOURCE/api/fftw3q.f $MR_BUILD_PREFIX/include/fftw3/ 