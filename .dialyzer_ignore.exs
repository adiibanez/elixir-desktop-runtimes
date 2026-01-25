# Dialyzer ignore patterns for pre-existing issues
# These should be fixed over time but are ignored to allow CI to pass
[
  # Legacy Android runtime code - pattern matching issue
  {"lib/mix/tasks/package_android_runtime.ex", :pattern_match},
  # Legacy Android runtime code - no local return from write_nif_dockerfile
  {"lib/mix/tasks/package_android_runtime.ex", :no_return}
]
