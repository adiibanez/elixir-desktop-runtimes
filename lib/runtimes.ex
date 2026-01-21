defmodule Runtimes do
  require EEx

  # =============================================================================
  # NIF Registry - Single source of truth for all NIF packages
  # =============================================================================
  # Each NIF has: repo, ref/tag, native_dir (for Rust), ldflags (for linking),
  # skip_3rd_tier (for experimental Rust targets), type (:rustler or :c_nif)

  @nif_registry %{
    # SQLite NIFs
    "exqlite" => %{
      repo: "https://github.com/elixir-desktop/exqlite.git",
      ref: "main",
      type: :c_nif,
      native_dir: nil,
      ldflags: "",
      skip_3rd_tier: false
    },
    "esqlite" => %{
      repo: "https://github.com/diodechain/esqlite.git",
      ref: "master",
      type: :c_nif,
      native_dir: nil,
      ldflags: "",
      skip_3rd_tier: false
    },

    # Crypto NIFs
    "libsecp256k1" => %{
      repo: "https://github.com/diodechain/libsecp256k1.git",
      ref: "master",
      type: :c_nif,
      native_dir: nil,
      ldflags: "",
      skip_3rd_tier: false
    },

    # Rustler NIFs
    "btleplug_client" => %{
      repo: "https://github.com/adiibanez/rustler_btleplug.git",
      ref: "static-no-precompiled",
      lib_name: "rustler_btleplug",
      type: :rustler,
      native_dir: "native/btleplug_client",
      ldflags: "-framework CoreBluetooth -framework CoreFoundation -framework Foundation -ObjC",
      skip_3rd_tier: false
    },
    "iroh_ex" => %{
      repo: "https://github.com/adiibanez/iroh_ex.git",
      ref: "iroh-0.90",
      lib_name: "iroh_ex",
      type: :rustler,
      native_dir: "native/iroh_ex",
      ldflags: "-framework Security -framework SystemConfiguration -framework CoreFoundation -framework Foundation",
      skip_3rd_tier: false
    },
    "wasmex" => %{
      repo: "https://github.com/adiibanez/wasmex.git",
      ref: "static-no-precompiled",
      lib_name: "wasmex",
      type: :rustler,
      native_dir: "native/wasmex",
      ldflags: "",
      skip_3rd_tier: true  # wasmex uses unstable Rust features
    }
  }

  # =============================================================================
  # Package Flavors - Curated NIF combinations for different use cases
  # =============================================================================
  # Set RUNTIME_FLAVOR env var to select: vanilla, crypto, iroh, full

  @flavors %{
    # Minimal: just SQLite for basic storage
    "vanilla" => ["exqlite"],

    # Crypto: Diode chain compatible (different SQLite + secp256k1)
    "crypto" => ["esqlite", "libsecp256k1"],

    # Iroh: SQLite + P2P networking
    "iroh" => ["exqlite", "iroh_ex"],

    # BLE: SQLite + Bluetooth
    "ble" => ["exqlite", "btleplug_client"],

    # Full: All available NIFs
    "full" => ["exqlite", "btleplug_client", "iroh_ex", "wasmex"]
  }

  # =============================================================================
  # Public API
  # =============================================================================

  @doc "Get NIF registry entry by name"
  def get_nif_config(name) when is_binary(name) do
    Map.get(@nif_registry, name)
  end

  @doc "Get all registered NIFs"
  def all_nifs, do: @nif_registry

  @doc "Get all Rustler NIFs (for CI builds)"
  def rustler_nifs do
    @nif_registry
    |> Enum.filter(fn {_name, config} -> config.type == :rustler end)
    |> Map.new()
  end

  @doc "Get available flavor names"
  def available_flavors, do: Map.keys(@flavors)

  @doc "Get NIF names for a specific flavor"
  def flavor_nifs(flavor) when is_binary(flavor) do
    Map.get(@flavors, flavor, @flavors["vanilla"])
  end

  @doc "Get current flavor from RUNTIME_FLAVOR env var"
  def current_flavor do
    System.get_env("RUNTIME_FLAVOR", "vanilla")
  end

  @doc "Get NIF list for current flavor (legacy format for backwards compat)"
  def default_nifs do
    current_flavor()
    |> flavor_nifs()
    |> Enum.map(&nif_to_legacy_format/1)
  end

  @doc "Get NIF configs for current flavor"
  def default_nif_configs do
    current_flavor()
    |> flavor_nifs()
    |> Enum.map(fn name -> {name, get_nif_config(name)} end)
  end

  # Convert NIF name to legacy tuple/string format used by iOS task
  defp nif_to_legacy_format(name) do
    case get_nif_config(name) do
      nil ->
        raise "Unknown NIF: #{name}"

      %{type: :c_nif, repo: repo} ->
        repo

      %{type: :rustler, repo: repo, ref: ref, lib_name: lib_name} ->
        {repo, name: lib_name, tag: ref}
    end
  end

  @doc """
  Export Rustler NIFs as JSON for CI (nif-packages.json format).
  Usage: mix run -e "IO.puts Runtimes.export_nifs_json()"
  """
  def export_nifs_json do
    nifs =
      rustler_nifs()
      |> Enum.sort_by(fn {name, _} -> name end)
      |> Enum.map(fn {name, config} ->
        lib_name = Map.get(config, :lib_name, name)
        skip = config.skip_3rd_tier

        "    {\n" <>
          "      \"name\": \"#{name}\",\n" <>
          "      \"lib_name\": \"#{lib_name}\",\n" <>
          "      \"repo\": \"#{config.repo}\",\n" <>
          "      \"ref\": \"#{config.ref}\",\n" <>
          "      \"native_dir\": \"#{config.native_dir}\",\n" <>
          "      \"ldflags\": \"#{config.ldflags}\",\n" <>
          "      \"skip_3rd_tier\": #{skip}\n" <>
          "    }"
      end)
      |> Enum.join(",\n")

    "{\n  \"nifs\": [\n#{nifs}\n  ]\n}\n"
  end

  @doc """
  Write nif-packages.json to .github/config/
  Usage: mix run -e "Runtimes.write_nif_packages_json()"
  """
  def write_nif_packages_json do
    path = ".github/config/nif-packages.json"
    File.write!(path, export_nifs_json())
    IO.puts("Written to #{path}")
  end

  def run(args, env \\ []) do
    args = if is_list(args), do: Enum.join(args, " "), else: args

    env =
      Enum.map(env, fn {key, value} ->
        case key do
          atom when is_atom(atom) -> {Atom.to_string(atom), value}
          _other -> {key, value}
        end
      end)

    # {:delayed_write, 100, 20}
    {:ok, file} = File.open("runtimes_run.log", [:append])
    IO.write(file, inspect(args))
    IO.write(file, "\n")
    File.close(file)
    IO.puts("RUN: #{args}")

    case System.cmd("bash", ["-c", args],
           stderr_to_stdout: true,
           into: IO.binstream(:stdio, :line),
           env: env
         ) do
      {ret, 0} ->
        IO.puts("RUN OK: #{args} #{inspect(ret)}")
        ret

      error ->
        IO.puts("RUN NOK: #{inspect(error)}")
    end
  end

  def docker_build(image, file) do
    IO.puts("RUN: docker build -t #{image} -f #{file} .")

    ret =
      System.cmd("docker", ~w(build -t #{image} -f #{file} .),
        stderr_to_stdout: true,
        into: IO.binstream(:stdio, :line)
      )

    File.rm(file)
    {_, 0} = ret
  end

  def get_nif(url) when is_binary(url) do
    get_nif({url, []})
  end

  def get_nif({url, opts} = term) when is_tuple(term) do
    name = Keyword.get(opts, :name, Path.basename(url, ".git"))
    tag = Keyword.get(opts, :tag, nil)

    %{
      tag: tag,
      repo: url,
      name: name,
      basename: Path.basename(url, ".git")
    }
  end

  def otp_source() do
    System.get_env("OTP_SOURCE", "https://github.com/erlang/otp")
  end

  def otp_tag() do
    System.get_env("OTP_TAG", "OTP-26.2.5.6")
  end

  def ensure_otp() do
    Runtimes.run("pwd")
    Runtimes.run("ls -lah ./")

    if !File.exists?("_build/otp_cache/otp") do
      File.mkdir_p!("_build")

      IO.puts(
        "git clone --depth 1 #{Runtimes.otp_source()} _build/otp_cache/otp --branch #{Runtimes.otp_tag()}"
      )

      # Runtimes.run(
      #   "git clone #{Runtimes.otp_source()} _build/otp_cache/otp && cd _build/otp_cache/otp && git checkout #{Runtimes.otp_tag()}"
      # )
      Runtimes.run(
        "git clone --depth 1 #{Runtimes.otp_source()} _build/otp_cache/otp --branch #{Runtimes.otp_tag()}"
      )
    end
  end

  def erts_version() do
    ensure_otp()
    content = File.read!("_build/otp_cache/otp/erts/vsn.mk")
    [[_, vsn]] = Regex.scan(~r/VSN *= *([0-9\.]+)/, content)
    vsn
  end
end
