#LIB_ARM=/Users/adrianibanez/Documents/projects/2024_sensor-platform/checkouts/elixir-desktop-ios-example-app/liberlang.xcframework/ios-arm64/liberlang.a
#LIB_X86=/Users/adrianibanez/Documents/projects/2024_sensor-platform/checkouts/elixir-desktop-ios-example-app/liberlang.xcframework/ios-x86_64-simulator/liberlang.a

if [[ ! -z $LIB_ARM ]]; then
  echo "LIB_ARM: $LIB_ARM"
# nm -gU $LIB_ARM | grep -E "SSL_|crypto|erl_start"
  nm -gU $LIB_ARM | grep -E "erl_start"
  xcrun --sdk iphoneos clang -o test_erl_start test_erl_start.c \
      -arch arm64 \
      -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
      -Wl,-force_load,$LIB_ARM

  echo "Lib arm: $LIB_ARM seems fine, no errors so far"
fi

if [[ ! -z $LIB_X86 ]]; then
  
  echo "LIB_X86: $LIB_X86"
  # nm -gU $LIB_X86 | grep -E "SSL_|crypto"
  nm -gU $LIB_X86 | grep -E "erl_start"
  xcrun --sdk iphonesimulator clang -o test_erl_start_sim test_erl_start.c \
      -arch x86_64 \
      -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path) \
      -Wl,-force_load,$LIB_X86
  echo "Lib x86: $LIB_X86 seems fine, no errors so far"
fi