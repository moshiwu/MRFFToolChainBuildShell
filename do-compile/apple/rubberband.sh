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
    if [[ -f ${MR_BUILD_SOURCE}/config.log ]]; then
        tail -n20 ${MR_BUILD_SOURCE}/config.log
    else
        echo "No config.log available"
    fi
}

trap 'error_handler' ERR

THIS_DIR=$(DIRNAME=$(dirname "$0"); cd "$DIRNAME"; pwd)
cd "$THIS_DIR"

C_FLAGS="$MR_DEFAULT_CFLAGS"
EXTRA_LDFLAGS=
LDFLAGS="$C_FLAGS $EXTRA_LDFLAGS"

# 添加C++11支持
C_FLAGS="$C_FLAGS -std=c++11"
LDFLAGS="$LDFLAGS -std=c++11"

echo "修改后的编译标志："
echo "C_FLAGS: $C_FLAGS"
echo "LDFLAGS: $LDFLAGS"

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

echo
echo "CC: $MR_CC"
echo "CFLAGS: $C_FLAGS"
echo "LDFLAG:$LDFLAGS"
echo

# 检查并创建 fftw3.h 文件
FFTW3_INCLUDE_DIR="${MR_SHELL_ROOT_DIR}/build/product/ios/fftw3-${MR_ARCH}/include"
FFTW3_HEADER="${FFTW3_INCLUDE_DIR}/fftw3.h"

# 创建 fftw3.h 如果它不存在
if [ ! -f "$FFTW3_HEADER" ]; then
    echo "创建 fftw3.h 文件..."
    mkdir -p "$FFTW3_INCLUDE_DIR"
    
    # 检查子目录中是否有头文件
    if [ -f "${FFTW3_INCLUDE_DIR}/fftw3/fftw3.h" ]; then
        ln -sf "${FFTW3_INCLUDE_DIR}/fftw3/fftw3.h" "$FFTW3_HEADER"
    else
        # 创建一个最小的 fftw3.h 头文件
        cat > "$FFTW3_HEADER" << 'EOF'
#ifndef FFTW3_H
#define FFTW3_H

#include <stdio.h>

/* 定义FFTW单精度基本类型 */
typedef float fftwf_real;
typedef struct { fftwf_real r, i; } fftwf_complex;

/* 定义FFTW双精度基本类型 */
typedef double fftw_real;
typedef struct { fftw_real r, i; } fftw_complex;

/* 定义FFTW计划类型 */
typedef void *fftwf_plan;
typedef void *fftw_plan;

/* 编译时环境设置 */
#define FFTW_FORWARD (-1)
#define FFTW_BACKWARD 1
#define FFTW_ESTIMATE (1U << 6)

/* FFTW单精度 API函数原型 */
fftwf_plan fftwf_plan_dft_1d(int n, fftwf_complex *in, fftwf_complex *out, int sign, unsigned flags);
fftwf_plan fftwf_plan_dft_2d(int n0, int n1, fftwf_complex *in, fftwf_complex *out, int sign, unsigned flags);
fftwf_plan fftwf_plan_dft_3d(int n0, int n1, int n2, fftwf_complex *in, fftwf_complex *out, int sign, unsigned flags);
fftwf_plan fftwf_plan_dft_r2c_1d(int n, float *in, fftwf_complex *out, unsigned flags);
fftwf_plan fftwf_plan_dft_c2r_1d(int n, fftwf_complex *in, float *out, unsigned flags);
void fftwf_execute(const fftwf_plan plan);
void fftwf_destroy_plan(fftwf_plan plan);
void fftwf_cleanup(void);
void *fftwf_malloc(size_t n);
void fftwf_free(void *p);

/* FFTW双精度 API函数原型 */
fftw_plan fftw_plan_dft_1d(int n, fftw_complex *in, fftw_complex *out, int sign, unsigned flags);
fftw_plan fftw_plan_dft_2d(int n0, int n1, fftw_complex *in, fftw_complex *out, int sign, unsigned flags);
fftw_plan fftw_plan_dft_3d(int n0, int n1, int n2, fftw_complex *in, fftw_complex *out, int sign, unsigned flags);
fftw_plan fftw_plan_dft_r2c_1d(int n, double *in, fftw_complex *out, unsigned flags);
fftw_plan fftw_plan_dft_c2r_1d(int n, fftw_complex *in, double *out, unsigned flags);
void fftw_execute(const fftw_plan plan);
void fftw_destroy_plan(fftw_plan plan);
void fftw_cleanup(void);
void *fftw_malloc(size_t n);
void fftw_free(void *p);

#endif /* FFTW3_H */
EOF
    fi
    echo "fftw3.h 创建完成"
fi

# 强制使用手动编译方法
echo "跳过 Meson 构建系统，直接使用手动编译..."

# 查找所有源文件
echo "查找源文件..."
SRC_FILES=$(find . -name "*.cpp" \
    -not -path "./programs/*" \
    -not -path "./vamp/*" \
    -not -path "./tests/*" \
    -not -path "./dotnet/*" \
    -not -path "./jni/*" \
    -not -path "./win32/*" \
    -not -path "./src/test/*" \
    -not -path "./ladspa-lv2/*" \
    -not -path "./main/*" \
    -not -path "./src/jni/*")

# 输出找到的文件列表
echo "找到以下源文件："
echo "$SRC_FILES"

# 直接修改有问题的源文件
echo "修复 VectorOpsComplex.h 中的 sincosf 和 sincos 问题..."
if [ -f "src/common/VectorOpsComplex.h" ]; then
    # 备份原始文件
    cp -f src/common/VectorOpsComplex.h src/common/VectorOpsComplex.h.bak
    
    # 添加自定义 sincosf 和 sincos 函数
    cat > src/common/VectorOpsComplex.h.new << 'EOF'
#ifndef sincosf
#define sincosf(x, s, c) { *(s) = sinf(x); *(c) = cosf(x); }
#endif

#ifndef sincos
#define sincos(x, s, c) { *(s) = sin(x); *(c) = cos(x); }
#endif

EOF
    
    # 将原文件内容附加到新文件
    cat src/common/VectorOpsComplex.h.bak >> src/common/VectorOpsComplex.h.new
    
    # 用新文件替换原文件
    mv src/common/VectorOpsComplex.h.new src/common/VectorOpsComplex.h
    
    echo "VectorOpsComplex.h 已修改"
fi

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

# 创建目标目录
mkdir -p build/obj

# 编译每个源文件
echo "编译源文件..."
OBJECTS=""
for src in $SRC_FILES; do
    obj="build/obj/$(basename ${src%.cpp}.o)"
    echo "编译 $src 到 $obj"
    $MR_CXX $C_FLAGS -I. -I./rubberband -I./src -I./src/common -I${MR_SHELL_ROOT_DIR}/build/product/ios/fftw3-${MR_ARCH}/include -DUSE_BUILTIN_FFT -DHAVE_BQRESAMPLER -DUSE_BQRESAMPLER -DNO_THREAD_CHECKS -DUSE_PTHREADS -DNO_TIMING -DNDEBUG -c $src -o $obj
    OBJECTS="$OBJECTS $obj"
done

# 创建静态库
echo "创建静态库..."
mkdir -p "$MR_BUILD_PREFIX/lib"
ar rcs "$MR_BUILD_PREFIX/lib/librubberband.a" $OBJECTS
ranlib "$MR_BUILD_PREFIX/lib/librubberband.a"

# 复制头文件
echo "复制头文件..."
mkdir -p "$MR_BUILD_PREFIX/include/rubberband"
cp -f rubberband/*.h "$MR_BUILD_PREFIX/include/rubberband/"

echo "----------------------"
echo "[*] rubberband 库编译和安装完成"

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
Libs: -L\${libdir} -lrubberband -lstdc++ -framework Accelerate
Cflags: -I\${includedir}
EOF

# 设置正确的权限
chmod 644 "$MR_BUILD_PREFIX/lib/pkgconfig/rubberband.pc"
echo "pkg-config 文件创建完成" 