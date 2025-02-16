defmodule Weather.Worker do

  @units  %{ imperial: %{temp: "˚F", precip: "in", wind: "miles per hour"},
              metric: %{temp: "˚C", precip: "mm", wind: "meters per second"},
              standard: %{temp: "˚K", precip: "mm", wind: "meters per second"}
         }

  @spec temperature_of(binary()) :: {:error, binary()} | {:ok, binary()}
  def temperature_of(location, units\\"imperial") do
    result = url_for(location, units) |> HTTPoison.get |> parse_response
    case result do
      {:ok, temp} -> "#{location}: #{temp} #{@units[String.to_atom(units)][:temp]}"
      {:error, msg}-> "Error retrieving temperature for #{location}: #{msg}"
    end
  end

  @spec url_for(binary(), binary()) :: binary()
  def url_for(location, units) do
    location = URI.encode(location)
    units = URI.encode(units)
    "http://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=#{apikey()}&units=#{units}"
  end

  @spec parse_response({:error, HTTPoison.Error.t()} | {:ok, HTTPoison.Response.t()}) ::
          {:error, binary()} | {:ok, any()}
  def parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body |> Poison.decode! |> compute_temperature   
  end

  def parse_response({:ok, %HTTPoison.Response{body: body, status_code: _status}}) do
    { :error, "HTTP error: #{body}"} 
  end

  def parse_response({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, inspect reason}
  end

  def compute_temperature(json) do
    try do
      temp = (json["main"]["temp"])
      {:ok, temp}
    rescue
      _ -> {:error, "Unable to process temperature"}
    end
  end

  @spec apikey() :: nil | binary()
  def apikey do
    System.get_env("OPENWEATHER_API_KEY")
  end

end