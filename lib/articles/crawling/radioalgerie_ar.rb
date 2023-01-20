# frozen_string_literal: true

module Articles
  # crawling files
  module Crawling
    # methode to get RadioalgerieAr articles
    class RadioalgerieAr
      class << self
        include AbstractController::Rendering
        def get_articles_radioalgerie(url_media_array, media)
          articles_url_radioalgerie_ar = []
          count = 0
          url_media_array.map do |url|
            begin
              doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.5', 'From' => 'foo@bar.invalid'), nil,
                                   'UTF-8')
            rescue OpenURI::HTTPError => e
              puts "Can't access #{url}"
              puts e.message
              puts
              next
            end

            doc.css('h3 a').map do |link|
              articles_url_radioalgerie_ar << "https://news.radioalgerie.dz#{link['href']}"
            end
          end
          articles_url_radioalgerie_ar = articles_url_radioalgerie_ar.reject(&:nil?)

          articles_url_radioalgerie_ar_after_check = []
          articles_url_radioalgerie_ar.map do |link|
            articles_url_radioalgerie_ar_after_check << link unless Article.where(medium_id: media.id,
                                                                                  url_article: link).present?
          end

          articles_url_radioalgerie_ar_after_check.map do |link|
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
            new_article.category_article = article.css('div.content div.field.field--name-field-categories.field--type-entity-reference.field--label-hidden.field__item a').text
            new_article.title = article.css('h1.title').text
            author_exist_final = 'Radioalgerie-AR auteur'
            author_exist = if author_exist_final.nil? || author_exist_final == ''
                             Author.where(['lower(name) like ? ', 'Radioalgerie-AR auteur'.downcase])
                           else
                             a = author_exist_final
                             Author.where(['lower(name) like ? ',
                                           a.downcase])
                           end

            new_author = Author.new
            if author_exist.count.zero?

              new_author.name = author_exist_final.nil? || author_exist_final == '' ? 'Radioalgerie-AR auteur' : author_exist_final
              new_author.medium_id = media.id
              new_author.save!
              new_article.author_id = new_author.id
            else
              new_article.author_id = author_exist.first.id

            end

            new_article.body = article.css('div.content p').inner_html
            new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
            date = article.at('div.content span.field.field--name-created.field--type-created.field--label-inline').text
            new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
            check_url_pic = article.at('div.col-lg-8 picture img')
            url_pic = check_url_pic.present? ? "https://news.radioalgerie.dz#{article.at('div.col-lg-8 picture img')&.attr('data-src')}" : nil
            new_article.url_image = url_pic
            begin
              new_article.image = Down.download(url_pic) if url_pic.present?
            rescue Down::Error => e
              puts "Can't download this image #{url_pic}"
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
