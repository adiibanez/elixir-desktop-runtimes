# act --list
#   --watch \
act -P macos-latest=-self-hosted \
  --cache-server-path .actcache \
  --container-architecture linux/amd64 \
  --artifact-server-path /tmp/artifacts  