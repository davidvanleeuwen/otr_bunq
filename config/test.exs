import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :otr_bunq, OtrBunqWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "oKdS+oMkm3bsRAxGY5v2+44x1R1CCzicryCZl6YCY/q005J8pc2/1NXpFB16qzmS",
  server: false

config :otr_bunq, OtrBunq.Repo,
  database: Path.expand("../otr_bunq.db", Path.dirname(__ENV__.file)),
  pool_size: 5,
  show_sensitive_data_on_connection_error: true

# In test we don't send emails
config :otr_bunq, OtrBunq.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
