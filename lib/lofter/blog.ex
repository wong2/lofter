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

  def get_blog_id_from_redirect(response) do
    {"Location", redirect_url} = List.keyfind(response.headers, "Location", 0)
    URI.parse(redirect_url).query
    |> URI.decode_query
    |> Map.get("hostBlogId")
  end

  def get_post_ids(blog_uid, limit) do
    blog_id = get_blog_id(blog_uid)
    Logger.debug "#{blog_uid}'s id is #{blog_id}"
    fetch_post_ids(blog_uid, blog_id, limit)
  end

  def fetch_post_ids(blog_uid, blog_id, limit) do
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
    {:ok, response} = HTTPoison.post(url, payload, headers, timeout: 30000)
    Regex.scan(~r/\.permalink\s*=\s*"(\w+)"/, response.body)
    |> Enum.map(fn([_, post_id]) -> post_id end)
    |> Enum.sort_by(&Lofter.Utils.post_id_to_integer/1, &>/2)
  end

end
