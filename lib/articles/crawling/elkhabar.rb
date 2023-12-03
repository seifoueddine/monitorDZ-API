# frozen_string_literal: true

module Articles
  # crawling files
  module Crawling
    # methode to get Elkhabar articles
    class Elkhabar
      class << self
        require_relative 'crawlingmethods'
        include Crawlingmethods
        include AbstractController::Rendering
        def get_articles_elkhabar(url_media_array, media)
          count = 0
          articles_url_elkhabar = []
          last_dates = []
          url_media_array.map do |url|
            begin
              doc = Nokogiri::HTML(URI.open(url))
            rescue OpenURI::HTTPError => e
              puts "Can't access #{url}"
              puts e.message
              puts
              next
            end
            doc.css('h2.panel-title a').map do |link|
              articles_url_elkhabar << "https://www.elkhabar.com#{link['href']}" unless link.css('i').present?
            end
            doc.css('time').map do |date|
              last_dates << date['datetime']
            end
          end

          last_dates = last_dates.map { |d| change_translate_date(d) }
          last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
          articles_url_elkhabar = articles_url_elkhabar.reject(&:nil?)
          articles_url_elkhabar = articles_url_elkhabar.uniq
          last_dates = last_dates.uniq
          last_articles = Article.where(medium_id: media.id).where(date_published: last_dates)
          list_articles_url = []
          last_articles.map do |article|
            list_articles_url << article.url_article
          end
          articles_url_elkhabar_after_check = articles_url_elkhabar - list_articles_url
          articles_url_elkhabar_after_check.map do |link|
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
            if article.css('span.category-blog').present?
              new_article.category_article = article.css('span.category-blog').text
            end
            new_article.title = article.css('section div div div h1.title').text unless article.css('section div div div h1.title').nil?
            # new_article.author = article.css('div.article-head__author div em a').text

            author_exist = if article.at('span.time-blog b').present?
                             Author.where(['lower(name) like ? ',
                                           article.at('span.time-blog b').text.downcase])
                           else
                             Author.where(['lower(name) like ? ', 'Elkhabar auteur'.downcase])

                           end

            new_author = Author.new
            if author_exist.count.zero?

              new_author.name = article.at('span.time-blog b').present? ? article.at('span.time-blog b').text : 'Elkhabar auteur'
              new_author.medium_id = media.id
              new_author.save!
              new_article.author_id = new_author.id
            else
              new_article.author_id = author_exist.first.id

            end
            new_article.body = article.css('div#article_body_content').inner_html
            new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
            # date = article.at('p.text-capitalize span').text
            # date[','] = ''
            date = article.at('time[datetime]')['datetime']
            new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
            if article.css('div#article_img img').present?
              url_array = article.css('div#article_img img').map { |link| "https://www.elkhabar.com#{link['src']}" }
            end
            # url_image = url_array[0]
            begin
              new_article.image = Down.download(url_array[0]) if url_array.present?
            rescue Down::Error => e
              puts "Can't download this image #{url_array[0]}"
              puts e.message
              puts
              new_article.image = nil
            end
            # if article.css('div#article_tags_title').present?
            # tags_array = article.css('div#article_tags_title').map(&:text)
            # end
            # new_article.media_tags = tags_array.join(',')
            new_article.status = 'pending'
            new_article.save!
            count += 1 if new_article.save
            # tag_check_and_save(tags_array) if media.tag_status == true
          end
          count
        end
      end
    end
  end
end
