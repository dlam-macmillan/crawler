#!/usr/bin/ruby

require_relative 'crawler'

# Do crawl
@max_level = ARGV[0].to_i || 2
@start_page = ARGV[1]
@expected_text = ARGV[2]

start = Link.new('', @start_page)
p start.destination

crawler = Crawler.new(@max_level, @expected_text)
crawler.crawl(start)

p 'this is the csv'
p crawler.csv

File.write("crawler_results_#{DateTime.now.strftime('%s')}.csv", crawler.csv)