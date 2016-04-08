defmodule Lofter.Blog do
  require Logger

  def get_blog_id(blog_uid) do
    url = "http://#{blog_uid}.lofter.com/view"
    Logger.debug "Fetching #{url}"
    {:ok, response} = HTTPoison.get(url, [], timeout: 20000)
    case response.status_code do
      302 -> get_blog_id_from_redirect(response)
    end
  end

  defp get_blog_id_from_redirect(response) do
    {"Location", redirect_url} = List.keyfind(response.headers, "Location", 0)
    URI.parse(redirect_url).query
    |> URI.decode_query
    |> Map.get("hostBlogId")
  end

  def get_posts(blog_uid, concurrency, limit) do
    Logger.info "Starting scrape #{blog_uid}"
    blog_id = get_blog_id(blog_uid) |> String.to_integer
    Logger.debug "#{blog_uid}'s id is #{blog_id}"
    fetch_post_list(blog_id, blog_uid, limit)
    |> parse_basic_post_list
    |> Enum.map(fn basic_post ->
      post_id = basic_post["id"]
      post_uid = Lofter.Utils.post_id_to_uid(post_id, blog_id)
      post_url = Lofter.Post.format_url(blog_uid, post_uid)
      Lofter.Post.get_post_data(post_url) |> Map.merge(basic_post)
    end)
  end

  def fetch_post_list(blog_id, blog_uid, limit) do
    url = "http://#{blog_uid}.lofter.com/dwr/call/plaincall/ArchiveBean.getArchivePostByTime.dwr"
    payload = """
    callCount=1
    scriptSessionId=${scriptSessionId}187
    c0-scriptName=ArchiveBean
    c0-methodName=getArchivePostByTime
    c0-id=0
    c0-param0=number:#{blog_id}
    c0-param1=number:#{Lofter.Utils.timestamp}
    c0-param2=number:#{limit}
    c0-param3=boolean:false
    batchId=0
    """
    headers = %{"Referer" => "http://lofter.com"}
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.post(url, payload, headers, timeout: 30000)
    body
  end

  def parse_basic_post_list(body) do
    Regex.scan(~r/s(\d+)\.(time|id)\s*=\s*(\w+)/, body, capture: :all_but_first)
    |> Enum.group_by(&List.first/1)
    |> Map.values
    |> Enum.map(fn group ->
      Map.new(group, fn [_, key, value] -> {key, String.to_integer(value)} end)
    end)
    |> Enum.sort_by(fn p -> Map.get(p, "time") end, &>/2)
  end

end
