# Webcrawler.rb

This is purely an educational tool for practicing web crawling.  It
doesn't do anything very useful as is.

Change this stuff to your liking.
~~~ruby
opts = {
  base_url: @options[:target],
  user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko)',
  url_queue: Array.new,
  urls_crawled: Array.new,
  threads: Thread.pool(5),
  args: @options
}
~~~