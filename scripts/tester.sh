#LIB_ARM=/Users/adrianibanez/Documents/projects/2024_sensor-platform/checkouts/elixir-desktop-ios-example-app/liberlang.xcframework/ios-arm64/liberlang.a
#LIB_X86=/Users/adrianibanez/Documents/projects/2024_sensor-platform/checkouts/elixir-desktop-ios-example-app/liberlang.xcframework/ios-x86_64-simulator/liberlang.a

if [[ ! -z $LIB_ARM ]]; then
xcrun --sdk iphoneos clang -o test_erl_start test_erl_start.c \
    -arch arm64 \
    -isysroot $(xcrun --sdk iphone --show-sdk-path) \
    -Wl,-force_load,$LIB_ARM
fi 

if [[ ! -z $LIB_X86 ]]; then
xcrun --sdk iphonesimulator clang -o test_erl_start_sim test_erl_start.c \
    -arch x86_64 \
    -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path) \
    -Wl,-force_load,$LIB_X86
fi