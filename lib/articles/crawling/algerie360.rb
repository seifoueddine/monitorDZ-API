# frozen_string_literal: true

module Articles
    # crawling files
    module Crawling
      # methode to get Algerie360 articles
      class Algerie360
        class << self
          include AbstractController::Rendering
  
          def get_articles_algerie360(url_media_array, media)
            articles_url_algerie360 = []
            count = 0
            last_dates = []
            url_media_array.map do |url|
              begin
                doc = Nokogiri::HTML(URI.open(url), nil, Encoding::UTF_8.to_s)
              rescue OpenURI::HTTPError => e
                puts "Can't access #{url}"
                puts e.message
                puts
                next
              end
              doc.css('div.entry__header h2 a').map do |link|
                articles_url_algerie360 << link['href']
              end
              doc.css('li.entry__meta-date').map do |date|
                date_with_time = date.text.split('à')[0]
                last_dates << date_with_time
              end
            end
            last_dates = last_dates.map { |d| change_date_autobip_aps(d) }
            last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
            # last_dates = last_dates.map(&:to_datetime.change({ hour: 0, min: 0, sec: 0 }))
            articles_url_algerie360 = articles_url_algerie360.reject(&:nil?)
            last_dates = last_dates.uniq
            last_articles = Article.where(medium_id: media.id).where(date_published: last_dates)
            list_articles_url = []
            last_articles.map do |article|
              list_articles_url << article.url_article
            end
            articles_url_algerie360_after_check = articles_url_algerie360 - list_articles_url
            articles_url_algerie360_after_check.map do |link|
              puts link
            end
            articles_url_algerie360_after_check.map do |link|
              begin
                article = Nokogiri::HTML(URI.open(link), nil, Encoding::UTF_8.to_s)
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
              new_article.category_article = 'algerie360.com'
              new_article.title = article.css('h1.single-post__entry-title.mt-0').text
              #  new_article.author = article.css('div.article-head__author div em a').text
              author_exist = if article.at('li.entry__meta-author a').nil?
                               Author.where(['lower(name) like ? ', 'Algérie360 auteur'.downcase])
                             else
                               Author.where(['lower(name) like ? ',
                                             article.at('li.entry__meta-author a').text.downcase])
                             end
    
              new_author = Author.new
              if author_exist.count.zero?
    
                new_author.name = article.at('li.entry__meta-author a').nil? ? 'Algérie360 auteur' : article.at('li.entry__meta-author a').text
                new_author.medium_id = media.id
                new_author.save!
                new_article.author_id = new_author.id
              else
                new_article.author_id = author_exist.first.id
    
              end
              new_article.body = article.css('article.entry.mb-0').inner_html
              new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
              new_article.body = new_article.body.gsub('(adsbygoogle=window.adsbygoogle||[]).push({});', '')
              date_with_time = article.css('li.entry__meta-date.pt-xl-1').text
              date_with_a = date_with_time.split('à')[0]
              date = date_with_a
              d = change_translate_date(date)
              new_article.date_published = d.to_datetime.change({ hour: 0, min: 0, sec: 0 })
              # new_article.date_published =
              url_array = article.css('div.entry__img-holder.px-2.px-md-0 img').map { |link| link['data-src'] }
              puts 'this is url  image'
              puts url_array
              puts 'this is url  image '
              new_article.url_image = url_array[0]
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
              # #tag_check_and_save(tags_array)if media.tag_status == true
            end
            count
          end
        end
      end
    end
  end
  