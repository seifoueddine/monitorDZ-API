# frozen_string_literal: true

module Articles
    # crawling files
    module Crawling
      # methode to get Algerie360 articles
      class Visaalgerie
        class << self
          include AbstractController::Rendering
  
          def get_articles_visaalgerie(url_media_array, media)
            articles_url_visadz = []
            count = 0
            last_dates = []
            url_media_array.map do |url|
              begin
                doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby'))
              rescue OpenURI::HTTPError => e
                puts "Can't access #{url}"
                puts e.message
                puts
                next
              end
              doc.css('div.mnar__list > ul.d-f.fxw-w li article.arcd > a').map do |link|
                articles_url_visadz << link['href']
              end
              doc.css('div.mnar__laar article.arcd.d-f.fxd-c.arcd--large > a.arcd__link').map do |link|
                articles_url_visadz << link['href']
              end
              doc.css('time').map do |date|
                last_dates << date['datetime']
              end
            end
            last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24) }
            articles_url_visadz = articles_url_visadz.reject(&:nil?)
            last_dates = last_dates.uniq
            last_articles = Article.where(medium_id: media.id).where(date_published: last_dates)
            list_articles_url = []
            last_articles.map do |article|
              list_articles_url << article.url_article
            end
            articles_url_visadz_after_check = articles_url_visadz - list_articles_url
            articles_url_visadz_after_check.map do |link|
              begin
                article = Nokogiri::HTML(URI.open(link, 'User-Agent' => 'ruby'))
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
              new_article.category_article = article.css('div.article__cat').text
              new_article.title = article.css('h1.article__title').text
              # new_article.author = article.css('div.article-head__author div em a').text
    
              if article.at('em.article__atnm').nil?
                author_exist = Author.where(['lower(name) like ? ', 'Visa Algérie auteur'.downcase])
              else
                author = article.at('em.article__atnm').text
                author_exist = Author.where(['lower(name) like ? ',
                                             author.downcase])
              end
    
              new_author = Author.new
              if author_exist.count.zero?
                author = article.at('em.article__atnm').text
                new_author.name = article.at('em.article__atnm').text.nil? ? 'Visa Algérie auteur' : author
                new_author.medium_id = media.id
                new_author.save!
                new_article.author_id = new_author.id
              else
                new_article.author_id = author_exist.first.id
    
              end
              new_article.body = article.css('p.article__desc').inner_html + article.css('div.article__cntn').inner_html
              new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
    
              date = article.at('time[datetime]')['datetime']
    
              new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24)
              # url_array = article.css('div.entry-media img').map {  |link| link['src'] }
              # url_image = url_array[0]
              # new_article.image = Down.download(url_array[0]) if url_array[0].present?
              # tags_array = article.css('div.entry-terms a').map(&:text)
              # new_article.media_tags = tags_array.join(',')
              new_article.status = 'pending'
              new_article.save!
              # tag_check_and_save(tags_array)
              count += 1 if new_article.save
            end
            count
          end
        end
      end
    end
  end
  