class BiladWorker
  include Sidekiq::Worker
  include AbstractController::Rendering
  require 'nokogiri'
  require 'open-uri'
  require 'openssl'
  require 'logger'


  def perform
    logger = Logger.new(Rails.root.join('log', 'worker.log'))
    logger.info "Starting job with arguments:"
    # media = Medium.find_by_name('ELBILAD')
    # url_media_array = media.url_crawling.split(',')
    # get_articles_bilad(url_media_array, media)
    puts"***********************************************************"
    puts"***********************************************************"
    puts"***********************************************************"
    puts"***********************************************************"
    puts"***********************************************************"
    puts"***********************************************************"
    puts"***********************************************************"
    puts"***********************************************************"
    puts"***********************************************************"
    puts"***********************************************************"
    puts"***********************************************************"
    puts"***********************************************************"
    logger.info "Job finished"
 end

 private 
 def get_articles_bilad(url_media_array, media)
    articles_url_bilad = []
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

      doc.css('article#categoryArticles h3 a').map do |link|
        articles_url_bilad << link['href']
      end
      doc.css('ul.list-news.int h1 a').map do |link|
        articles_url_bilad << link['href']
      end
    end
    articles_url_bilad = articles_url_bilad.reject(&:nil?)

    articles_url_biled_after_check = []
    articles_url_bilad.map do |link|
      articles_url_biled_after_check << link unless Article.where(medium_id: media.id,
                                                                  url_article: link).present?
    end

    articles_url_biled_after_check.map do |link|
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
      new_article.category_article = article.css('#content > header > ul.list-breadcrumbs > li:nth-child(2)').text
      new_article.title = article.css('#content > header > h1').text
      # new_article.author = article.css('div.article-head__author div em a').text
      author_exist = if article.at('ul.list-share li a span.strong').text == '0'
                       Author.where(['lower(name) like ? ', 'Bilad auteur'.downcase])
                     else
                       a = article.at('ul.list-share li a span.strong').text
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('ul.list-share li a span.strong').text == '0' ? 'Bilad auteur' : article.at('ul.list-share li a span.strong').text
        new_author.medium_id = media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('article.module-detail p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date_array = article.css('ul.list-share li a span').map(&:text)
      new_article.date_published = if date_array.to_s.include?('0')
                                     Date.today.to_datetime.change({ hour: 0, min: 0,
                                                                     sec: 0 })
                                   else
                                     date_published_array[1].split(',')[0].to_datetime.change({
                                                                                                hour: 0, min: 0, sec: 0
                                                                                              })
                                   end
      url_array = article.css('article.module-detail img').map { |link| link['data-src'] }
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
      #  tag_check_and_save(tags_array)if media.tag_status == true
      count += 1 if new_article.save
    end
    count
  end
end