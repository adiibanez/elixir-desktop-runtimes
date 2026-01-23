mkdir temp_objects
cd temp_objects

# Extract all object files from the stripped library
ar x ../liberlang_stripped.a

# Recreate the archive from the extracted (and now smaller) object files
ar -rcs ../liberlang_repacked.a *.o

# Clean up the temporary directory
cd ..
rm -rf temp_objects

# Compare the sizes:
ls -lh liberlang.a liberlang_stripped.a liberlang_repacked.a




exit 0

'''
lto=b
-rw-r--r--  1 runner  staff    86M Mar 20 16:46 /Users/runner/work/elixir-desktop-runtimes/elixir-desktop-runtimes/_build/nifs/libwasmex.a
-rw-r--r--  1 runner  staff   2.0M Mar 20 16:46 /Users/runner/work/elixir-desktop-runtimes/elixir-desktop-runtimes/_build/nifs/sqlite3_nif.a
-rw-r--r--  1 runner  staff    20M Mar 20 16:46 /Users/runner/work/elixir-desktop-runtimes/elixir-desktop-runtimes/_build/nifs/libbtleplug_client.a
'''


RUSTFLAGS="-C debug=false -C debug-assertions=false -C incremental=false"
rustc - -C lto=off -C embed-bitcode=no -C opt-level=z -C codegen-units=1 -C strip=symbols -C link-arg=-Wl,-dead_strip -C link-arg=-Wl,--gc-sections --target aarch64-apple-darwin --crate-type bin --crate-type rlib --crate-type dylib --crate-type cdylib --crate-type staticlib --crate-type proc-macro --print=sysroot --print=split-debuginfo --print=crate-name --print=cfg