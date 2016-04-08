defmodule Lofter.Utils do

  def timestamp do
    :os.system_time(:micro_seconds)
  end

  def strip_query_string(url) do
    url |> String.split("?") |> List.first
  end

  def post_uid_to_id(post_uid) do
    post_uid |> String.split("_") |> List.last |> String.to_integer(16)
  end

  def post_id_to_uid(post_id, blog_id) do
    :io_lib.format("~.16b_~.16b", [blog_id, post_id]) |> to_string
  end

end
