require 'Nokogiri'
require 'JSON'
require 'Pry'
require 'csv'
require 'mechanize'

## This is the least performant and worst code ever. I'm just hacking something together for a friend real quick and my data size is relatively small. Don't judge!

class RockAndIceScraper

  attr_accessor :agent, :page, :homepage_he_count, :homepage_hes, :homepage_she_count, :homepage_shes, :scraped_pages, :error_pages, :news, :news_scraped_pages, :articles_with_he_no_she,
  :articles_with_she_no_he, :articles_with_any_she, :articles_with_any_he, :overall_he_occurences, :overall_she_occurences

  def initialize
    @agent = Mechanize.new
    @page = @agent.get("http://www.rockandice.com/")
    @homepage_he_count = 0
    @homepage_hes = []
    @homepage_she_count = 0
    @homepage_shes = []
    @homepage_scraped_pages = {}
    @news_scraped_pages = {}
    @error_pages = {}
    @news = @agent.get("http://www.rockandice.com/climbing-news-stories")
    @articles_with_he_no_she = []
    @articles_with_she_no_he = []
    @articles_with_any_she = []
    @articles_with_any_he = []
    @overall_he_occurences = 0
    @overall_she_occurences = 0
  end


  def scrape_homepage
    homepage_classes_and_tags = [".headline", ".synopsis", ".sod-title",  ".sod-synopsis", "p", ".title", ".video-title"]
    homepage_classes_and_tags.each do |homepage_class|
      @page.css(homepage_class).map do |node|
        text = node.text
        if !!(/ he /.match(text))
          @homepage_he_count += 1
          @homepage_hes.push(text)
        end

        if !!(/ she /.match(text))
          @homepage_she_count += 1
          @homepage_shes.push(text)
        end

      end
    end
  end

  def deep_scrape_homepage
    links = [".sotd-link" ".top-news-item a", ".clean-box a", ".main-side a"]
    links.each do |link_type|
      page.search(link_type).each do |node|
        destination = node.attributes["href"].value
        if /rockandice/.match(destination)
          #stay on site
          begin
            sub_page = agent.get(destination)
            @homepage_scraped_pages[destination] = {"he" => 0, "she" => 0}
            search_paragraphs(sub_page, destination, @homepage_scraped_pages)
            search_paginations(sub_page, destination)
          rescue => e
            @error_pages[destination] = e
          end
        end
      end
    end
  end

  def search_paragraphs(page, destination, scraped_pages)
    page.css(".story p").each do |node|
      text = node.text
      scraped_pages[destination]["he"] += text.scan(/ he /).size
      scraped_pages[destination]["she"] += text.scan(/ she /).size
    end
  end

  def search_paginations
    #TODO - search whole stories
  end

  def deep_scrape_news
    links = [".article-list-link a"]
    links.each do |link_type|
      @news.search(link_type)[0..400].each do |news_node|
        destination = news_node.attributes["href"].value
        begin
            sub_page = agent.get(destination)
            @news_scraped_pages[destination] = {"he" => 0, "she" => 0}
            search_paragraphs(sub_page, destination, @news_scraped_pages)
            search_paginations(sub_page, destination)
          rescue => e
            @error_pages[destination] = e
          end
      end
    end
  end

  def totals
    @news_scraped_pages.each do |article|
      @articles_with_he_no_she.push(article.first) if (article.last["he"] > 0) && (article.last["she"] == 0)
      @articles_with_she_no_he.push(article.first) if (article.last["she"] > 0) && (article.last["he"] == 0)
      @articles_with_any_she.push(article.first) if article.last["she"] > 0
      @articles_with_any_he.push(article.first) if article.last["he"] > 0
    end
  end

  def overall
    @news_scraped_pages.each do |article|
      @overall_he_occurences += article.last["he"]
      @overall_she_occurences += article.last["she"]
    end
  end

end

RI = RockAndIceScraper.new
RI.scrape_homepage
RI.deep_scrape_homepage
RI.deep_scrape_news
RI.totals


binding.pry

puts "hi"