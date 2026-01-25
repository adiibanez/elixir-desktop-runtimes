# Troubleshooting Guide

Common issues and solutions for the elixir-desktop-runtimes build system.

## iOS/macOS Builds

### "yielding_c_fun: Permission denied"

**Symptom**: OTP Round 2 build fails with permission errors.

**Cause**: GitHub artifacts don't preserve Unix execute permissions.

**Solution**: The workflow should restore permissions after downloading artifacts:
```bash
find _build/otp_builder -name "yielding_c_fun" -type f -exec chmod +x {} \;
find _build/otp_builder -path "*/bin/*" -type f -exec chmod +x {} \;
```

If this still fails, check that R1 artifacts were uploaded correctly.

---

### "fdopen macro conflict" / zlib errors

**Symptom**: OTP build fails with errors about `fdopen` being undefined or conflicting.

**Cause**: Xcode 16+ SDKs have a conflicting macro in zlib headers.

**Solution**: The workflow patches `zutil.h` automatically:
```bash
sed -i '' 's|#.*define fdopen(fd,mode) NULL.*|/* fdopen macro removed */|' \
  _build/otp_builder/erts/emulator/zlib/zutil.h
```

If building locally, apply this patch manually before `otp_build configure`.

---

### "OpenSSL not found at $OPENSSL_PREFIX"

**Symptom**: OTP configure fails because it can't find OpenSSL.

**Cause**: OpenSSL artifact wasn't downloaded or path is wrong.

**Solution**:
1. Check that `build_openssl` job succeeded
2. Verify the artifact was uploaded with the correct `base_arch`
3. Check `OPENSSL_PREFIX` environment variable points to correct path

---

### XCFramework missing slices

**Symptom**: `xcodebuild -create-xcframework` fails or produces incomplete framework.

**Cause**: Some platform builds failed or artifacts weren't uploaded.

**Solution**:
1. Check all `build_otp_round2` jobs completed successfully
2. Look for `liberlang-OTP-*-{platform}` artifacts
3. The `combine_xcframework` job skips missing slices with warnings

---

### NIF excluded from build

**Symptom**: A NIF isn't being built for certain platforms.

**Cause**: NIFs with `skip_3rd_tier: true` are excluded from experimental Rust targets.

**Solution**: This is intentional. Check `apple-platforms.json` for `rust_is_3rd_tier: true` platforms. These require `-Zbuild-std` which some NIFs don't support.

---

## Android Builds

### "docker pull failed" / Rate limiting

**Symptom**: Workflow fails pulling dockcross images with 429 errors.

**Cause**: Docker Hub rate limits for unauthenticated pulls.

**Solution**: The workflow has retry logic with 60s delays. If still failing:
1. Check if Docker Hub is having issues
2. Consider caching the base image in GHCR
3. Add Docker Hub authentication

---

### "Could not pull BEAM image"

**Symptom**: NIF build can't find the BEAM Docker image.

**Cause**: OTP build didn't complete or image wasn't pushed to GHCR.

**Solution**:
1. Check `build-otp` job succeeded for the required architecture
2. Verify image exists: `docker pull ghcr.io/{owner}/android_beam:arch_{id}-{version}`
3. Check GHCR permissions allow pulling

---

### "mix package.android.nif failed"

**Symptom**: NIF build errors or produces empty artifacts.

**Cause**: Various - Rust compilation errors, missing dependencies, Docker issues.

**Solution**:
1. Check the Docker build logs for Rust errors
2. Verify the NIF repo and ref are correct in `nif-packages.json`
3. Try building the NIF locally in Docker to reproduce

---

## Configuration Issues

### "nif-packages.json out of sync"

**Symptom**: CI check fails saying configs are out of sync.

**Cause**: `lib/runtimes.ex` was modified but JSON wasn't regenerated.

**Solution**:
```bash
mix run -e "Runtimes.write_nif_packages_json()"
git add .github/config/nif-packages.json
git commit -m "Sync NIF config"
```

---

### Cache miss causing full rebuild

**Symptom**: Build takes much longer than expected.

**Cause**: Cache key changed (version bump, config change, patch modification).

**Solution**: This is expected behavior. Cache keys include:
- OTP version and git ref
- Platform identifier
- `erl-opts-description` (compile options)
- Hash of patch files

Check which component changed to understand the cache miss.

---

## Debugging Tips

### View build logs

Detailed logs are written to `runtimes_run.log` during Mix tasks. In CI:
```yaml
- name: Upload debug logs
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: debug-logs
    path: "**/*.log"
```

### Check library architecture

```bash
# macOS/iOS
lipo -info liberlang.a
file liberlang.a

# Verify symbols
nm liberlang.a | grep beam_emu
```

### Inspect Docker image

```bash
# List what's in the BEAM image
docker run --rm ghcr.io/{owner}/android_beam:arch_arm64-aarch64-arm64-v8a-27.3.4.2 \
  find /otp -name "*.a"
```

### Test OTP configure locally

```bash
cd _build/otp_builder

# Dry run configure to see what would happen
./otp_build configure --help

# Check config.log for errors
cat config.log | grep -i error
```

## Getting Help

1. Check the [Architecture docs](ARCHITECTURE.md) for build flow understanding
2. Look at recent CI runs for similar issues
3. Search closed issues/PRs for solutions
4. File a new issue with:
   - Full error message
   - Platform/architecture
   - OTP version
   - Link to failed CI run
