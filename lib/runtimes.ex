defmodule Runtimes do
  require EEx

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
