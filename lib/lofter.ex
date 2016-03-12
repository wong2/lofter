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
      switches: [dir: :string],
      aliases: [d: :dir]
    )
    default_options = [dir: "."]
    {Keyword.merge(default_options, options), blog_uids}
  end

  def process({_, []}) do
    IO.puts "Usage: [-d output_directory] blog1 blog2 ..."
  end

  def process({[dir: directory], blog_uids}) do
    Enum.each(blog_uids, fn(blog_uid) ->
      output_path = Path.join(directory, "#{blog_uid}.json")
      dumps(blog_uid, output_path)
    end)
  end

  def dumps(blog_uid, path, concurrency \\ 10) do
    content = blog_uid
              |> scrape_posts(concurrency)
              |> Poison.encode_to_iodata!
    File.write!(path, content)
    Logger.info "Blog posts #{blog_uid} dumped at #{path}"
  end

  def scrape_posts(blog_uid, concurrency, limit \\ 10000) do
    Logger.info "Starting scrape #{blog_uid}"
    post_ids = Lofter.Blog.get_post_ids(blog_uid, limit)

    Logger.info "Total posts: #{length(post_ids)}"
    get_post_datas(post_ids, blog_uid, concurrency)
  end

  def get_post_datas(post_ids, blog_uid, concurrency) do
    Parallel.map(post_ids, fn(post_id) ->
      Lofter.Post.get_post_data(blog_uid, post_id)
    end, size: concurrency)
  end

end
