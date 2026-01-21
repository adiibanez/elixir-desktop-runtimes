defmodule Mix.Tasks.Package.Android.Nif do
  use Mix.Task
  alias Mix.Tasks.Package.Android.Runtime
  require EEx

  # NIF definitions are centralized in Runtimes module
  # Use RUNTIME_FLAVOR env var to select: vanilla, crypto, iroh, ble, full

  def run([]) do
    flavor = Runtimes.current_flavor()
    IO.puts("Building Android NIFs with flavor: #{flavor}")

    for nif <- Runtimes.default_nifs() do
      for arch <- Runtime.default_archs() do
        build(arch, Runtimes.get_nif(nif))
      end
    end
  end

  def run(args) do
    {parsed, _, _} = OptionParser.parse(args, strict: [arch: :string, flavor: :string])
    IO.inspect(parsed, label: "Received args")

    arch = Keyword.get(parsed, :arch, "arm64")

    nifs =
      case Keyword.get(parsed, :flavor) do
        nil ->
          Runtimes.default_nifs()

        flavor ->
          IO.puts("Using flavor: #{flavor}")
          Runtimes.flavor_nifs(flavor)
          |> Enum.map(fn name ->
            case Runtimes.get_nif_config(name) do
              nil -> name
              %{type: :c_nif, repo: repo} -> repo
              %{type: :rustler, repo: repo, ref: ref, lib_name: lib_name} ->
                {repo, name: lib_name, tag: ref}
            end
          end)
      end

    for nif <- nifs do
      build(arch, Runtimes.get_nif(nif))
    end
  end

  defp build(arch, nif) do
    type = Runtime.get_arch(arch).android_type
    target = "_build/#{type}-nif-#{nif.name}.zip"

    if exists?(target) do
      :ok
    else
      image_name = "#{nif.name}-#{arch}"

      Runtimes.docker_build(
        image_name,
        Runtime.generate_nif_dockerfile(arch, nif)
      )

      Runtimes.run(~w(docker run --rm
    -w /work/#{nif.basename}/ --entrypoint ./package_nif.sh #{image_name}
    #{nif.name} > #{target}))
    end
  end

  def exists?(file) do
    case File.stat(file) do
      {:error, _} -> false
      {:ok, %File.Stat{size: 0}} -> false
      _ -> true
    end
  end
end
