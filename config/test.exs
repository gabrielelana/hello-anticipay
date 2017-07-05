use Mix.Config

# Disable projections when running tests
config :anticipay, enable_projections: false

# Enable only error logs when running tests
config :logger, :console,
  level: :warn,
  format: "$date $time [$level] $levelpad$message\n",
  colors: [info: :green]
