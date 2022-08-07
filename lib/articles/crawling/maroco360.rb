# frozen_string_literal: true

module Articles
  # crawling files
  module Crawling
    # methode to get Maroco360 articles
    class Maroco360
      class << self
        include AbstractController::Rendering

        def get_articles_maroco360(url_media_array, media)
          articles_url_maroco360 = []
          count = 0
          url_media_array.map do |url|
            puts url
            begin
              doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.5', 'From' => 'foo@bar.invalid'), nil,
                                   'UTF-8')
            rescue OpenURI::HTTPError => e
              puts "Can't access #{url}"
              puts e.message
              puts
              next
            end

            doc.css('div.text h3 a').map do |link|
              puts link
              articles_url_maroco360 << "https://fr.le360.ma#{link['href']}"
            end
          end
          articles_url_maroco360 = articles_url_maroco360.reject(&:nil?)
          articles_url_maroco360_after_check = []
          articles_url_maroco360.map do |link|
            articles_url_maroco360_after_check << link unless Article.where(medium_id: media.id,
                                                                            url_article: link).present?
          end
          articles_url_maroco360_after_check.map do |link|
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
            new_article.category_article = article.css('#block-system-main > div > div.content-block > div.label-ttl.label-node > div:nth-child(1)').text
            new_article.title =  article.css('div.articles-holder h1').text
            author_exist_final = article.at('span.date-ttl u a').text
            author_exist = if author_exist_final.nil? || author_exist_final == ''
                             Author.where(['lower(name) like ? ', 'Maroco360 auteur'.downcase])
                           else
                             a = author_exist_final
                             Author.where(['lower(name) like ? ',
                                           a.downcase])
                           end

            new_author = Author.new
            if author_exist.count.zero?

              new_author.name = author_exist_final.nil? || author_exist_final == '' ? 'Maroco360 auteur' : author_exist_final
              new_author.medium_id = media.id
              new_author.save!
              new_article.author_id = new_author.id
            else
              new_article.author_id = author_exist.first.id

            end

            new_article.body = article.css('div.articles-holder p').inner_html
            new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
            date_published_treat = article.at('div.articles-holder span.date-ttl').text.split('le')
            date = date_published_treat[1]

            begin
              new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
            rescue ArgumentError
              puts "Error date here : #{date}"
              next
            end

            url_array = article.css('div.full-item div.holder img').map { |link| link['src'] }
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
