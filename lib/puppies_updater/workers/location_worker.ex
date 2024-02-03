defmodule PuppiesUpdater.Workers.LocationWorker do
  alias PuppiesUpdater.PuppiesCom
  alias PuppiesUpdater.Locations
  use Oban.Worker

  @impl true
  def perform(job) do
    %{"index" => i, "location" => location} = job.args

    next_job_params(i)
    |> new(schedule_in: {location["num_hours"], :hours})
    |> Oban.insert()

    {:ok, token} = PuppiesCom.get_token()

    {:ok, _} =
      PuppiesCom.update_user(token, %{
        formatted_location: location["name"],
        lat: location["latitude"],
        lng: location["longitude"]
      })

    Oban.Notifier.notify(Oban, :location_jobs, %{complete: job.id})
    :ok
  end

  defp next_job_params(i) do
    locations = Locations.locations()
    i = if i == length(locations) - 1, do: 0, else: i + 1
    %{location: locations |> Enum.at(i), index: i}
  end
end
