defmodule Lofter.Post do
  require Logger

  def get_post_data(blog_uid, post_id) do
    post_url = "http://#{blog_uid}.lofter.com/post/#{post_id}"
    post_url
    |> fetch
    |> extract
    |> Map.merge(%{id: post_id, url: post_url})
  end

  def fetch(post_url, timeout \\ 20000) do
    Logger.info "Fetching #{post_url}"
    options = [timeout: timeout]
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.get(post_url, [], options)
    body
  end

  def extract(html) do
    %{
      image_urls: extract_image_urls(html),
      tags: extract_tags(html)
    }
  end

  def extract_image_urls(html) do
    html
    |> find_by_attr_pattern("img", "src", ~r/^http:\/\/imglf\d?.\w+.(126|127).net/)
    |> Floki.attribute("src")
    |> Enum.map(&Lofter.Utils.strip_query_string/1)
  end

  def extract_tags(html) do
    html
    |> find_by_attr_pattern("a", "href", ~r/\/tag\//)
    |> Enum.map(fn(a) -> Floki.text(a) |> String.strip(?#) end)
  end

  defp find_by_attr_pattern(html, selector, attr, pattern) do
    html
    |> Floki.find(selector)
    |> Enum.filter(fn(tag) ->
      case tag |> Floki.attribute(attr) |> List.first do
        nil -> []
        value -> Regex.match?(pattern, value)
      end
    end)
  end

end
