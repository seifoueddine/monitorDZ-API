# frozen_string_literal: true

module Articles
  module Crawling
    class Ennahar
      USER_AGENT = 'ruby/2.6.5'

      class << self
        include AbstractController::Rendering

        def get_articles_ennahar(url_media_array, media)
          articles_urls = fetch_all_article_urls(url_media_array)
          existing_articles = fetch_existing_articles(media, articles_urls[:dates])

          articles_urls[:urls] -= existing_articles
          count_new_articles(articles_urls[:urls], media)
        end

        private

        def fetch_all_article_urls(url_media_array)
          articles_url_ennahar = []
          last_dates = []

          url_media_array.each do |url|
            doc = fetch_document(url)
            next unless doc

            articles_url_ennahar.concat(fetch_links_from_doc(doc))
            last_dates.concat(fetch_dates_from_doc(doc))
          end

          {
            urls: articles_url_ennahar.compact,
            dates: last_dates.map { |d| d.to_datetime.change(hour: 0, min: 0, sec: 0) + (1.0 / 24) }.uniq
          }
        end

        def fetch_document(url)
          Nokogiri::HTML(URI.open(url, 'User-Agent' => USER_AGENT))
        rescue OpenURI::HTTPError => e
          puts "Can't access #{url}: #{e.message}"
          nil
        end

        def fetch_links_from_doc(doc)
          doc.css('h2.card__title.x-middle a').map { |link| link['href'] }
        end

        def fetch_dates_from_doc(doc)
          doc.css('time').map { |date| date['datetime'] }
        end

        def fetch_existing_articles(media, dates)
          Article.where(medium_id: media.id, date_published: dates).pluck(:url_article)
        end

        def count_new_articles(articles_urls, media)
          count = 0
          articles_urls.each do |url|
            article_doc = fetch_document(url)
            next unless article_doc

            new_article = build_article(article_doc, url, media)
            count += 1 if new_article&.save
          end
          count
        end

        def build_article(doc, url, media)
          new_article = Article.new
          new_article.attributes = {
            url_article: url,
            medium_id: media.id,
            language: media.language,
            category_article: doc.css('div.sgb1__acat a').text,
            title: doc.css('h1.sgb1__attl').text,
            body: sanitize_body(doc.css('div.artx').inner_html),
            date_published: doc.at('time[datetime]')['datetime'].to_datetime.change(hour: 0, min: 0,
                                                                                    sec: 0) + (1.0 / 24),
            url_image: doc.css('figure.sgb1__afig div.sgb1__afmg img').map { |link| link['data-src'] }.first,
            status: 'pending'
          }

          assign_author(new_article, doc, media)
          assign_image(new_article)

          new_article
        end

        def assign_author(article, doc, media)
          author_name = doc.at('div.sgb1__aath a').text.downcase
          author = Author.find_or_initialize_by(name: author_name)
          if author.new_record?
            author.medium_id = media.id
            author.save!
          end
          article.author = author
        end

        def assign_image(article)
          return unless article.url_image

          begin
            article.image = Down.download(article.url_image)
          rescue Down::Error => e
            puts "Can't download this image #{article.url_image}: #{e.message}"
            article.image = nil
          end
        end

        def sanitize_body(body)
          body.gsub(/<img[^>]*>/, '')
        end
      end
    end
  end
end
