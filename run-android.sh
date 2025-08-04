export OTP_SOURCE=https://github.com/adiibanez/otp
export OTP_VERSION=OTP-27.3-noiosminversion
export OTP_TAG=OTP-27.3-noiosminversion

mix run -e "Mix.Tasks.Package.Android.Runtime.write_beam_dockerfile(\"arm\", \"`pwd`/Dockerfile_android-beam-arm\")"

ls -lah Dockerfile_android-beam-arm
cat Dockerfile_android-beam-arm

#exit 0

export OPENSSL_HASH=002a2d6b30b58bf4bea46c43bdd96365aaf8daa6c428782aa4feee06da197df3
export OPENSSL_VERSION=3.4.1
export ARCH=arm64

# --platform=linux/amd64 \
docker buildx build -t android_beam --platform linux/$ARCH \
--build-arg BASE_IMAGE=dockcross/android-$ARCH \
--build-arg ARCH=$ARCH \
--build-arg ANDROID_NAME=android \
--build-arg ABI=23 \
--build-arg OTP_SOURCE=$OTP_SOURCE \
--build-arg OTP_TAG=$OTP_TAG \
--build-arg OPENSSL_VERSION=$OPENSSL_VERSION \
--build-arg OPENSSL_HASH=$OPENSSL_HASH \
--build-arg KERL_CONFIGURE_OPTIONS= \
--build-arg OTP_PATH=_build/otp_cache/otp \
--output type=docker \
  -f Dockerfile_android-beam-arm .
#docker run -t android_beam env
#docker run -t android_beam cat /root/.profile
docker run --platform linux/$ARCH -t android_beam erl -version
#docker run --platform linux/arm64 -t android_beam erl -version

#mix run -e "Mix.Tasks.Package.Android.Runtime.write_nif_dockerfile(\"arm\", \"`pwd`/Dockerfile_android-beam-arm\")"