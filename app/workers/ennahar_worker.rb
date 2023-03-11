# frozen_string_literal: true

class EnnaharWorker
  include Sidekiq::Worker
  include AbstractController::Rendering

  require 'nokogiri'
  require 'open-uri'
  require 'openssl'
  require 'logger'

  include Articles::Crawling::Crawlingmethods
  def perform
    @logger = Logger.new(Rails.root.join('log', 'ennahar.log'))
    @logger.info 'Starting Job & scraping ENNAHAR:'
    media = Medium.find_by_name('ENNAHAR')
    url_media_array = media.url_crawling.split(',')
    count = get_articles_ennahar(url_media_array, media)
    @logger.info "Job find :#{count} articles"
    @logger.info 'Job finished'
  end

  private

  def get_articles_ennahar(url_media_array, media)
    count = 0
    articles_url_ennahar = []
    last_dates = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.5'))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end

      doc.css('h2.card__title.x-middle a').map do |link|
        articles_url_ennahar << link['href']
      end
      doc.css('time').map do |date|
        last_dates << date['datetime']
      end
    end
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24) }
    articles_url_ennahar = articles_url_ennahar.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_ennahar_after_check = articles_url_ennahar - list_articles_url
    articles_url_ennahar_after_check.map do |link|
      begin
        article = Nokogiri::HTML(URI.open(link, 'User-Agent' => 'ruby/2.6.5'))
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
      new_article.category_article = article.css('div.sgb1__acat a').text
      new_article.title = article.css('h1.sgb1__attl').text
      author_exist = Author.where(['lower(name) like ? ',
                                   article.at('div.sgb1__aath a').text.downcase])
      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('div.sgb1__aath a').text
        new_author.medium_id = media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end
      new_article.body = article.css('div.artx').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      new_article.date_published = article.at('time[datetime]')['datetime'].to_datetime.change({ hour: 0, min: 0,
                                                                                                 sec: 0 }) + (1.0 / 24)
      url_array = article.css('figure.sgb1__afig div.sgb1__afmg img').map { |lin| lin['data-src'] }
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
