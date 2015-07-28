#!/usr/bin/ruby

require 'logging'
require 'rspec'
require 'rspec/expectations'
require 'rspec/matchers'
require 'httparty'
require 'nokogiri'
require_relative 'link'

class Crawler

  attr_accessor :csv

  def initialize(max_level, expected_text=nil)
    @logger = Logging.logger['crawler_log']
    @logger.level = :info
    @logger.appenders = Logging.appenders.stdout

    @visited_links = Array.new
    @links_with_errors = Array.new
    @max_level = max_level

    @expected_text = expected_text
    @response
    @previous_link
    @csv = "source,destination,status code,time\n"
  end

  def crawl(link_object, level=0)
    current_level = level + 1
    @logger.info "Level: #{current_level}"
    link = URI.encode(link_object.destination)

    begin
      @response = HTTParty.get(link, cookies:{laserwolf_beta:'true', natureWideSurvey: '0'}, limit:3)
      event = {:source => link_object.source, :destination => link_object.destination , :status_code => @response.code, :time => Time.now.getutc}
      p event
      print_csv_row(event)

      @visited_links << link

      check_page link

      links = Array.new
      links = add_links(@response.body, link) unless current_level == @max_level

      links.each do |link_object|
        @logger.info "going to visit #{link_object.destination}"
        crawl link_object, current_level
      end

      @previous_link = link
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

  def add_links(body, source)
    webpage = Nokogiri.HTML(body)
    matches = webpage.search('a').map{ |a| a['href'] }

    links = Array.new
    matches.each do |link|
      links << Link.new(source, link) if link.to_s.start_with?('http') #&& @visited_links.include?(link) == false
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
end