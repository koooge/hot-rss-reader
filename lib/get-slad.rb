# coding: utf-8

module SladRss
  def self.get_news(items)
    news = []
    items.each do |item|
      comments = item.slash_comments
      next if comments.nil?
      news.push("\"#{item.title}\" #{item.link} #{comments}comments") if comments >= 50
    end
    return news
  end
end