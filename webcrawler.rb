#!/usr/bin/env ruby
# Copyright (C) 2015 Pentestgeek.com
# #
# #This program is free software: you can redistribute it and/or modify
# #it under the terms of the GNU General Public License as published by
# #the Free Software Foundation, either version 3 of the License, or
# #any later version.
# #
# #This program is distributed in the hope that it will be useful,
# #but WITHOUT ANY WARRANTY; without even the implied warranty of
# #MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# #GNU General Public License for more details.
# #
# #You should have received a copy of the GNU General Public License
# #along with this program. If not, see <http://www.gnu.org/licenses/>
APP_ROOT = File.dirname(__FILE__)
$:.unshift( File.join(APP_ROOT, 'lib'))

# require dependencies
require 'net/https'
require 'optparse'
require 'crawler'
require 'pry'
require 'nokogiri'
require 'thread/pool'
require 'optparse'

@options = {}
args = OptionParser.new do |opts|
  opts.banner = "./webcrawler.rb -h [host] -p [port]\r\n\r\n"
  opts.on("-t", "--target [Website]", "Website to crawl i.e www.site.com") { |target| @options[:target] = target }
  opts.on("-d", "--debug", "Enabled full debug mode, lots of output") { |d| @options[:debug] = true }
  opts.on("-v", "--verbose", "Enables verbose output\r\n\r\n") { |v| @options[:verbose] = true }
end
args.parse!(ARGV)

#setup Crawler options
opts = {
  base_url: @options[:target],
  user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko)',
  url_queue: Array.new,
  urls_crawled: Array.new,
  threads: Thread.pool(5),
  args: @options
}

# initialize the crawler and let it loose
crawler = Crawler.new(opts)
crawler.crawl