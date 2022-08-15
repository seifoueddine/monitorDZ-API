# frozen_string_literal: true

module Articles
    # crawling files
    module Crawling
      # methode to get Maghrebemergent articles
      class Maghrebemergent
        class << self
          include AbstractController::Rendering 

          def get_articles_maghrebemergent(url_media_array, media)
            articles_url_maghrebemergent = []
            count = 0
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
              doc.css('article a.elementor-post__thumbnail__link').map do |link|
                articles_url_maghrebemergent << link['href']
              end
              doc.css('article div div span.elementor-post-date').map do |date|
                last_dates << date.text
              end
            end
            last_dates = last_dates.map { |d| change_translate_date(d) }
            last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
            articles_url_maghrebemergent = articles_url_maghrebemergent.reject(&:nil?)
            last_dates = last_dates.uniq
            last_articles = Article.where(medium_id: media.id).where(date_published: last_dates)
            list_articles_url = []
            last_articles.map do |article|
              list_articles_url << article.url_article
            end
            articles_url_maghrebemergent_after_check = articles_url_maghrebemergent - list_articles_url
            articles_url_maghrebemergent_after_check.map do |link|
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
              new_article.category_article = article.at('div.elementor-widget-container ul li span span.elementor-post-info__terms-list a').text
              new_article.title = article.css('h1.elementor-heading-title.elementor-size-small').text
              # new_article.author = article.css('div.article-head__author div em a').text
    
              if article.at('div.elementor-widget-container ul li a span.elementor-icon-list-text elementor-post-info__item elementor-post-info__item--type-author').nil?
                author_exist = Author.where(['lower(name) like ? ', 'Maghrebemergent auteur'.downcase])
              else
                author_exist = Author.where(['lower(name) like ? ',
                                             article.at('div.elementor-widget-container ul li a span.elementor-icon-list-text elementor-post-info__item elementor-post-info__item--type-author').text.downcase])
              end
    
              new_author = Author.new
              if author_exist.count.zero?
    
                new_author.name = article.at('div.elementor-widget-container ul li a span.elementor-icon-list-text elementor-post-info__item elementor-post-info__item--type-author').nil? ? 'Maghrebemergent auteur' : article.at('div.elementor-widget-container ul li a span.elementor-icon-list-text elementor-post-info__item elementor-post-info__item--type-author').text
                new_author.medium_id = media.id
                new_author.save!
                new_article.author_id = new_author.id
              else
                new_article.author_id = author_exist.first.id
    
              end
              new_article.body = article.css('div.elementor-element.elementor-element-c93088c.elementor-widget.elementor-widget-theme-post-content').inner_html
              new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
              # date = article.at('p.text-capitalize span').text
              # date[','] = ''
              date = article.at('div.elementor-widget-container ul li a span.elementor-icon-list-text.elementor-post-info__item.elementor-post-info__item--type-date').text
              d = change_translate_date(date)
              new_article.date_published = d.to_datetime.change({ hour: 0, min: 0, sec: 0 })
              url_array = article.css('section div div div div div div.elementor-widget-wrap div.elementor-widget-container div.elementor-image img').map do |link|
                link['src']
              end
              new_article.url_image = url_array[1]
              begin
                new_article.image = Down.download(url_array[0]) if url_array[0].present?
              rescue Down::Error => e
                puts "Can't download this image #{url_array[0]}"
                puts e.message
                puts
                new_article.image = nil
              end
              # tags_array = article.css('ul.itemTags li').map(&:text)
              # new_article.media_tags = tags_array.join(',')
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