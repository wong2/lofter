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
              |> Lofter.Blog.get_posts(concurrency, limit)
              |> Poison.encode_to_iodata!
    File.write!(path, content)
    Logger.info "Blog posts #{blog_uid} dumped at #{path}"
  end

end
