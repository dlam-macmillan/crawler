require 'spec_helper'
require 'childprocess'
require 'httparty'
require 'wrong'
require_relative '../crawler'
require_relative '../link'

describe "crawler" do
  before :all do
    begin
      @test_website = ChildProcess.build('ruby', File.join(File.dirname(__FILE__), '../test/test-website/website.rb'))
      @test_website.start
      Wrong.eventually(timeout: 2) { HTTParty.get("http://localhost:8080/index.html").success? }
    rescue
      puts 'test website failed to start'
      Process.exit(-1)
    end
    puts 'test website started successfully'
  end

  after :all do
    @test_website.stop
  end

  it "crawls 3 levels" do
    start = Link.new('', 'http://localhost:8080/index.html')
    crawler = Crawler.new(3)
    crawler.crawl(start)

    expect(crawler.csv.to_s.include?(',http://localhost:8080/index.html')).to be(true)
    expect(crawler.csv.to_s.include?('http://localhost:8080/index.html,http://localhost:8080/level-one.html')).to be(true)
    expect(crawler.csv.to_s.include?('http://localhost:8080/level-one.html,http://localhost:8080/level-two.html')).to be(true)
  end

  it "crawls 2 level" do
    start = Link.new('', 'http://localhost:8080/index.html')
    crawler = Crawler.new(2)
    crawler.crawl(start)

    expect(crawler.csv.to_s.include?(',http://localhost:8080/index.html')).to be(true)
    expect(crawler.csv.to_s.include?('http://localhost:8080/index.html,http://localhost:8080/level-one.html')).to be(true)
    expect(crawler.csv.to_s.include?('http://localhost:8080/level-one.html,http://localhost:8080/level-two.html')).to be(false)
  end

  it "reports broken links (404)" do
    start = Link.new('', 'http://localhost:8080/mising/page')
    crawler = Crawler.new(2)
    crawler.crawl(start)

    expect(crawler.csv.to_s.include?(',http://localhost:8080/mising/page,404,')).to be(true)
  end

  it "it reports the correct source and destination values in the results" do
    start = Link.new('', 'http://localhost:8080/page-with-multiple-children.html')
    crawler = Crawler.new(3)
    crawler.crawl(start)

    expect(crawler.csv.to_s.include?(',http://localhost:8080/page-with-multiple-children.html,')).to be(true)
    expect(crawler.csv.to_s.include?('http://localhost:8080/page-with-multiple-children.html,')).to be(true)
    expect(crawler.csv.to_s.include?('http://localhost:8080/level-two-child-a.html,http://localhost:8080/level-three-child-a-a.html,')).to be(true)
    expect(crawler.csv.to_s.include?('http://localhost:8080/page-with-multiple-children.html,http://localhost:8080/level-two-child-b.html,')).to be(true)
    expect(crawler.csv.to_s.include?('http://localhost:8080/level-two-child-b.html,http://localhost:8080/level-three-child-b-b.html,')).to be(true)
    expect(crawler.csv.to_s.include?('http://localhost:8080/page-with-multiple-children.html,http://localhost:8080/level-two-child-c.html,')).to be(true)
    expect(crawler.csv.to_s.include?('http://localhost:8080/level-two-child-c.html,http://localhost:8080/level-three-child-c-c.html,')).to be(true)
  end

  it "it stops following links in a closed look when it reaches the max depth level" do
    start = Link.new('', 'http://localhost:8080/loop-a.html')
    crawler = Crawler.new(3)
    crawler.crawl(start)

    expect(crawler.csv.to_s.include?('http://localhost:8080/loop-a.html,http://localhost:8080/loop-b.html')).to be(true)
    expect(crawler.csv.to_s.include?('http://localhost:8080/loop-b.html,http://localhost:8080/loop-a.html')).to be(true)
  end

end