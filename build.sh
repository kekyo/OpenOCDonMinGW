#!/bin/bash

set -e

BUILD=${BUILD:-`gcc -dumpmachine`}
SUFFIX=${SUFFIX:-`date --iso-8601`}

OPENOCD_VERSION=${OPENOCD_VERSION:-0.10.0}
OPENOCD=${OPENOCD:-openocd-${OPENOCD_VERSION}}

BASE=`pwd`
STAGE=${BASE}/stage
ARTIFACTS=${BASE}/artifacts

PREFIX=${STAGE}/${BUILD}/${OPENOCD}

NPROC=${NPROC:-$((`nproc`*2))}
PARALLEL=${PARALLEL:--j${NPROC}}

PATH=${STAGE}:$PATH; export PATH

# pacman -S unzip bzip2 base-devel mingw-w64-i686-toolchain mingw-w64-i686-libusb mingw-w64-i686-libusb-compat-git mingw-w64-i686-hidapi mingw-w64-i686-libftdi

echo "# ==============================================================="
echo "# download"

mkdir -p artifacts
pushd artifacts

if [ ! -f ${OPENOCD}.zip ]; then
    wget https://astuteinternet.dl.sourceforge.net/project/openocd/openocd/${OPENOCD_VERSION}/${OPENOCD}.zip
fi

popd

echo "# ==============================================================="
echo "# build"

mkdir -p stage
pushd stage

rm -rf ${OPENOCD}
unzip ${ARTIFACTS}/${OPENOCD}.zip

pushd ${OPENOCD}

rm -rf build
mkdir -p build
pushd build
../configure --prefix=${PREFIX} \
    --enable-static \
    --disable-gccwarnings \
    --enable-remote-bitbang \
    --enable-internal-jimtcl \
    --enable-internal-libjaylink \
    CFLAGS="-O2 -fomit-frame-pointer -static" \
    LDFLAGS="-static"
make ${PARALLEL}
make install
popd

popd

echo "# ==============================================================="
echo "# collect"

COLLECT=`pwd`/../artifacts/${OPENOCD}_${BUILD}_${SUFFIX}.tar.bz2

pushd ${BUILD}
tar -jcvf ${COLLECT} ${OPENOCD}
popd

popd
