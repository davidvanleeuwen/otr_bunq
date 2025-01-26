defmodule OtrBunq.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    OtrBunq.Release.migrate()

    :ets.new(:session_table, [:named_table, :set, :public])

    children = [
      OtrBunqWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:otr_bunq, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: OtrBunq.PubSub},
      OtrBunq.Repo,
      # Start the Finch HTTP client for sending emails
      {Finch, name: OtrBunq.Finch},
      OtrBunq.GenBalance,
      # Start a worker by calling: OtrBunq.Worker.start_link(arg)
      # {OtrBunq.Worker, arg},
      # Start to serve requests, typically the last entry
      OtrBunqWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OtrBunq.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OtrBunqWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
