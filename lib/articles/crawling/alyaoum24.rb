# frozen_string_literal: true

module Articles
  # crawling files
  module Crawling
    # methode to get alyaoum24 articles
    class Alyaoum24
      class << self
        require_relative 'crawlingmethods'
        include Crawlingmethods
        include AbstractController::Rendering
        def get_articles_alyaoum24(url_media_array, media)
          articles_url_alyaoum24 = []
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

            doc.css('ul.listing-archive div.descriptionPostArchive a').map do |link|
              articles_url_alyaoum24 << link['href']
            end
          end
          articles_url_alyaoum24 = articles_url_alyaoum24.reject(&:nil?)

          articles_url_alyaoum24_after_check = []
          articles_url_alyaoum24.map do |link|
            articles_url_alyaoum24_after_check << link unless Article.where(medium_id: media.id,
                                                                            url_article: link).present?
          end

          articles_url_alyaoum24_after_check.map do |link|
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
            new_article.category_article = article.css('ul.breadcrumb li:nth(2)').text
            new_article.title =  article.css('div.infoSingle h1').text
            # new_article.author = article.css('div.article-head__author div em a').text
            
            auth = article.at('div.nameAuthor').text
            author_exist_final = auth.sub! 'بقلم/', ''
            author_exist = if author_exist_final.nil? || author_exist_final == ''
                             Author.where(['lower(name) like ? ', 'Alyaoum24 auteur'.downcase])
                           else
                             a = author_exist_final
                             Author.where(['lower(name) like ? ',a.downcase])
                           end
            if author_exist.count.zero?
              new_author = Author.new
              new_author.name = author_exist_final.nil? || author_exist_final == '' ? 'Alyaoum24 auteur' : author_exist_final
              new_author.medium_id = media.id
              new_author.save!
              new_article.author_id = new_author.id
            else
              new_article.author_id = author_exist.first.id

            end

            new_article.body = article.css('div.post_content p').inner_html
            new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
            date = article.at('span.timePost').text
            date_checked = change_translate_date(date)
            new_article.date_published = date_checked.to_datetime.change({ hour: 0, min: 0, sec: 0 })
            url_array =  article.css('div.article-image img.attachment-full.size-full.wp-post-image').map do |link|
              link['src']
            end
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
