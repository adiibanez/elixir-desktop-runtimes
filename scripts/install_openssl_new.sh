#!/bin/bash

THREAD_COUNT=$(sysctl hw.ncpu | awk '{print $2}')

if [ -z "$OPENSSL_PREFIX" ]; then
export OPENSSL_PREFIX=/usr/local/openssl
fi 

if [ -n "$OPENSSL_OPTS" ]; then
    echo OPENSSL_OPTS: $OPENSSL_OPTS
else 
    export OPENSSL_OPTS="no-shared no-dso no-hw no-engine -DNO_FORK"
    # -mios-version-min=13.4
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

rm ./apps/lib/http_server.c

# if [[ ! -d $BUILD_DIR/build/lib ]]; then
# 	./Configure --prefix="$BUILD_DIR/build" --openssldir="$BUILD_DIR/build/ssl" no-shared darwin64-$HOST_ARC-cc CFLAGS="$NATIVE_BUILD_FLAGS"
# 	make clean
# 	make -j$THREAD_COUNT
# 	make install
# 	make clean
# fi

echo ./Configure --prefix=$OPENSSL_PREFIX  $OPENSSL_OPTS $ARCH
#"$@"

# do not build apps including silly forking https server
./Configure --prefix=$OPENSSL_PREFIX no-apps $OPENSSL_OPTS $ARCH && \
make clean  && \
make depend && \
make -j$THREAD_COUNT && \
make install_sw install_ssldirs

echo "OPENSSL INSTALLED $OPENSSL_PREFIX"
ls -lah "$OPENSSL_PREFIX/lib"

#file $OPENSSL_PREFIX/lib/crypto.a