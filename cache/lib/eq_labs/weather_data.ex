defmodule EqLabs.WeatherData do
  use Tesla

  @base_url "https://api.open-meteo.com/"

  plug Tesla.Middleware.BaseUrl, @base_url
  plug Tesla.Middleware.JSON
  # plug Tesla.Middleware.Logger

  def get_weather() do
    # make HTTP request to open API to retrieve weather data
    url = "/v1/forecast?latitude=52.52&longitude=13.41&current_weather=true&hourly=temperature_2m,relativehumidity_2m,windspeed_10m"
    {:ok, response} = get(url)
    # parse response and return weather data
    case response.status do
      200 ->
        {:ok, response.body}
      _ ->
        {:error, "Request failed"}
    end
  end
end