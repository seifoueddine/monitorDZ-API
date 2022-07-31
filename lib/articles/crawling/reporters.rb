# frozen_string_literal: true

module Articles
  # crawling files
  module Crawling
    # methode to get Reporters articles
    class Reporters
      class << self
        include AbstractController::Rendering
        def get_articles_reporters(url_media_array, media)
          articles_url_reporters = []
          count = 0
          url_media_array.map do |url|
            begin
              doc = Nokogiri::HTML(URI.open(url))
            rescue OpenURI::HTTPError => e
              puts "Can't access #{url}"
              puts e.message
              puts
              next
            end
            doc.css('h3.entry-title.td-module-title a').map do |link|
              articles_url_reporters << link['href']
            end
          end

          articles_url_reporters = articles_url_reporters.reject(&:nil?)
          articles_url_reporters_after_check = []
          articles_url_reporters.map do |link|
            articles_url_reporters_after_check << link unless Article.where(medium_id: media.id,
                                                                            url_article: link).present?
          end
          articles_url_reporters_after_check.map do |link|
            begin
              article = Nokogiri::HTML(URI.open(link))
            rescue OpenURI::HTTPError => e
              puts "Can't access #{link}"
              puts e.message
              puts
              next
            end
            new_article = Article.new
            new_article.url_article = link
            new_article.medium_id = media.id
            new_article.language = media.language
            new_article.category_article = article.css('header.td-post-title ul.td-category a').text
            new_article.title = article.css('h1.entry-title').text
            author_exist = if article.at('div.td-post-author-name').nil?
                             Author.where(['lower(name) like ? ', 'reporters auteur'.downcase])
                           else
                             Author.where(['lower(name) like ? ',
                                           article.at('div.td-post-author-name').text.downcase])
                           end
            new_author = Author.new
            if author_exist.count.zero?
              new_author.name = article.at('div.td-post-author-name').nil? ? 'reporters auteur' : article.at('div.td-post-author-name').text
              new_author.medium_id = media.id
              new_author.save!
              new_article.author_id = new_author.id
            else
              new_article.author_id = author_exist.first.id
            end
            new_article.body = article.css('div.td-post-content').inner_html
            new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
            new_article.date_published = article.at('time[datetime]')['datetime'].to_datetime.change({ hour: 0, min: 0,
                                                                                                       sec: 0 }) + (1.0 / 24)
            url_array = article.css('div.td-post-featured-image img').map { |link| link['src'] }
            new_article.url_image = url_array[0]
            begin
              new_article.image = Down.download(url_array[0]) if url_array[0].present?
            rescue Down::Error => e
              puts "Can't download this image #{url_array[0]}"
              puts e.message
              puts
              new_article.image = nil
            end
            new_article.status = 'pending'
            new_article.save!
            count += 1 if new_article.save
          end
          count
        end
      end
    end
  end
end
