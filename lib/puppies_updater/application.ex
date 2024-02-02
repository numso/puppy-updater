defmodule PuppiesUpdater.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PuppiesUpdaterWeb.Telemetry,
      PuppiesUpdater.Repo,
      {Oban, Application.fetch_env!(:puppies_updater, Oban)},
      {DNSCluster, query: Application.get_env(:puppies_updater, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PuppiesUpdater.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: PuppiesUpdater.Finch},
      # Start a worker by calling: PuppiesUpdater.Worker.start_link(arg)
      # {PuppiesUpdater.Worker, arg},
      # Start to serve requests, typically the last entry
      PuppiesUpdaterWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PuppiesUpdater.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PuppiesUpdaterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
