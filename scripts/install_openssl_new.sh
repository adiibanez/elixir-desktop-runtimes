#!/bin/bash

THREAD_COUNT=$(sysctl hw.ncpu | awk '{print $2}')

if [ -z "$OPENSSL_PREFIX" ]; then
export OPENSSL_PREFIX=/usr/local/openssl
fi 

if [ -n "$OPENSSL_OPTS" ]; then
    echo OPENSSL_OPTS: $OPENSSL_OPTS
else 
    export OPENSSL_OPTS="no-shared"
fi 


echo "OPENSSL PREFIX: $OPENSSL_PREFIX"

# install openssl
echo "Build and install openssl......"
export BASE_DIR="$(pwd)"

echo "PREFIX: $OPENSSL_PREFIX"
echo "BUILD_DIR: $BUILD_DIR"
echo "BASE_DIR: $BASE_DIR"
echo "ARCH: $ARCH"

cd openssl-$OPENSSL_VERSION

echo `pwd`
# ls -lah 

echo ./Configure --prefix=$OPENSSL_PREFIX  $OPENSSL_OPTS $ARCH 
#"$@"

./Configure --prefix=$OPENSSL_PREFIX  $OPENSSL_OPTS $ARCH && \
make clean  && \
make depend && \
make -j$THREAD_COUNT && \
make install_sw install_ssldirs

echo "OPENSSL INSTALLED $OPENSSL_PREFIX"
ls -lah "$OPENSSL_PREFIX/lib"

#file $OPENSSL_PREFIX/lib/crypto.a