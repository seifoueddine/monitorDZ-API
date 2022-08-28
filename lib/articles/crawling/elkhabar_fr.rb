# frozen_string_literal: true

module Articles
  # crawling files
  module Crawling
    # methode to get ElkhabarFr articles
    class ElkhabarFr
      class << self
        include AbstractController::Rendering
        def get_articles_elkhabar_fr(url_media_array, media)
          count = 0
          articles_url_elkhabar_fr = []
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
            doc.css('h3.panel-title a').map do |link|
              articles_url_elkhabar_fr << "https://www.elkhabar.com#{link['href']}" unless link.css('i').present?
            end
            doc.css('time').map do |date|
              last_dates << date['datetime']
            end
          end

          last_dates = last_dates.map { |d| change_translate_date(d) }
          last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
          articles_url_elkhabar_fr = articles_url_elkhabar_fr.reject(&:nil?)
          articles_url_elkhabar_fr = articles_url_elkhabar_fr.uniq
          last_dates = last_dates.uniq
          last_articles = Article.where(medium_id: media.id).where(date_published: last_dates)
          list_articles_url = []
          last_articles.map do |article|
            list_articles_url << article.url_article
          end
          articles_url_elkhabar_fr_after_check = articles_url_elkhabar_fr - list_articles_url
          articles_url_elkhabar_fr_after_check.map do |link|
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
            new_article.title =  article.css('section div div div div div div h1.title').text if article.css('section div div div div div div h1.title').present?

            author_exist = if article.at('span.time-blog b').present?
                             Author.where(['lower(name) like ? ',
                                           article.at('span.time-blog b').text.downcase])

                           else
                             Author.where(['lower(name) like ? ', 'Elkhabar-fr auteur'.downcase])
                           end

            new_author = Author.new
            if author_exist.count.zero?

              new_author.name = article.at('span.time-blog b').present? ? article.at('span.time-blog b').text : 'Elkhabar-fr auteur'
              new_author.medium_id = media.id
              new_author.save!
              new_article.author_id = new_author.id
            else
              new_article.author_id = author_exist.first.id

            end
            new_article.body = article.css('div#article_body_content').inner_html
            new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
            date = article.at('time[datetime]')['datetime']
            new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
            if article.css('div#article_img img').present?
              url_array = article.css('div#article_img img').map { |link| "https://www.elkhabar.com#{link['src']}" }
            end
            begin
              new_article.image = Down.download(url_array[0]) if url_array.present?
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

        private

        # change_translate_date
        def change_translate_date(d)
          d.split.map do |m|
            case m.downcase
            when 'Janvier,'.downcase
              'January'
            when 'Février,'.downcase
              'February'
            when 'Mars,'.downcase
              'March'
            when 'Avril,'.downcase
              'April'
            when 'Mai,'.downcase
              'May'
            when 'Juin,'.downcase
              'June'
            when 'Juillet,'.downcase
              'July'
            when 'Octobre,'.downcase
              'October'
            when 'Novembre,'.downcase
              'November'
            when 'Décembre,'.downcase
              'December'
            when 'Septembre,'.downcase
              'September'
            when 'août,'.downcase
              'August'
            when 'Janvier'.downcase
              'January'
            when 'Février'.downcase
              'February'
            when 'Mars'.downcase
              'March'
            when 'Avril'.downcase
              'April'
            when 'Mai'.downcase
              'May'
            when 'Juin'.downcase
              'June'
            when 'Juillet'.downcase
              'July'
            when 'Octobre'.downcase
              'October'
            when 'Novembre'.downcase
              'November'
            when 'Décembre'.downcase
              'December'
            when 'Septembre'.downcase
              'September'
            when 'août'.downcase
              'August'

            when 'جانفي'.downcase
              'January'
            when 'فيفري'.downcase
              'February'
            when 'مارس'.downcase
              'March'
            when 'افريل'.downcase
              'April'
            when 'ماي'.downcase
              'May'
            when 'جوان'.downcase
              'June'
            when 'جويلية'.downcase
              'July'
            when 'جولية'.downcase
              'July'
            when 'أكتوبر'.downcase
              'October'
            when 'نوفمبر'.downcase
              'November'
            when 'ديسمبر'.downcase
              'December'
            when 'سبتمبر'.downcase
              'September'
            when 'اوت'.downcase
              'August'

            when 'جانفي،'.downcase
              'January'
            when 'فيفري،'.downcase
              'February'
            when 'مارس،'.downcase
              'March'
            when 'افريل،'.downcase
              'April'
            when 'ماي،'.downcase
              'May'
            when 'جوان،'.downcase
              'June'
            when 'جويلية،'.downcase
              'July'
            when 'جولية،'.downcase
              'July'
            when 'أكتوبر،'.downcase
              'October'
            when 'نوفمبر،'.downcase
              'November'
            when 'نونمبر،'.downcase
              'November'
            when 'ديسمبر،'.downcase
              'December'
            when 'سبتمبر،'.downcase
              'September'
            when 'اوت،'.downcase
              'August'

            when 'يناير'.downcase
              'January'
            when 'فبراير'.downcase
              'February'
            when 'ابريل'.downcase
              'April'
            when 'أبريل'.downcase
              'April'
            when 'مايو'.downcase
              'May'
            when 'يونيو'.downcase
              'June'
            when 'يوليو'.downcase
              'July'
            when 'أغسطس'.downcase
              'August'

            else
              m
            end
          end.join(' ')
        end
      end
    end
  end
end
