OPENSSL_HASH=002a2d6b30b58bf4bea46c43bdd96365aaf8daa6c428782aa4feee06da197df3
OPENSSL_VERSION=3.4.1
OTP_TAG=OTP-27.2.4
KERL_CONFIGURATION_OPTIONS="--disable-year2038"

export RUSTLER_BTLEPLUG_BUILD=1
export WASMEX_BUILD=1
export RUST_TARGET=ios-arm64
#x86_64-apple-ios
# ["ios", "ios-arm64", "iossimulator-x86_64", "iossimulator-arm64"]
#--nifs "openssl,rustler_btleplug"
mix package.ios.runtime
#--arch ios-arm64

#mix package.ios.nif iossimulator-x86_64 rustler_btleplug