# frozen_string_literal: true

module Articles
  # crawling files
  module Crawling
    # methode to get Elcherouk articles
    class Elcherouk
      class << self
        include AbstractController::Rendering
        def get_articles_elcherouk(url_media_array, media)
          articles_url_cherouk = []
          count = 0
          url_media_array.map do |url|
            # doc = Nokogiri::HTML(URI.open(url))

            begin
              doc = Nokogiri::HTML(URI.open(url))
            rescue OpenURI::HTTPError => e
              puts "Can't access #{url}"
              puts e.message
              puts
              next
            end

            doc.css('section h3 a').map do |link|
              articles_url_cherouk << link['href']
            end
          end
          articles_url_cherouk = articles_url_cherouk.reject(&:nil?)
          articles_url_cherouk_after_check = []
          articles_url_cherouk.map do |link|
            articles_url_cherouk_after_check << link unless Article.where(medium_id: media.id,
                                                                          url_article: link).present?
          end
          articles_url_cherouk_after_check.map do |link|
            begin
              article = Nokogiri::HTML(URI.open(link))
            rescue OpenURI::HTTPError => e
              puts "Can't access #{link}"
              puts e.message
              puts
              next
            rescue RuntimeError => e
              puts "Can't access #{link}"
              puts e.message
              puts
              next
            end
            new_article = Article.new
            new_article.url_article = link
            new_article.medium_id = media.id
            new_article.language = media.language
            new_article.category_article = article.css('article a.ech-bkbt._albk').text
            new_article.title = article.css('article h1.ech-sgmn__title.ech-sgmn__sdpd').text
            # new_article.author = article.css('div.article-head__author div em a').text

            author_exist = Author.where(['lower(name) like ? ',
                                         article.css('article div.d-f.fxd-c.ai-fs a').text.downcase])

            new_author = Author.new
            if author_exist.count.zero?
              new_author.name = article.css('article div.d-f.fxd-c.ai-fs a').text
              new_author.medium_id = media.id
              new_author.save!
              new_article.author_id = new_author.id
            else
              new_article.author_id = author_exist.first.id
            end
            new_article.body = article.css('article div.ech-artx').inner_html
            new_article.body = new_article.body.gsub(/<img[^>]*>/, '')

            date = DateTime.parse article.css('article.ech-sgmn__article time').text
            new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })

            unless article.at_css('article.ech-sgmn__article figure img').nil?
              url_array = article.at_css('article.ech-sgmn__article figure img').attr('data-src')
            end
            new_article.url_image = url_array

            # new_article.image = Down.download(url_array[0]) if url_array[0].present?

            begin
              new_article.image = Down.download(url_array) if url_array.present?
            rescue Down::ResponseError => e
              puts "Can't download this image #{url_array}"
              puts e.message
              puts
              new_article.image = nil
            end

            tags_array = article.css('ul.ech-sgmn__tgls.d-f.fxw-w.jc-fe a').map(&:text)
            # new_article.media_tags = tags_array.join(',')
            new_article.status = 'pending'
            new_article.save!
            count += 1 if new_article.save
            # tag_check_and_save(tags_array)if media.tag_status == true
          end
          count
        end
      end
    end
  end
end
