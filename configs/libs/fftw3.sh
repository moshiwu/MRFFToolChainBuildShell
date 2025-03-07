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

export LIB_NAME='fftw3'
export LIPO_LIBS="libfftw3"
export GIT_LOCAL_REPO=extra/fftw3
export GIT_COMMIT=fftw-3.3.10
export REPO_DIR=fftw3
export GIT_REPO_VERSION=3.3.10

# you can export GIT_FFTW3_UPSTREAM=git@xx:yy/fftw3.git use your mirror
if [[ "$GIT_FFTW3_UPSTREAM" != "" ]] ;then
    export GIT_UPSTREAM="$GIT_FFTW3_UPSTREAM"
else
    export GIT_UPSTREAM=https://github.com/FFTW/fftw3.git
fi

# pre compiled
export PRE_COMPILE_TAG=fftw3-3.3.10-250227145407
export PRE_COMPILE_TAG_TVOS=fftw3-3.3.10-250227145407
export PRE_COMPILE_TAG_MACOS=fftw3-3.3.10-250227145407
export PRE_COMPILE_TAG_IOS=fftw3-3.3.10-250227145407
export PRE_COMPILE_TAG_ANDROID=fftw3-3.3.10-250227145407 