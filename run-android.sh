iex -S mix run -e 'Mix.Tasks.Package.Android.Runtime.write_beam_dockerfile("arm", "/tmp/Dockerfile_android-beam-arm")'

export OPENSSL_HASH=002a2d6b30b58bf4bea46c43bdd96365aaf8daa6c428782aa4feee06da197df3
export OPENSSL_VERSION=3.4.1 
export ARCH=arm
# --platform=linux/amd64 \
docker buildx build -t android_beam \
--build-arg BASE_IMAGE=dockcross/android-$ARCH \
--build-arg ARCH=$ARCH \
--build-arg ANDROID_NAME=android \
--build-arg ABI=23 \
--build-arg OPENSSL_VERSION=$OPENSSL_VERSION \
--build-arg OPENSSL_HASH=$OPENSSL_HASH \
--build-arg KERL_CONFIGURE_OPTIONS= \
--build-arg OTP_PATH=_build/otp_cache/otp \
--output type=docker \
  -f /tmp/Dockerfile_android-beam-arm .

docker run -t android_beam env
docker run -t android_beam cat /root/.profile