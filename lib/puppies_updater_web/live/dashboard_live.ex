defmodule PuppiesUpdaterWeb.DashboardLive do
  alias PuppiesUpdater.Repo
  alias PuppiesUpdater.Locations.Location
  alias PuppiesUpdater.PuppiesCom
  alias PuppiesUpdater.Workers.LocationWorker
  alias PuppiesUpdater.Locations
  use PuppiesUpdaterWeb, :live_view
  import Ecto.Query

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-10 flex justify-around flex-wrap gap-10">
      <div>
        <h2 class="font-semibold text-center mb-2">Current Location</h2>
        <%= if @current do %>
          <div class="border p-4">
            <p class="text-sm font-semibold leading-6 text-gray-900"><%= @current.name %></p>
            <p class="mt-1 truncate text-xs leading-5 text-gray-500">
              (<%= @current.latitude %>, <%= @current.longitude %>)
            </p>
          </div>
        <% else %>
          <div>Failed to fetch data from puppies.com</div>
        <% end %>
      </div>
      <div>
        <h2 class="font-semibold text-center mb-2">Next Location</h2>

        <ul role="list" class="divide-y divide-gray-100 overflow-auto max-h-[50vh] border p-4 mb-4">
          <li :for={job <- @jobs} class="flex justify-between gap-x-6 py-5 group">
            <div class="flex flex-col min-w-0 gap-x-4">
              <p class="text-sm font-semibold leading-6 text-gray-900"><%= job.location["name"] %></p>
              <p class="mt-1 truncate text-xs leading-5 text-gray-500">
                (<%= job.location["latitude"] %>, <%= job.location["longitude"] %>)
              </p>
              <p class="mt-1 truncate text-xs leading-5 text-gray-500">
                Runs for <%= job.location["num_hours"] %> hours
              </p>
              <p
                class="mt-4 truncate text-xs leading-5 text-gray-500 font-bold"
                phx-hook="time"
                id={"job-#{job.id}"}
                data-date={job.when}
              >
                <span class="block">Will update on:</span>
                <time id={"job-#{job.id}-inner"} phx-update="ignore"></time>
              </p>
            </div>
          </li>
        </ul>

        <.button phx-click="stop">Stop All Jobs</.button>
      </div>
      <div>
        <h2 class="font-semibold text-center mb-2">Location List</h2>
        <ul role="list" class="divide-y divide-gray-100 overflow-auto max-h-[50vh] border p-4">
          <li
            :for={{location, i} <- Enum.with_index(@locations)}
            class="flex justify-between gap-x-6 py-5 group"
          >
            <div class="flex min-w-0 gap-x-4 items-center">
              <div class="min-w-0 flex-auto">
                <p class="text-sm font-semibold leading-6 text-gray-900"><%= location.name %></p>
                <p class="mt-1 truncate text-xs leading-5 text-gray-500">
                  (<%= location.latitude %>, <%= location.longitude %>)
                </p>
                <p class="mt-1 truncate text-xs leading-5 text-gray-500">
                  Runs for <%= location.num_hours %> hours
                </p>
              </div>
              <div class="invisible shrink-0 group-hover:visible">
                <.button phx-click="update" phx-value-index={i}>Update now</.button>
              </div>
            </div>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_, _, socket) do
    if connected?(socket) do
      :ok = Oban.Notifier.listen([:location_jobs])
    end

    {:ok,
     socket
     |> assign(locations: Locations.locations())
     |> assign(jobs: get_jobs())
     |> assign(current: get_current())}
  end

  defp get_current() do
    with {:ok, token} <- PuppiesCom.get_token(),
         {:ok, user} <- PuppiesCom.get_user(token) do
      %Location{name: user["formatted_location"], latitude: user["lat"], longitude: user["lng"]}
    else
      _ -> nil
    end
  end

  defp get_jobs() do
    Repo.all(from o in Oban.Job, where: o.state == "scheduled")
    |> Enum.map(&%{id: &1.id, location: &1.args["location"], when: &1.scheduled_at})
  end

  @impl true
  def handle_event("update", %{"index" => i}, socket) do
    i = String.to_integer(i)
    location = socket.assigns.locations |> Enum.at(i)
    Oban.cancel_all_jobs(Oban.Job)
    LocationWorker.new(%{location: location, index: i}) |> Oban.insert()
    {:noreply, socket}
  end

  def handle_event("stop", _, socket) do
    Oban.cancel_all_jobs(Oban.Job)
    {:noreply, socket |> assign(jobs: get_jobs())}
  end

  @impl true
  def handle_info({:notification, :location_jobs, _}, socket) do
    {:noreply,
     socket
     |> assign(jobs: get_jobs())
     |> assign(current: get_current())}
  end
end
