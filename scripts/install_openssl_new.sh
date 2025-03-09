#!/bin/bash

if [ -z "$OPENSSL_VERSION" ]; then
export VSN=1.1.1v
export VSN_HASH=d6697e2871e77238460402e9362d47d18382b15ef9f246aba6c7bd780d38a6b0
else
export VSN=$OPENSSL_VERSION
export VSN_HASH=$OPENSSL_HASH
fi

if [ -z "$OPENSSL_PREFIX" ]; then
export PREFIX=/usr/local/openssl
else
export PREFIX=$OPENSSL_PREFIX
fi 

echo "OPENSSL PREFIX: $PREFIX"

if [ -z "$ARCH" ]; then
export BUILD_DIR=_build
#export BASE_DIR=..
else
export BASE_ARCH=$(echo "$ARCH" | sed 's/ -D.*//') 
echo "BASE_ARCH: $BASE_ARCH"
export BUILD_DIR=_build/$BASE_ARCH
#export BASE_DIR=../..
fi

# install openssl
echo "Build and install openssl......"

export BASE_DIR="$(pwd)"

echo "PREFIX: $PREFIX"
echo "BUILD_DIR: $BUILD_DIR"
echo "BASE_DIR: $BASE_DIR"
echo "ARCH: $ARCH"

cd $BUILD_DIR

cp $BASE_DIR/patch/openssl-ios.conf openssl-$VSN/Configurations/15-ios.conf && \
cd openssl-$VSN

echo `pwd`
ls -lah 

echo ./Configure $ARCH --prefix=$PREFIX "$@"
./Configure $ARCH --prefix=$PREFIX "$@"
make clean && make depend && make && make install_sw install_ssldirs

echo "OPENSSL INSTALLED $PREFIX"
