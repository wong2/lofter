defmodule Lofter.Utils do

  def timestamp do
    :os.system_time(:micro_seconds)
  end

  def strip_query_string(url) do
    url |> String.split("?") |> List.first
  end

end
