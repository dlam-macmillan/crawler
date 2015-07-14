#!/usr/bin/ruby

require 'logging'
require 'rspec'
require 'rspec/expectations'
require 'rspec/matchers'
require 'httparty'
require 'nokogiri'

@logger = Logging.logger['crawler_log']
@logger.level = :info
@logger.appenders = Logging.appenders.stdout

@visited_links = Array.new
@links_with_errors = Array.new
@max_level = ARGV[0].to_i || 2

# @domain = ARGV[0]
@start_page = ARGV[1]
@expected_text = ARGV[2]
@response
@previous_link
@csv = "source,destination,status code,time\n"

def crawl(link, level=0)
  current_level = level + 1
  @logger.info "Level: #{current_level}"
  link = URI.encode(link.strip)

  begin
    @response = HTTParty.get(link, cookies:{laserwolf_beta:'true', natureWideSurvey: '0'}, limit:3)
    event = {:source => @previous_link, :destination => link, :status_code => @response.code, :time => Time.now.getutc}
    p event
    print_csv_row(event)

    @visited_links << link

    check_page link

    links = Array.new
    links = add_links(@response.body) unless current_level == @max_level

    @previous_link = link

    links.each do |link|
      @logger.info "going to visit #{link}"
      crawl link, current_level
    end
  rescue HTTParty::RedirectionTooDeep => error
    event = {:source => @previous_link, :destination => link, :status_code => "Error: over 3 redirects Details: #{error}", :time => Time.now.getutc}
    p event
    print_csv_row(event)
  rescue
    event = {:source => @previous_link, :destination => link, :status_code => "Error: #{error}", :time => Time.now.getutc}
    p event
    print_csv_row(event)
  end

end

def add_links(body)
  webpage = Nokogiri.HTML(body)
  matches = webpage.search('a').map{ |a| a['href'] }

  links = Array.new
  matches.each do |link|
    links << link if link.to_s.start_with?('http') && @visited_links.include?(link) == false
  end

  links.uniq!
  return links
end

def check_page(link)
  unless @response.code >= 200 && @response.code < 400 || @response.code != 401 && @response.code != 403
    @links_with_errors << link
    @logger.error "#{link} has error status of #{@response.code}"
    return false
  end

  unless @expected_text.to_s.empty?
    begin
      unless find(:css, 'html').text.include? @expected_text
        @logger.error "Unable to find the text \"#{@expected_text}\" on the page"
        @links_with_errors << link
      end
    rescue Capybara::ElementNotFound
      @logger.error 'Unable to find expected element on page. Full stacktrace: '
      @logger.error $!.backtrace
      @links_with_errors << link
    rescue
      @logger.error "Unable to find the text \"#{@expected_text}\" on the page"
      @logger.error $!.backtrace
      @links_with_errors << link
    end
  end
end

def print_csv_row(event)
  @csv << "#{event[:source]},#{event[:destination]},#{event[:status_code]},#{event[:time]}\n"
end

# Do crawl
crawl @start_page

@logger.error 'Summary of error links found: ' if @links_with_errors.size > 0
@links_with_errors.each do |link|
  @logger.error link
end

@logger.info "No broken links found!" if @links_with_errors.empty?

p 'this is the csv'
puts @csv

File.write("crawler_results_#{DateTime.now.strftime('%s')}.csv", @csv)