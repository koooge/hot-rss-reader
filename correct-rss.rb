# coding: utf-8

require 'open-uri'
require 'openssl'
require 'rss'
require 'json'
#require 'nokogiri'

Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file}

rss_list_filename = File.dirname(__FILE__) + '/rss_list.json'

PROXY_HOST = ''
PROXY_PORT = ''
PROXY_USER = ''
PROXY_PASS = ''

class NewsList
  @@open_options =
      { :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE,
        "User-Agent" => "Ruby/#{RUBY_VERSION}",
        # :proxy_http_basic_authentication =>
        #     ['http://' + PROXY_HOST + ':' + PROXY_PORT, PROXY_USER, PROXY_PASS]
      }

  def fetch_rss(url)
    page = open(url, @@open_options).read
    return page
  end

  def parse_rss(page, type)
    case type
    when 'rss'
      rss = RSS::Parser.parse(page, true)
      items = rss.items
      return items
    end
  end

  def get_news_list(items, type, threshold, redirect)
    news = []
    case type
    when 'twitter'
      items.each do |item|
        next if item.title =~ /^PR/
        if redirect
          link = open(item.link, @@open_options).base_uri.to_s.split('?')[0]
        else
          link = item.link
        end
        tweet_link = 'http://urls.api.twitter.com/1/urls/count.json?url=' + link
        tweet_count = JSON.parse(open(tweet_link, @@open_options).read)['count']
        news.push("\"#{item.title}\" #{link} #{tweet_count}tweets") if tweet_count >= threshold
      end
    when 'facebook'
      items.each do |item|
        next unless item.link.start_with?('http')
        fb_link = 'http://graph.facebook.com/?id=' + item.link
        fb_shares = JSON.parse(open(fb_link, @@open_options).read)['shares']
        unless fb_shares.nil?
          news.push("\"#{item.title}\" #{item.link} #{fb_shares}shares") if fb_shares >= threshold
        end
      end
    when 'hacker_news'
    when 'slash_dot'
    end
    return news
  end

  def new_article?
  end
end

feeds = []
begin
  rss_list = open(rss_list_filename) do |io|
    JSON.load(io)
  end

  news_list = NewsList.new
  rss_list.each do |rss|
    page = news_list.fetch_rss rss['url']
    items = news_list.parse_rss(page, rss['type'])
    news = news_list.get_news_list(items, rss['evaluation'], rss['threshold'], rss['redirect'])
    feeds.push(news)
  end

  url = 'https://news.ycombinator.com'
  page = news_list.fetch_rss url
  feeds.push(HackerNewsRss.get_news page)

  url = 'http://srad.jp/sradjp.rss'
  page = news_list.fetch_rss url
  items = news_list.parse_rss(page, 'rss')
  feeds.push(SladRss.get_news items)
rescue => e
  feeds.push(e.backtrace)
end

File.open(File.dirname(__FILE__) + "/news_list.txt", "w") do |file|
  feeds.each do |feed|
    feed.each do |news|
      file.puts news
      puts news
    end
  end
end