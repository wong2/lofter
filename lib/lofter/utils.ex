defmodule Lofter.Utils do

  def timestamp do
    :os.system_time(:micro_seconds)
  end

  def strip_query_string(url) do
    url |> String.split("?") |> List.first
  end

  def post_id_to_integer(post_id) do
    post_id |> String.split("_") |> List.last |> String.to_integer(16)
  end

end
