defmodule PuppiesUpdater.PuppiesCom do
  def get_token() do
    email = Application.fetch_env!(:puppies_updater, :email)
    password = Application.fetch_env!(:puppies_updater, :password)

    Finch.build(
      :post,
      "https://puppies.com/api/auth/token",
      [],
      Jason.encode!(%{email: email, password: password})
    )
    |> Finch.request(PuppiesUpdater.Finch)
    |> case do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, body |> Jason.decode!() |> Map.get("id_token")}

      error ->
        IO.inspect(error)
        {:error, error}
    end
  end

  def get_user(token) do
    Finch.build(
      :get,
      "https://puppies.com/api/users/me",
      [{"authorization", "Bearer #{token}"}]
    )
    |> Finch.request(PuppiesUpdater.Finch)
    |> case do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, body |> Jason.decode!()}

      error ->
        IO.inspect(error)
        {:error, error}
    end
  end

  def update_user(token, location) do
    Finch.build(
      :patch,
      "https://puppies.com/api/users/me",
      [{"authorization", "Bearer #{token}"}],
      Jason.encode!(location)
    )
    |> Finch.request(PuppiesUpdater.Finch)
    |> case do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, body |> Jason.decode!()}

      error ->
        IO.inspect(error)
        {:error, error}
    end
  end
end
