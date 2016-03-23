defmodule Lofter do
  require Logger

  def main(args) do
    args
    |> parse_args
    |> process
  end

  def parse_args(args) do
    {options, blog_uids, _} = OptionParser.parse(
      args,
      switches: [dir: :string, concurrency: :integer, limit: :integer],
      aliases: [d: :dir, c: :concurrency, l: :limit]
    )
    default_options = [dir: ".", concurrency: 10, limit: 99999]
    options = Keyword.merge(default_options, options) |> Enum.into(%{})
    %{dir: directory, concurrency: concurrency, limit: limit} = options
    {{directory, concurrency, limit}, blog_uids}
  end

  def process({_, []}) do
    IO.puts """
    Usage: lofter blog1 blog2 ...
    Options:
      -d, --dir:  output directory
      -c, --concurrency: how many requests can be made at the same time, defaults to 10
      -l, --limit: only fetch newest N posts, defaults to no limit
    """
  end

  def process({{directory, concurrency, limit}, blog_uids}) do
    Enum.each(blog_uids, fn(blog_uid) ->
      output_path = Path.join(directory, "#{blog_uid}.json")
      dumps(blog_uid, output_path, concurrency, limit)
    end)
  end

  def dumps(blog_uid, path, concurrency, limit) do
    content = blog_uid
              |> scrape_posts(concurrency, limit)
              |> Poison.encode_to_iodata!
    File.write!(path, content)
    Logger.info "Blog posts #{blog_uid} dumped at #{path}"
  end

  def scrape_posts(blog_uid, concurrency, limit) do
    Logger.info "Starting scrape #{blog_uid}"
    post_ids = Lofter.Blog.get_post_ids(blog_uid, limit)

    Logger.info "Total posts: #{length(post_ids)}"
    get_post_datas(post_ids, blog_uid, concurrency)
  end

  def get_post_datas(post_ids, blog_uid, concurrency) do
    post_ids
    |> Enum.map(fn (post_id) ->
      Lofter.Post.get_post_data(blog_uid, post_id)
    end)
  end

end
