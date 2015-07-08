#!/usr/bin/ruby

require 'capybara'
require 'capybara/poltergeist'
require 'logging'
require 'rspec'
require 'rspec/expectations'
require 'rspec/matchers'

include Capybara::DSL

@logger = Logging.logger['crawler_log']
@logger.level = :info
@logger.appenders = Logging.appenders.stdout

@visited_links = Array.new
@links_with_errors = Array.new
@max_level = 2

@domain = ARGV[0]
@start_page = ARGV[1]
@expected_text = ARGV[2]

Capybara.app_host = @domain
Capybara.run_server = false
Capybara.current_driver = :poltergeist

def visit_page(link, level)
  current_level = level + 1
  @logger.info "Level: #{current_level}"
  link = URI.encode(link)
  visit link
  @visited_links << link

  check_page link

  links = Array.new
  links = add_links unless current_level == @max_level

  links.each do |link|
    @logger.info "going to visit #{link}"
    visit_page link, current_level
  end
end

def add_links
  links = Array.new
    all(:css, 'a').each do|link|
      unless link[:href] == nil
        link_href = link[:href].split('#')[0].strip #stripping out jump links because driver cannot handle them
        links << link_href if link_href !=nil && link_href.start_with?(@domain) && @visited_links.include?(link_href) == false
      end
    end
    links.uniq!
    return links
end

def check_page(link)
  unless page.status_code >= 200 && page.status_code < 400 || page.status_code != 401 && page.status_code != 403
    @links_with_errors << link
    @logger.error "#{link} has error status of #{page.status_code}"
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

# Do crawl
visit_page @start_page, 0

@logger.error 'Summary of error links found: ' if @links_with_errors.size > 0
@links_with_errors.each do |link|
  @logger.error link
end

@logger.info "No broken links found!" if @links_with_errors.empty?