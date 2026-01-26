# visionOS Support Status

This document describes the current state of visionOS support in the elixir-desktop-runtimes build pipeline.

## Overview

visionOS (Apple Vision Pro) support was added to the build matrix in January 2026. Due to the platform's novelty, some components require special handling.

## Build Matrix

| Component | visionOS Device | visionOS Simulator |
|-----------|-----------------|-------------------|
| OpenSSL | ✅ Supported | ✅ Supported |
| OTP/BEAM | ✅ Supported | ✅ Supported |
| btleplug_client NIF | ✅ Supported | ✅ Supported |
| iroh_ex NIF | ❌ Not supported | ❌ Not supported |
| wasmex NIF | ❌ Not supported | ❌ Not supported |

## Technical Details

### Platform Configuration

visionOS platforms are defined in `.github/config/apple-platforms.json`:

```json
{
  "id": "visionos",
  "name": "visionOS",
  "sdk": "xros",
  "arch": "arm64",
  "base_arch": "xros",
  "otp_arch": "aarch64-apple-ios",
  "rust_target": "aarch64-apple-visionos",
  "rust_is_3rd_tier": true
}
```

### Key Configurations

1. **OpenSSL**: Uses `xros-xcrun` architecture defined in `patch/openssl-ios.conf`

2. **OTP**: Uses iOS target (`aarch64-apple-ios`) because OTP's autoconf `config.sub` doesn't recognize `xros` as a valid OS. The actual compilation targets visionOS via SDK flags (`xcrun -sdk xros`).

3. **Rust**: visionOS is a Tier 3 target, requiring:
   - Nightly toolchain
   - `rust-src` component
   - `-Zbuild-std` flag to compile the standard library from source

## Unsupported NIFs

### iroh_ex

**Status**: Skipped for visionOS builds

**Root Cause**: The `netwatch` crate (dependency of iroh) doesn't support visionOS.

**Error**:
```
error[E0432]: unresolved import `os`
 --> netwatch-0.12.0/src/netmon/actor.rs:3:16
  |
3 | pub(super) use os::Error;
  |                ^^ help: a similar path exists: `std::os`
```

**Required Changes to Enable**:

1. **Fork netwatch** (https://github.com/n0-computer/netwatch)

2. **Add visionOS platform support** in `src/netmon/mod.rs`:
   ```rust
   // Change from:
   #[cfg(target_os = "ios")]
   mod darwin;

   // To:
   #[cfg(any(target_os = "ios", target_os = "visionos"))]
   mod darwin;
   ```

3. **Update platform detection** - visionOS shares most networking APIs with iOS, so the Darwin implementation should work with minimal changes.

4. **Patch iroh_ex's Cargo.toml**:
   ```toml
   [patch.crates-io]
   netwatch = { git = "https://github.com/your-fork/netwatch", branch = "visionos-support" }
   ```

5. **Test on visionOS Simulator** before submitting upstream PR.

**Upstream Tracking**: Consider opening an issue at https://github.com/n0-computer/netwatch/issues

### wasmex

**Status**: Skipped for all Tier 3 platforms

**Root Cause**: wasmex/wasmer doesn't provide pre-built standard library for Tier 3 targets, and building from source has additional complexity.

**Required Changes to Enable**:

1. Investigate wasmer's visionOS support status
2. May require building wasmer with custom configuration
3. Lower priority than iroh_ex due to complexity

## Flavor Availability

Due to NIF limitations, visionOS builds only support:

| Flavor | Available |
|--------|-----------|
| vanilla | ✅ Yes (btleplug_client only) |
| iroh | ❌ No (requires iroh_ex) |
| full | ❌ No (requires iroh_ex + wasmex) |

## Future Work

1. **Short-term**: Monitor netwatch for upstream visionOS support
2. **Medium-term**: Fork and patch netwatch if no upstream progress
3. **Long-term**: Contribute visionOS support back to upstream projects

## References

- [Apple visionOS SDK Documentation](https://developer.apple.com/visionos/)
- [Rust Platform Support](https://doc.rust-lang.org/nightly/rustc/platform-support.html)
- [netwatch repository](https://github.com/n0-computer/netwatch)
- [iroh repository](https://github.com/n0-computer/iroh)
