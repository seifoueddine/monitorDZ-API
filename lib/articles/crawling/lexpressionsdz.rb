# frozen_string_literal: true

module Articles
  # crawling files
  module Crawling
    # methode to get tsa articles
    class Lexpressiondz
      class << self
        include AbstractController::Rendering

        def get_articles_lexpressiondz(url_media_array, media)
          articles_url_lexpressiondz = []
          count = 0
          url_media_array.map do |url|
            begin
              doc = Nokogiri::HTML(open(url, 'User-Agent' => 'ruby'))
            rescue OpenURI::HTTPError => e
              puts "Can't access #{url}"
              puts e.message
              puts
              next
            end

            doc.css('article h2 a').map do |link|
              articles_url_lexpressiondz << link['href']
            end
          end
          articles_url_lexpressiondz = articles_url_lexpressiondz.reject(&:nil?)

          articles_url_lexpressiondz_after_check = []
          articles_url_lexpressiondz.map do |link|
            unless Article.where(medium_id: media.id, url_article: link).present?
              articles_url_lexpressiondz_after_check << link
            end
          end

          articles_url_lexpressiondz_after_check.map do |link|
            begin
              article = Nokogiri::HTML(open(link, 'User-Agent' => 'ruby'))
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
            new_article.category_article = article.css('#content > nav > ol > li:nth-child(3) > a').text
            new_article.title = "#{article.css('article header.heading-a p').text}, #{article.css('article header.heading-a h1').text}"
            # new_article.author = article.css('div.article-head__author div em a').text
            author_exist = if article.css('h3.scheme-user').text == ''
                             Author.where(['lower(name) like ? ', "L'expressiondz auteur".downcase])
                           else
                             a = article.css('h3.scheme-user').text
                             Author.where(['lower(name) like ? ',
                                           a.downcase])
                           end

            new_author = Author.new
            if author_exist.count.zero?

              new_author.name = article.css('h3.scheme-user').text == '' ? "L'expressiondz auteur" : article.css('h3.scheme-user').text
              new_author.medium_id = media.id
              new_author.save!
              new_article.author_id = new_author.id
            else
              new_article.author_id = author_exist.first.id
            end

            new_article.body = article.css('div.module-article p').inner_html
            new_article.body = new_article.body.gsub(/<img[^>]*>/, '')

            date_published_array = article.at('ul.list-details li').text
            new_article.date_published = date_published_array.split('|')[1].to_datetime.change({ hour: 0, min: 0,
                                                                                                 sec: 0 })
            url_array = article.css('figure.image-featured img').map { |link| link['data-src'] }
            new_article.url_image = url_array[0]
            begin
              new_article.image = Down.download(url_array[0]) if url_array[0].present?
            rescue Down::Error => e
              puts "Can't download this image #{url_array[0]}"
              puts e.message
              puts
              new_article.image = nil
            end
            # tags_array = article.css('#tags a').map(&:text)
            # new_article.media_tags = tags_array.join(',')
            new_article.status = 'pending'
            new_article.save!
            count += 1 if new_article.save
            #  tag_check_and_save(tags_array)if media.tag_status == true
          end
          count
        end
      end
    end
  end
end
