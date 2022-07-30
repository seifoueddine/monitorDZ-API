# frozen_string_literal: true

module Articles
  # crawling files
  module Crawling
    # methode to get tsa articles
    class Tsa
      class << self
        include AbstractController::Rendering
        def get_articles_tsa(url_media_array, media)
          count = 0
          articles_url_tsafr = []
          url_media_array.map do |url|
            begin
              doc = Nokogiri::HTML(URI.open(url))
            rescue OpenURI::HTTPError => e
              puts "Can't access #{url}"
              puts e.message
              puts
              next
            end
            doc.css('h1.article-preview__title.title-middle.transition a').map do |link|
              articles_url_tsafr << link['href']
            end
          end
          articles_url_tsafr = articles_url_tsafr.reject(&:nil?)
          last_articles = Article.where(medium_id: media.id)
          list_articles_url = []
          last_articles.map do |article|
            list_articles_url << article.url_article
          end
          articles_url_tsa_after_check = articles_url_tsafr - list_articles_url
          articles_url_tsa_after_check.map do |link|
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
            new_article.category_article = if article.css('div.article__meta a.article__meta-category').nil?
                                             article.css('div.anarticle__meta div a.article-meta__category').text
                                           else
                                             article.css('div.article__meta a.article__meta-category').text
                                           end
            new_article.title = if article.css('div.article__title').nil?
                                  article.css('h2.anarticle__title span').text
                                else
                                  article.css('div.article__title').text
                                end
            author_exist = if article.at('span.article__meta-author').nil?
                             Author.where(['lower(name) like ? ', 'TSA auteur'.downcase])
                           else
                             Author.where(['lower(name) like ? ',
                                           article.at('span.article__meta-author').text.downcase])
                           end

            new_author = Author.new
            if author_exist.count.zero?
              new_author.name = if article.at('span.article__meta-author').nil?
                                  'TSA auteur'
                                else
                                  article.at('span.article__meta-author').text
                                end
              new_author.medium_id = media.id
              new_author.save!
              new_article.author_id = new_author.id
            else
              new_article.author_id = author_exist.first.id
            end
            new_article.body = if article.css('div.article__content').nil?
                                 article.css('div.anarticle__content').inner_html
                               else
                                 article.css('div.article__content').inner_html
                               end
            new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
            date = article.at('time[datetime]').nil? ? Date.today : article.at('time[datetime]')['datetime']
            new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24)
            url_array = article.css('body > div.article-section > div > div.article-section__main.wrap__main > article > div.full-article__featured-image > img').map do |link|
              link['src']
            end
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
