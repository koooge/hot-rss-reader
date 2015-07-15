# coding: utf-8

require 'nokogiri'

module HackerNewsRss
  def self.get_news(page)
    news = []
    html = Nokogiri::HTML(page)
    athings = html.xpath("//tr[@class = 'athing']")
    subtexts = html.xpath("//td[@class = 'subtext']")  
    for i in 0..(athings.size-1)
      news_title = athings[i].xpath("td[@class = 'title']/a").text
      news_url = athings[i].xpath("td[@class = 'title']/a").attribute('href')
      news_point = subtexts[i].xpath("span[@class='score']").text.to_i
      news.push("\"#{news_title}\" #{news_url} #{news_point}points") if news_point >= 500
    end
    return news
  end
end