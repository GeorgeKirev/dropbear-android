#!/bin/bash
set -e

export DROPBEAR_VERSION=2018.76
export HOST_TAG=linux-x86_64
export NDK_VERSION=android-ndk-r19b

if [ ! -f ./$NDK_VERSION-$HOST_TAG.zip ]; then
  wget https://dl.google.com/android/repository/$NDK_VERSION-$HOST_TAG.zip
fi
unzip $NDK_VERSION-$HOST_TAG.zip

HOST=arm-linux-androideabi

export NDK=`pwd`/$NDK_VERSION
export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/$HOST_TAG
export AR=$TOOLCHAIN/bin/arm-linux-androideabi-ar
export AS=$TOOLCHAIN/bin/arm-linux-androideabi-as
export CC=$TOOLCHAIN/bin/armv7a-linux-androideabi26-clang
export CXX=$TOOLCHAIN/bin/armv7a-linux-androideabi26-clang++
export LD=$TOOLCHAIN/bin/arm-linux-androideabi-ld
export RANLIB=$TOOLCHAIN/bin/arm-linux-androideabi-ranlib
export STRIP=$TOOLCHAIN/bin/arm-linux-androideabi-strip

# Download the latest version of dropbear SSH
if [ ! -f ./dropbear-$DROPBEAR_VERSION.tar.bz2 ]; then
    wget -O ./dropbear-$DROPBEAR_VERSION.tar.bz2 https://matt.ucc.asn.au/dropbear/releases/dropbear-$DROPBEAR_VERSION.tar.bz2
fi

# Start each build with a fresh source copy
rm -rf ./dropbear-$DROPBEAR_VERSION
tar xjf dropbear-$DROPBEAR_VERSION.tar.bz2

# Change to dropbear directory
cd dropbear-$DROPBEAR_VERSION

# Apply the new config.guess and config.sub now so they're not patched
cp ../config.guess ../config.sub .

patch -p1 < ../android-compat.patch

./configure --host=arm-linux-androideabi --disable-utmp --disable-utmpx --disable-wtmp --prefix=`pwd`/install

cp ../default_options.h .

# disable password auth due to missing crypt()
sed -i -e 's/#define DROPBEAR_SVR_PASSWORD_AUTH 1/#define DROPBEAR_SVR_PASSWORD_AUTH 0/g' default_options.h

make -j8 || true
make install
cd ..



## RSYNC
wget https://download.samba.org/pub/rsync/nightly/rsync-HEAD.tar.gz
tar xvf rsync-*.tar.gz
rm rsync*.tar.gz
cd rsync-HEAD*
./configure --host=arm-linux-androideabi CFLAGS='-Os -W -Wall -fPIE' LDFLAGS='-fPIE -pie -static' --with-included-popt --with-included-zlib
make -j8
