defmodule EQRCode.MixProject do
  use Mix.Project

  @source_url "https://github.com/SiliconJungles/eqrcode"
  @version "0.2.0"

  def project do
    [
      app: :eqrcode,
      version: @version,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      name: "EQRCode",
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package() do
    [
      description: "Simple QRCode Generator in Elixir",
      licenses: ["MIT"],
      maintainers: ["siliconavengers", "nthock"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      assets: "assets",
      formatters: ["html"]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.25.2", only: :dev, runtime: false}
    ]
  end
end
