defmodule PuppiesUpdater.Locations.Location do
  @derive Jason.Encoder
  defstruct name: nil, latitude: nil, longitude: nil, num_hours: nil
end

defmodule PuppiesUpdater.Locations do
  alias PuppiesUpdater.Locations.Location

  @external_resource "lib/locations.txt"

  locations =
    @external_resource
    |> File.read!()
    |> String.split("\n\n", trim: true)
    |> Enum.map(fn str ->
      [name, latitude, longitude, num_hours] = String.split(str, "\n", trim: true)

      Macro.escape(%Location{
        name: name,
        latitude: String.to_float(latitude),
        longitude: String.to_float(longitude),
        num_hours: String.to_integer(num_hours)
      })
    end)

  def locations(), do: unquote(locations)
end
