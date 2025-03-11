defmodule Mix.Tasks.Package.Ios.Runtime do
  alias Mix.Tasks.Package.Ios.Nif
  use Mix.Task
  require EEx

  # "https://github.com/elixir-desktop/exqlite",
  # "https://github.com/diodechain/libsecp256k1.git",
  @default_nifs [
    "https://github.com/elixir-desktop/exqlite.git",
    # "https://github.com/adiibanez/rustler_btleplug.git"
    {"https://github.com/adiibanez/rustler_btleplug.git",
     name: "rustler_btleplug", tag: "v0.0.15-alpha"}
    #  "https://github.com/adiibanez/wasmex.git"
    # "https://github.com/tessi/wasmex.git"
    # [repo: "https://github.com/adiibanez/rustler_btleplug", tag: "v0.0.15-alpha"]
  ]

  @diode_nifs [
    "https://github.com/diodechain/esqlite.git",
    "https://github.com/diodechain/libsecp256k1.git"
  ]

  @notsure_modules """
  --disable-distributed
  --disable-hipe
  --disable-compiler
  --without-odbc: As mentioned earlier, excludes ODBC database connectivity.
  --without-mysql: Excludes MySQL database connectivity.
  --without-postgres: Excludes PostgreSQL database connectivity.
  --without-smp: Disables symmetric multiprocessing (SMP) support. This might reduce the size of the Erlang runtime, but it can also limit performance on multi-core devices. Test carefully before disabling SMP.
  --without-threads: Disables Erlang threads. If your application doesn't use Erlang threads, you can disable this.
  --disable-compiler: Disables the Erlang compiler. If your application doesn't need to compile code at runtime, you can disable the compiler.
  --disable-kernel-poll: Disables kernel poll for I/O. Likely not needed on iOS.
  --disable-native-libs: Disables dynamic linking, to only run code as build, but requires special handling and may break lots of code.
  """

  @additional_configuration """
  --disable-debug
  --disable-hipe
  --without-javac
  --without-jinterface
  --without-odbc
  --without-postgres
  --without-mysql
  --without-wx
  --disable-sctp
  --disable-megaco
  --disable-corba
   --disable-kernel-poll
  """

  def architectures() do
    # Not sure if we still need arm-32 at all https://blakespot.com/ios_device_specifications_grid.html
    %{
      # "ios" => %{
      #   arch: "armv7",
      #   id: "ios",
      #   sdk: "iphoneos",
      #   #openssl_arch: "ios-xcrun",
      #   darwin64-arm64
      #   xcomp: "arm-ios",
      #   name: "arm-apple-ios",
      #   cflags: "-mios-version-min=7.0.0 -fno-common -Os -D__IOS__=yes"
      # },
      "ios-arm64" => %{
        arch: "arm64",
        id: "ios64",
        sdk: "iphoneos",
        openssl_arch: "ios64-xcrun",
        # openssl_arch: "darwin64-arm64",
        xcomp: "arm64-ios",
        name: "aarch64-apple-ios",
        cflags: "-mios-version-min=7.0.0 -fno-common -Os -D__IOS__=yes"
      },
      "iossimulator-x86_64" => %{
        arch: "x86_64",
        id: "iossimulator",
        sdk: "iphonesimulator",
        openssl_arch: "iossimulator-x86_64-xcrun",
        # openssl_arch: "darwin64-x86_64",
        xcomp: "x86_64-iossimulator",
        name: "x86_64-apple-iossimulator",
        cflags: "-mios-simulator-version-min=7.0.0 -fno-common -Os -D__IOS__=yes"
      },
      "iossimulator-arm64" => %{
        arch: "arm64",
        id: "iossimulator",
        sdk: "iphonesimulator",
        openssl_arch: "iossimulator-arm64-xcrun",
        # openssl_arch: "darwin64-arm64",
        xcomp: "arm64-iossimulator",
        name: "aarch64-apple-iossimulator",
        cflags: "-mios-simulator-version-min=7.0.0 -fno-common -Os -D__IOS__=yes"
      }
    }
  end

  def get_arch(arch) do
    Map.fetch!(architectures(), arch)
  end

  def run(["with_diode_nifs"]) do
    IO.puts("with_diode_nifs")
    buildall(architectures(), @diode_nifs)
  end

  def run([]) do
    IO.puts("with empty []")
    buildall(architectures(), @default_nifs)
  end

  def run(args) do
    {parsed, _, _} = OptionParser.parse(args, strict: [arch: :string, nifs: :string])
    IO.inspect(parsed, label: "Received args")

    nifs = Keyword.get(parsed, :nifs, @default_nifs)

    build(parsed[:arch], nifs)
    # IO.puts("Validating nifs...")
    # Enum.each(nifs, fn nif -> Runtimes.get_nif(nif) end)
    # buildall(Map.keys(architectures()), nifs)
  end

  def openssl_target(arch) do
    path = Path.absname("_build/openssl_cache/#{arch.name}/openssl")
    IO.puts("OpenSSL target #{path}")
    path
  end

  def openssl_lib(arch) do
    path = Path.join(openssl_target(arch), "lib/libcrypto.a")
    IO.puts("OpenSSL target #{path}")
    path
  end

  def otp_target(arch) do
    path = Path.absname("_build/otp_cache/#{arch.name}/otp")
    IO.puts("OTP target #{path}")
    path
  end

  def runtime_target(arch) do
    path = "_build/runtime_cache/#{arch.name}/liberlang.a"
    IO.puts("Runtime target #{path}")
    path
  end

  def build(archid, extra_nifs) when is_binary(extra_nifs) do
    build(archid, String.split(extra_nifs, ","))
  end

  def build(archid, extra_nifs) when is_list(extra_nifs) do
    IO.inspect(archid, label: "build archid")
    arch = get_arch(archid)
    File.mkdir_p!("_build/runtime_cache/#{arch.name}")

    # Building OpenSSL
    if File.exists?(openssl_lib(arch)) do
      IO.puts("OpenSSL (#{openssl_lib(arch)}) already exists...")
    else
      case Runtimes.run("scripts/install_openssl.sh",
             ARCH: arch.openssl_arch,
             OPENSSL_PREFIX: openssl_target(arch),
             MAKEFLAGS: "-j10 -O"
           ) do
        {:ok} -> IO.puts("OpenSSL ok")
        {:error, error} -> IO.puts("OpenSSL error: #{error}")
        _ -> IO.puts("OpenSSL not sure ...")
      end
    end

    # Building OTP
    if File.exists?(runtime_target(arch)) do
      IO.puts("liberlang.a (#{arch.id}) already exists...")
    else
      if !File.exists?(otp_target(arch)) do
        Runtimes.ensure_otp()
        Runtimes.run(~w(git clone _build/otp_cache/otp #{otp_target(arch)}))
      end

      env = [
        LIBS: openssl_lib(arch),
        INSTALL_PROGRAM: "/usr/bin/install -c",
        MAKEFLAGS: "-j10 -O",
        RELEASE_LIBBEAM: "yes"
      ]

      if System.get_env("SKIP_CLEAN_BUILD") == nil do
        nifs = [
          "#{otp_target(arch)}/lib/asn1/priv/lib/#{arch.name}/asn1rt_nif.a",
          "#{otp_target(arch)}/lib/crypto/priv/lib/#{arch.name}/crypto.a"
        ]

        # First round build to generate headers and libs required to build nifs:
        # git clean -xdf &&

        cmd = ~w(
          cd #{otp_target(arch)} &&
          ./otp_build setup \
          --with-ssl=#{openssl_target(arch)} \
          --disable-dynamic-ssl-lib \
          --xcomp-conf=xcomp/erl-xcomp-#{arch.xcomp}.conf \
          --enable-static-nifs=#{Enum.join(nifs, ",")} #{System.get_env("KERL_CONFIGURE_OPTIONS", "")}
          #{@additional_configuration}
        )

        IO.inspect(cmd, label: "First round build of #{otp_target(arch)}")

        Runtimes.run(
          cmd,
          env
        )

        Runtimes.run(~w(cd #{otp_target(arch)} && ./otp_build boot -a), env)
        Runtimes.run(~w(cd #{otp_target(arch)} && ./otp_build release -a), env)
      end

      # Second round
      # The extra path can only be generated AFTER the nifs are compiled
      # so this requires two rounds...
      extra_nifs =
        Enum.map(extra_nifs, fn nif ->
          if Nif.static_lib_path(arch, Runtimes.get_nif(nif)) == nil do
            Nif.build(archid, nif)
          end

          Nif.static_lib_path(arch, Runtimes.get_nif(nif))
          |> Path.absname()
        end)

      nifs = [
        "#{otp_target(arch)}/lib/asn1/priv/lib/#{arch.name}/asn1rt_nif.a",
        "#{otp_target(arch)}/lib/crypto/priv/lib/#{arch.name}/crypto.a"
        | extra_nifs
      ]

      IO.puts("Extra nifs: #{inspect(nifs)}")

      IO.inspect(System.get_env("KERL_CONFIGURE_OPTIONS", ""),
        label: "Kerl configure options"
      )

      Runtimes.run(
        ~w(
          cd #{otp_target(arch)} && ./otp_build configure
          --with-ssl=#{openssl_target(arch)}
          --disable-dynamic-ssl-lib
          --xcomp-conf=xcomp/erl-xcomp-#{arch.xcomp}.conf
          --enable-static-nifs=#{Enum.join(nifs, ",")}
          #{System.get_env("KERL_CONFIGURE_OPTIONS", "")}
          #{@additional_configuration}
        ),
        env
      )

      Runtimes.run(~w(cd #{otp_target(arch)} && ./otp_build boot -a), env)
      Runtimes.run(~w(cd #{otp_target(arch)} && ./otp_build release -a), env)

      {build_host, 0} = System.cmd("#{otp_target(arch)}/erts/autoconf/config.guess", [])
      build_host = String.trim(build_host)

      # [erts_version] = Regex.run(~r/erts-[^ ]+/, File.read!("otp/otp_versions.table"))
      # Locating all built .a files for the target architecture:
      files =
        :filelib.fold_files(
          String.to_charlist(otp_target(arch)),
          ~c".+\\.a$",
          true,
          fn name, acc ->
            name = List.to_string(name)

            if String.contains?(name, arch.name) and
                 not (String.contains?(name, build_host) or
                        String.ends_with?(name, "_st.a") or String.ends_with?(name, "_r.a")) do
              Map.put(acc, Path.basename(name), name)
            else
              acc
            end
          end,
          %{}
        )
        |> Map.values()

      files = files ++ [openssl_lib(arch) | nifs]

      # Creating a new archive
      repackage_archive(files, runtime_target(arch))
    end
  end

  def filter_lib_files(path, arch_name, build_host) do
    files =
      :filelib.fold_files(
        String.to_charlist(path),
        ~c".+\\.a$",
        true,
        fn name, acc ->
          name = List.to_string(name)

          if String.contains?(name, arch_name) and
               not (String.contains?(name, build_host) or
                      String.ends_with?(name, "_st.a") or String.ends_with?(name, "_r.a")) do
            Map.put(acc, Path.basename(name), name)
          else
            acc
          end
        end,
        %{}
      )
      |> Map.values()

    # |> dbg()

    output = Enum.join(files, " ")
    File.write!("/tmp/libs.txt", output)
  end

  #  Method takes multiple ".a" archive files and extracts their ".o" contents
  # to then reassemble all of them into a single `target` ".a" archive
  defp repackage_archive(files, target) do
    # Removing relative prefix so changing cwd is safe.
    files = Enum.join(files, " ")
    Runtimes.run("libtool -static -o #{target} #{files}")
  end

  defp buildall(targets, nifs) do
    Runtimes.ensure_otp()

    # targets
    # |> Enum.map(fn target -> Task.async(fn -> build(target, nifs) end) end)
    # |> Enum.map(fn task -> Task.await(task, 60_000*60*3) end)
    if System.get_env("PARALLEL", "") != "" do
      for target <- targets do
        {spawn_monitor(fn -> build(target, nifs) end), target}
      end
      |> Enum.each(fn {{pid, ref}, target} ->
        receive do
          {:DOWN, ^ref, :process, ^pid, :normal} ->
            :ok

          {:DOWN, ^ref, :process, ^pid, reason} ->
            IO.puts("Build failed for #{target}: #{inspect(reason)}")
            raise reason
        end
      end)
    else
      for {id, _target} <- targets do
        IO.inspect(id, label: "Buildall loop")

        build(id, nifs)
      end
    end

    {sims, reals} =
      Enum.map(targets, fn target -> runtime_target(get_arch(target)) end)
      |> Enum.split_with(fn lib -> String.contains?(lib, "simulator") end)

    libs =
      (lipo(sims) ++ lipo(reals))
      |> Enum.map(fn lib -> "-library #{lib}" end)

    IO.inspect(libs, label: "LIBS inspection")

    framework = "./_build/liberlang.xcframework"

    if File.exists?(framework) do
      File.rm_rf!(framework)
    end

    Runtimes.run(
      "xcodebuild -create-xcframework -output #{framework} " <>
        Enum.join(libs, " ")
    )
  end

  # lipo joins different cpu build of the same target together
  defp lipo([]), do: []
  defp lipo([one]), do: [one]

  defp lipo(more) do
    File.mkdir_p!("tmp")
    x = System.unique_integer([:positive])
    tmp = "tmp/#{x}-liberlang.a"
    if File.exists?(tmp), do: File.rm!(tmp)
    Runtimes.run("lipo -create #{Enum.join(more, " ")} -output #{tmp}")
    [tmp]
  end
end
