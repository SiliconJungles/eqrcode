defmodule EQRCode.MixProject do
  use Mix.Project

  @source_url "https://github.com/SiliconJungles/eqrcode"
  @version "0.1.8"

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
      maintainers: ["siliconavengers"],
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
      assets: "assets",
      formatters: ["html"]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
