defmodule PuppiesUpdater.Repo do
  use Ecto.Repo,
    otp_app: :puppies_updater,
    adapter: Ecto.Adapters.Postgres
end
