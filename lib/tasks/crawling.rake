# frozen_string_literal: true
require 'nokogiri'
require 'open-uri'
require 'openssl'
require_relative '../articles/crawling/crawlingmethods'
# require 'resolv-replace'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
namespace :crawling do
  desc 'carwling all media'
  task scraping: :environment do
    @articles_for_auto_tag = []
    Medium.all.each do |m|
      @media = m
      if m.url_crawling?
        url_media_array = m.url_crawling.split(',')
        puts url_media_array
        get_articles(url_media_array, m)
        Article.where(medium_id: m.id,
                      created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day).where.not(id: Article.group(:url_article).select('min(id)')).destroy_all

      else
        puts "crawling_status: 'No url_crawling', media: m.name, status: 'error'"
      end
      puts '*************@articles_for_auto_tag count******************'
      puts @articles_for_auto_tag.count
      puts '*************@articles_for_auto_tag count******************'
    end
    puts 'call auto tag'
    auto_tag(@articles_for_auto_tag)
    puts 'end auto tag'
  end

  def get_articles(url_media_array, media)
    puts "get article of #{media.name}"
    case media.name
    # when 'AUTOBIP'
    #   get_articles_autobip(url_media_array)
    when 'ELCHEROUK'
      get_articles_elcherouk(url_media_array)
    when 'ENNAHAR'
      get_articles_ennahar(url_media_array)
    when 'TSA'
      get_articles_tsa(url_media_array)
    when 'APS'
      get_articles_aps(url_media_array)
    when 'APS-AR'
      get_articles_aps_ar(url_media_array)
    when 'MAGHREBEMERGENT'
      get_articles_maghrebemergent(url_media_array)
    when 'ELBILAD'
      get_articles_bilad(url_media_array)
    #  when 'ELMOUDJAHID'
    #    get_articles_elmoudjahid(url_media_array)
     when 'ELMOUDJAHID-FR'
       get_articles_elmoudjahid_fr(url_media_array)
    when 'ELKHABAR'
      get_articles_elkhabar(url_media_array)
    when 'ELKHABAR-FR'
      get_articles_elkhabar_fr(url_media_array)
    # when 'ELIKHABARIA'
    #   get_articles_elikhbaria(url_media_array)
    when 'ALGERIECO'
      get_articles_algerieco(url_media_array)
    when 'CHIFFREAFFAIRE'
      get_articles_chiffreaffaire(url_media_array)
    when 'ELHIWAR'
      get_articles_elhiwar(url_media_array)
    when 'LE SOIR'
      get_articles_le_soir(url_media_array)
    when 'LIBERTE'
      get_articles_liberte(url_media_array)
    when 'LIBERTE-AR'
      get_articles_liberte_ar(url_media_array)
    when 'VISAALGERIE'
      get_articles_visadz(url_media_array)
    when 'SANTENEWS'
      get_articles_santenews(url_media_array)
    when 'ALGERIE360'
      get_articles_algerie360(url_media_array)
    # when 'ALGERIEPARTPLUS'
    #  get_articles_algerie_part(url_media_array)
    when '24H-DZ'
      get_articles_24hdz(url_media_array)
    when 'REPORTERS'
      get_articles_reporters(url_media_array)
    # when 'SHIHABPRESSE'
    #   get_articles_shihabpresse(url_media_array)
    when 'LEXPRESSIONDZ'
      get_articles_lexpressiondz(url_media_array)
    when 'LEMATIN-MA'
      get_articles_lematin(url_media_array)
    when 'ALMAGHREB24'
      get_articles_almaghreb24(url_media_array)
    when 'AUJOURDHUI-MA'
      get_articles_aujourdhui(url_media_array)
    when 'ELDJAZAIR-ELDJADIDA'
      get_articles_eldjazaireldjadida(url_media_array)
    when 'ALGERIE-PATRIOTIQUE'
      get_articles_algeriepatriotique(url_media_array)
    # when 'ELMAOUID'
    #   get_articles_elmaouid(url_media_array)
    when 'ALYAOUM24'
      get_articles_alyaoum24(url_media_array)
    when 'MAROCO360'
      get_articles_maroco360(url_media_array)
    when 'RADIOALGERIE-AR'
      get_articles_radioalgerie_ar(url_media_array)
    when 'RADIOALGERIE-FR'
      get_articles_radioalgerie_fr(url_media_array)
    when 'ELWATAN'
      get_articles_elwatan(url_media_array)
    else

      puts "crawling_status: 'No media name found!! ', status: 'error' "
    end
  end

  # start method to get autobip articles
  def get_articles_autobip(url_media_array)
    articles_url_autobip = []
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
      doc.css('div.post__text a').map do |link|
        articles_url_autobip << link['href'] if link['itemprop'] == 'url'
      end
      doc.css('div.post__meta.pt-2 time span').map do |date|
        last_dates << date.text
      end
    end

    last_dates = last_dates.map { |d| change_translate_date(d) }
    last_dates = last_dates.map(&:to_datetime)
    articles_url_autobip = articles_url_autobip.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_autobip_after_check = articles_url_autobip - list_articles_url
    articles_url_autobip_after_check.map do |link|
      begin
        article = Nokogiri::HTML(URI.open(URI.escape(link)))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{link}"
        puts e.message
        puts
        next
      end

      new_article = Article.new
      new_article.url_article = link
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('header.single-header a.cat-theme-bg').text
      new_article.title = article.css('h1.entry-title').text

      author_exist = Author.where(['lower(name) like ? ',
                                   article.at("//a[@itemprop = 'author']").text.downcase])
      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at("//a[@itemprop = 'author']").text
        new_author.medium_id = @media.id
        new_author.save!
      else

        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name
      end

      new_article.author_id = new_author.id
      new_article.body = article.css('div.pt-4.bp-2.entry-content.typography-copy').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')

      d = change_translate_date(article.at("//span[@itemprop = 'datePublished']").text)
      new_article.date_published = d.to_datetime
      url_array = article.css('.fotorama.mnmd-gallery-slider.mnmd-post-media-wide img').map { |link| link['src'] }
      new_article.url_image = url_array[0]
      begin
        new_article.image = Down.download(url_array[0]) if url_array[0].present?
      rescue Down::Error => e
        puts "Can't download this image #{url_array[0]}"
        puts e.message
        puts
        new_article.image = nil
      end
      tags_array = article.css('a.post-tag').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end

      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
      # tag_check_and_save(tags_array) if @media.tag_status == true
    end

    puts "json: { crawling_status_autobip: 'ok' }"
  end
  # end method to get autobip articles

  # start method to get elcherouk articles
  def get_articles_elcherouk(url_media_array)
    articles_url_cherouk = []
    count = 0
    url_media_array.map do |url|
      # doc = Nokogiri::HTML(URI.open(url))

      begin
        doc = Nokogiri::HTML(URI.open(url))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end

      doc.css('section h3 a').map do |link|
        articles_url_cherouk << link['href']
      end
    end
    articles_url_cherouk = articles_url_cherouk.reject(&:nil?)

    articles_url_cherouk_after_check = []
    articles_url_cherouk.map do |link|
      articles_url_cherouk_after_check << link unless Article.where(medium_id: @media.id, url_article: link).present?
    end

    articles_url_cherouk_after_check.map do |link|
      begin
        article = Nokogiri::HTML(URI.open(link))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{link}"
        puts e.message
        puts
        next
      rescue RuntimeError => e
        puts "Can't access #{link}"
        puts e.message
        puts
        next
      end
      new_article = Article.new
      new_article.url_article = link
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('article a.ech-bkbt._albk').text
      new_article.title = article.css('article h1.ech-sgmn__title.ech-sgmn__sdpd').text
      # new_article.author = article.css('div.article-head__author div em a').text

      author_exist = Author.where(['lower(name) like ? ',
                                   article.css('article div.d-f.fxd-c.ai-fs a').text.downcase])

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.css('article div.d-f.fxd-c.ai-fs a').text
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id
      end
      new_article.body = article.css('article div.ech-artx').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')

      date = DateTime.parse article.css('article.ech-sgmn__article time').text
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })

      unless article.at_css('article.ech-sgmn__article figure img').nil?
        url_array = article.at_css('article.ech-sgmn__article figure img').attr('data-src')
      end
      new_article.url_image = url_array

      # new_article.image = Down.download(url_array[0]) if url_array[0].present?

      begin
        new_article.image = Down.download(url_array) if url_array.present?
      rescue Down::ResponseError => e
        puts "Can't download this image #{url_array}"
        puts e.message
        puts
        new_article.image = nil
      end

      tags_array = article.css('ul.ech-sgmn__tgls.d-f.fxw-w.jc-fe a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
      if new_article.save
        count += 1

        # @articles_for_auto_tag.push(new_article)
      end
      tag_check_and_save(tags_array) if @media.tag_status == true
    end
    puts 'json: { crawling_count_elcherouk:  count  }'
  end
  # end method to get elcherouk articles

  # start method to get ennahar articles
  def get_articles_ennahar(url_media_array)
    articles_url_ennahar = []
    last_dates = []
    url_media_array.map do |url|
      # doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.10'))

      begin
        doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.10'))
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
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_ennahar_after_check = articles_url_ennahar - list_articles_url
    articles_url_ennahar_after_check.map do |link|
      begin
        article = Nokogiri::HTML(URI.open(link, 'User-Agent' => 'ruby/2.6.10'))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{link}"
        puts e.message
        puts
        next
      end

      new_article = Article.new
      new_article.url_article = link
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('div.sgb1__acat a').text
      new_article.title = article.css('h1.sgb1__attl').text
      # new_article.author = article.css('div.article-head__author div em a').text

      author_exist = Author.where(['lower(name) like ? ',
                                   article.at('div.sgb1__aath a').text.downcase])

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('div.sgb1__aath a').text
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end
      new_article.body = article.css('div.artx').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      new_article.date_published = article.at('time[datetime]')['datetime'].to_datetime.change({ hour: 0, min: 0,
                                                                                                 sec: 0 }) + (1.0 / 24)
      url_array = article.css('figure.sgb1__afig div.sgb1__afmg img').map { |link| link['data-src'] }
      new_article.url_image = url_array[0]
      begin
        new_article.image = Down.download(url_array[0]) if url_array[0].present?
      rescue Down::Error => e
        puts "Can't download this image #{url_array[0]}"
        puts e.message
        puts
        new_article.image = nil
      end
      # tags_array = article.css('div.article-core__tags a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end

      # @articles_for_auto_tag.push(new_article) if new_article.save
      # #tag_check_and_save(tags_array)
    end
    puts "json: { crawling_status_ennahar: 'ok' }"
  end
  # end method to get ennahar articles

  # start method to get TSA articles
  def get_articles_tsa(url_media_array)
    articles_url_tsafr = []
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
      doc.css('h1.article-preview__title.title-middle.transition a').map do |link|
        articles_url_tsafr << link['href'] # if link['class'] == 'main_article'
      end
      # doc.css('ul.article-horiz__meta li time').map do |date|
      # last_dates << date.text
      #   end
    end
    articles_url_tsafr = articles_url_tsafr.reject(&:nil?)
    # last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_tsa_after_check = articles_url_tsafr - list_articles_url
    articles_url_tsa_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('div.article__meta a.article__meta-category').nil? ? article.css('div.anarticle__meta div a.article-meta__category').text : article.css('div.article__meta a.article__meta-category').text
      new_article.title = article.css('div.article__title').nil? ? article.css('h2.anarticle__title span').text : article.css('div.article__title').text
      # new_article.author = article.css('div.article-head__author div em a').text

      author_exist = if article.at('span.article__meta-author').nil?
                       Author.where(['lower(name) like ? ', 'TSA auteur'.downcase])
                     else
                       Author.where(['lower(name) like ? ', article.at('span.article__meta-author').text.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('span.article__meta-author').nil? ? 'TSA auteur' : article.at('span.article__meta-author').text
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end
      new_article.body = article.css('div.article__content').nil? ? article.css('div.anarticle__content').inner_html : article.css('div.article__content').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date = article.at('time[datetime]').nil? ? Date.today : article.at('time[datetime]')['datetime']
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24)
      url_array = article.css('body > div.article-section > div > div.article-section__main.wrap__main > article > div.full-article__featured-image > img').map do |link|
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
      # tags_array = article.css('div.article-core__tags a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end

      # #tag_check_and_save(tags_array)
    end
    puts "json: { crawling_status_tsa: 'ok' }"
  end
  # end method to get TSA articles

  # start method to get APS articles
  def get_articles_aps(url_media_array)
    articles_url_aps = []
    last_dates = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby', read_timeout: 3600))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      rescue Net::OpenTimeout => e
        puts "TRY #{url}/n ERROR: timed out while trying to connect #{url}"
        puts e.message
        puts
        next
      rescue Errno::ECONNRESET => e
        puts "TRY #{url}/n ERROR: timed out while trying to connect #{url}"
        puts e.message
        puts
        next
      end
      doc.css('#itemListLeading h3 a').map do |link|
        articles_url_aps << "http://www.aps.dz#{link['href']}" # if link['class'] == 'main_article'
      end
      doc.css('span.catItemDateCreated').map do |date|
        last_dates << date.text
      end
    end
    last_dates = last_dates.map { |d| change_translate_date(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
    # last_dates = last_dates.map(&:to_datetime.change({ hour: 0, min: 0, sec: 0 }))
    articles_url_aps = articles_url_aps.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_aps_after_check = articles_url_aps - list_articles_url
    articles_url_aps_after_check.map do |link|
      begin
        article = Nokogiri::HTML(URI.open(link, read_timeout: 3600))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{link}"
        puts e.message
        puts
        next
      rescue Net::OpenTimeout => e
        puts "TRY #{link}/n ERROR: timed out while trying to connect #{link}"
        puts e.message
        puts
        next
      rescue Errno::ECONNRESET => e
        puts "TRY #{link}/n ERROR: timed out while trying to connect #{link}"
        puts e.message
        puts
        next
      end
      new_article = Article.new
      new_article.url_article = link
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('nav.wrap.t3-navhelper > div > ol > li a').text == '' ? article.css('body > div.t3-wrapper > nav.wrap.t3-navhelper > div > ol > li:nth-child(2) > span').text : article.css('nav.wrap.t3-navhelper > div > ol > li a').text
      new_article.title = article.css('div.itemHeader h2.itemTitle').text
      # new_article.author = article.css('div.article-head__author div em a').text

      author_exist = if article.at('span.article__meta-author').nil?
                       Author.where(['lower(name) like ? ', 'APS auteur'.downcase])
                     else
                       Author.where(['lower(name) like ? ',
                                     article.at('span.article__meta-author').text.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('span.article__meta-author').nil? ? 'APS auteur' : article.at('span.article__meta-author').text
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end
      new_article.body = article.css('div.itemIntroText strong').inner_html + article.css('div.itemFullText').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date = article.css('span.itemDateCreated').text
      date['Publié le : '] = ''
      d = change_translate_date(date)
      new_article.date_published = d.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      # new_article.date_published =
      url_array = article.css('div.itemImageBlock span.itemImage img').map { |link| "http://www.aps.dz#{link['src']}" }
      new_article.url_image = url_array[0]
      begin
        new_article.image = Down.download(url_array[0]) if url_array[0].present?
      rescue Down::Error => e
        puts "Can't download this image #{url_array[0]}"
        puts e.message
        puts
        new_article.image = nil
      end
      tags_array = article.css('ul.itemTags li').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end

      # tag_check_and_save(tags_array)if @media.tag_status == true
    end
    puts "json: { crawling_status_aps: 'ok' }"
  end
  # end method to get APS articles

  # start method to get APS-ar articles
  def get_articles_aps_ar(url_media_array)
    articles_url_APSar = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.10', 'From' => 'foo@bar.invalid'), nil, 'UTF-8')
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      rescue Net::OpenTimeout => e
        puts "TRY #{url}/n ERROR: timed out while trying to connect #{url}"
        puts e.message
        puts
        next
      rescue Errno::ECONNRESET => e
        puts "TRY #{url}/n ERROR: timed out while trying to connect #{url}"
        puts e.message
        puts
        next
      end

      doc.css('div.itemList div.catItemHeader h3.catItemTitle a').map do |link|
        articles_url_APSar << "https://www.aps.dz#{link['href']}"
      end
    end
    articles_url_APSar = articles_url_APSar.reject(&:nil?)

    articles_url_APSar_after_check = []
    articles_url_APSar.map do |link|
      articles_url_APSar_after_check << link unless Article.where(medium_id: @media.id, url_article: link).present?
    end
    articles_url_APSar_after_check.map do |link|
    end

    articles_url_APSar_after_check.map do |link|
      begin
        article = Nokogiri::HTML(open(link, 'User-Agent' => 'ruby'))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{link}"
        puts e.message
        puts
        next
      rescue Net::OpenTimeout => e
        puts "TRY #{link}/n ERROR: timed out while trying to connect #{link}"
        puts e.message
        puts
        next
      rescue Errno::ECONNRESET => e
        puts "TRY #{link}/n ERROR: timed out while trying to connect #{link}"
        puts e.message
        puts
        next
      end
      new_article = Article.new
      new_article.url_article = link
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('div.itemToolbar span a').text
      new_article.title =  article.css('div.itemHeader h2.itemTitle').text
      # new_article.author = article.css('div.article-head__author div em a').text
      author_exist_final = 'APSar auteur'
      author_exist = if author_exist_final.nil? || author_exist_final == ''
                       Author.where(['lower(name) like ? ', 'APSar auteur'.downcase])
                     else
                       a = author_exist_final
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = author_exist_final.nil? || author_exist_final == '' ? 'APSar auteur' : author_exist_final
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('div.itemIntroText.col-xs-hidden p').inner_html + article.css('div.itemFullText p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date_published_treat = article.at('div.itemToolbar span.itemDateCreated').text.split(',')
      date = date_published_treat[1]

      date_checked = change_translate_date(date)
      new_article.date_published = date_checked.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array =  article.css('span.itemImage img').map { |link| "https://www.aps.dz#{link['src']}" }
      # tags_array = article.css('ul.itemTags li a').map(&:text)
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
    end
    puts "json: { crawling_status_APSar: 'ok' }"
  end
  # end method to get APS-ar articles

  # start method to get le soir articles
  def get_articles_le_soir(url_media_array)
    articles_url_le_soir = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end
      doc.css('div.categorie-liste-details a:nth-child(2)').map do |link|
        articles_url_le_soir << "https://www.lesoirdalgerie.com#{link['href']}"
      end
    end
    articles_url_le_soir = articles_url_le_soir.reject(&:nil?)

    articles_url_le_soir_after_check = []
    articles_url_le_soir.map do |link|
      articles_url_le_soir_after_check << link unless Article.where(medium_id: @media.id, url_article: link).present?
    end

    articles_url_le_soir_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('body > section.breadcrumb > span:nth-child(3) > a').text
      new_article.title = "#{article.css('div.title h1 span.grey-text').text}, #{article.css('div.title h1 span.black-text').text}"
      # new_article.author = article.css('div.article-head__author div em a').text
      anchor = []
      article.css('div.published').each do |header|
        anchor << header.text
      end
      author_exist = if article.css('div.published a').nil?
                       Author.where(['lower(name) like ? ', 'Le soir auteur'.downcase])
                     else
                       Author.where(['lower(name) like ? ',
                                     article.css('div.published a').text.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.css('div.published a').nil? ? 'Le soir auteur' : article.css('div.published a').text
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else

        new_article.author_id = author_exist.first.id
      end

      new_article.body = article.css('div.text p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date_published = article.at('/html/body/section[3]/div/div[2]/div/div[2]/text()[2]').text
      first = date_published.split(',')[0]
      date = first.sub! 'le', ''
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })

      url_array = article.css('div.article-content div.article-details div.picture img')
                         .map { |link| "https://www.lesoirdalgerie.com#{link['data-original']}" }
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
      # #tag_check_and_save(tags_array)if @media.tag_status == true
    end
    puts "json: { crawling_status_le_soir: 'ok' }"
  end
  # end method to get le soir articles

  # start method to get _liberte articles
  def get_articles_liberte(url_media_array)
    articles_url_liberte = []
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
      doc.css('div.right-side a.title').map do |link|
        articles_url_liberte << "https://www.liberte-algerie.com#{link['href']}" # if link['class'] == 'main_article'
      end
      doc.css('div.right-side div.date-heure span.date').map do |date|
        last_dates << date.text
      end
    end
    last_dates = last_dates.map { |d| change_translate_date(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
    # last_dates = last_dates.map(&:to_datetime.change({ hour: 0, min: 0, sec: 0 }))
    articles_url_liberte = articles_url_liberte.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_liberte_after_check = articles_url_liberte - list_articles_url
    articles_url_liberte_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('div#global div h3 strong').text
      new_article.title = "#{article.css('div#main-post span h4').text} : #{article.css('div#main-post span h1').text}"
      #  new_article.author = article.css('div.article-head__author div em a').text
      author_exist = if article.at('div#side-post div div p a').nil?
                       Author.where(['lower(name) like ? ', 'Liberté auteur'.downcase])
                     else
                       Author.where(['lower(name) like ? ',
                                     article.at('div#side-post div div p a').text.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('div#side-post div div p a').nil? ? 'Liberté auteur' : article.at('div#side-post div div p a').text
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end
      new_article.body = article.css('div#text_core').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date = article.css('div#side-post div div.date-heure span')[0].text.delete(' ')
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('div.media img.post-image').map { |link| link['src'] }
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
      # #tag_check_and_save(tags_array)if @media.tag_status == true
    end
    puts "json: { crawling_status_liberte: 'ok' }"
  end
  # end method to get _liberte articles

  # start method to get _liberte_ar articles
  def get_articles_liberte_ar(url_media_array)
    articles_url_liberte_ar = []
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
      doc.css('div.right-side a.title').map do |link|
        articles_url_liberte_ar << "https://www.liberte-algerie.com#{link['href']}" # if link['class'] == 'main_article'
      end
      doc.css('div.right-side div.date-heure span.date').map do |date|
        last_dates << date.text
      end
    end
    last_dates = last_dates.map { |d| change_translate_date(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
    # last_dates = last_dates.map(&:to_datetime.change({ hour: 0, min: 0, sec: 0 }))
    articles_url_liberte_ar = articles_url_liberte_ar.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_liberte_ar_after_check = articles_url_liberte_ar - list_articles_url
    articles_url_liberte_ar_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('div#global div h3 strong').text
      new_article.title = "#{article.css('div#main-post span h4').text} : #{article.css('div#main-post span h1').text}"
      #  new_article.author = article.css('div.article-head__author div em a').text
      author_exist = if article.at('div#side-post div div p a').nil?
                       Author.where(['lower(name) like ? ', 'Liberté-ar auteur'.downcase])
                     else
                       Author.where(['lower(name) like ? ',
                                     article.at('div#side-post div div p a').text.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('div#side-post div div p a').nil? ? 'Liberté-ar auteur' : article.at('div#side-post div div p a').text
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end
      new_article.body = article.css('div#text_core').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date = article.css('div#side-post div div.date-heure span')[0].text.delete(' ')

      # d = change_translate_date(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      # new_article.date_published =
      url_array = article.css('div.media img.post-image').map { |link| link['src'] }
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
      # tag_check_and_save(tags_array)if @media.tag_status == true
    end
    puts "json: { crawling_status_liberte_ar: 'ok' }"
  end
  # end method to get _liberte_ar articles

  # start method to get 24hdz articles
  def get_articles_24hdz(url_media_array)
    articles_url_24hdz = []

    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end
      doc.css('h3.entry-title.td-module-title a').map do |link|
        articles_url_24hdz << link['href']
      end
    end

    articles_url_24hdz = articles_url_24hdz.reject(&:nil?)

    articles_url_24hdz_after_check = []
    articles_url_24hdz.map do |link|
      articles_url_24hdz_after_check << link unless Article.where(medium_id: @media.id, url_article: link).present?
    end

    articles_url_24hdz_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('span a.entry-crumb').text
      new_article.title = article.css('header.td-post-title').text
      #  new_article.author = article.css('div.article-head__author div em a').text
      author_exist = if article.at('div.td-post-author-name').nil?
                       Author.where(['lower(name) like ? ', '24h-dz auteur'.downcase])
                     else
                       Author.where(['lower(name) like ? ',
                                     article.at('div.td-post-author-name').text.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('div.td-post-author-name').nil? ? '24h-dz auteur' : article.at('div.td-post-author-name').text
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end
      new_article.body = article.css('div.td-post-content').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')

      # d = change_translate_date(date)
      new_article.date_published = article.at('time[datetime]')['datetime'].to_datetime.change({ hour: 0, min: 0,
                                                                                                 sec: 0 }) + (1.0 / 24)
      # new_article.date_published =
      url_array = article.css('div.td-post-featured-image img').map { |link| link['src'] }
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
      # #tag_check_and_save(tags_array)if @media.tag_status == true
    end
    puts "json: { crawling_status_24hdz: 'ok' }"
  end
  # end method to get 24hdz articles

  # start method to get reporters articles
  def get_articles_reporters(url_media_array)
    articles_url_reporters = []

    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end
      doc.css('h3.entry-title.td-module-title a').map do |link|
        articles_url_reporters << link['href']
      end
    end

    articles_url_reporters = articles_url_reporters.reject(&:nil?)

    articles_url_reporters_after_check = []
    articles_url_reporters.map do |link|
      articles_url_reporters_after_check << link unless Article.where(medium_id: @media.id, url_article: link).present?
    end

    articles_url_reporters_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('header.td-post-title ul.td-category a').text
      new_article.title = article.css('h1.entry-title').text
      #  new_article.author = article.css('div.article-head__author div em a').text
      author_exist = if article.at('div.td-post-author-name').nil?
                       Author.where(['lower(name) like ? ', 'reporters auteur'.downcase])
                     else
                       Author.where(['lower(name) like ? ',
                                     article.at('div.td-post-author-name').text.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('div.td-post-author-name').nil? ? 'reporters auteur' : article.at('div.td-post-author-name').text
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end
      new_article.body = article.css('div.td-post-content').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')

      # d = change_translate_date(date)
      new_article.date_published = article.at('time[datetime]')['datetime'].to_datetime.change({ hour: 0, min: 0,
                                                                                                 sec: 0 }) + (1.0 / 24)
      # new_article.date_published =
      url_array = article.css('div.td-post-featured-image img').map { |link| link['src'] }
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
      # #tag_check_and_save(tags_array)if @media.tag_status == true
    end
    puts "json: { crawling_status_reporteur: 'ok' }"
  end
  # end method to get reporters articles

  # start method to get algerie360
  def get_articles_algerie360(url_media_array)
    articles_url_algerie360 = []
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
    last_dates = last_dates.map { |d| change_translate_date(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
    # last_dates = last_dates.map(&:to_datetime.change({ hour: 0, min: 0, sec: 0 }))
    articles_url_algerie360 = articles_url_algerie360.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_algerie360_after_check = articles_url_algerie360 - list_articles_url
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
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
        new_author.medium_id = @media.id
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end

      # #tag_check_and_save(tags_array)if @media.tag_status == true
    end
    puts "json: { crawling_status_algerie360: 'ok' }"
  end
  # end method to get algerie360

  # start method to get algeriepart
  def get_articles_algerie_part(url_media_array)
    articles_url_algeriepart = []
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
      doc.css('div.tdb_module_loop.td_module_wrap.td-animation-stack div.td-module-meta-info h3.entry-title.td-module-title a').map do |link|
        articles_url_algeriepart << link['href']
      end
      doc.css('time').map do |date|
        last_dates << date['datetime']
      end
    end
    last_dates = last_dates.map { |d| change_translate_date(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
    # last_dates = last_dates.map(&:to_datetime.change({ hour: 0, min: 0, sec: 0 }))
    articles_url_algeriepart = articles_url_algeriepart.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_algeriepart_after_check = articles_url_algeriepart - list_articles_url
    articles_url_algeriepart_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      categories = []
      article.css('div.tdb-entry-category').map do |category|
        categories << category.text
      end
      new_article.category_article = categories.join(',')
      new_article.title = article.css('h1.tdb-title-text').text
      new_author = Author.new
      author = Author.where(['lower(name) like ? ', 'AlgériePart auteur'.downcase])
      if author.present?
        new_article.author_id = author.first.id

      else

        new_author.name = 'AlgériePart auteur'
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      end

      new_article.body = article.css('div.tdb-block-inner.td-fix-index').inner_html
      date = article.css('div.vc_column-inner div div div.tdb-block-inner.td-fix-index time').text
      d = change_translate_date(date)
      new_article.date_published = d.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      new_article.url_image = nil
      new_article.status = 'pending'

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end

      # #tag_check_and_save(tags_array)if @media.tag_status == true
    end
    puts "json: { crawling_status_algeriepart: 'ok' }"
  end
  # end method to get algeriepart

  # start method to get bilad articles
  def get_articles_bilad(url_media_array)
    articles_url_bilad = []
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
      articles_url_biled_after_check << link unless Article.where(medium_id: @media.id, url_article: link).present?
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
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
        new_author.medium_id = @media.id
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
      new_article.status = 'pending'

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
    end
    puts "json: { crawling_status_bilad: 'ok' }"
  end
  # end method to get bilad articles
  #
  #

  # start method to get maghrebemergent articles
  def get_articles_maghrebemergent(url_media_array)
    articles_url_maghrebemergent = []
    last_dates = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      rescue SocketError => e
        puts "Error: #{e.message}"
        puts "Skipping #{url}"
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
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
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
        new_author.medium_id = @media.id
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end

      # #tag_check_and_save(tags_array)
    end
    puts "json: { crawling_status_aps: 'ok' }"
  end
  # end method to get maghrebemergent articles
  #

  # start method to get elmoudjahid_fr articles
  def get_articles_elmoudjahid_fr(url_media_array)
    articles_url_elmoudjahid = []

    count = 0
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.10'))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end
      doc.css('article ul.list-category h2 a').map do |link|
        articles_url_elmoudjahid << link['href'] # if link['class'] == 'main_article'
      end
    end
    articles_url_elmoudjahid = articles_url_elmoudjahid.reject(&:nil?)

    articles_url_elmoudjahid_after_check = []
    articles_url_elmoudjahid.map do |link|
      articles_url_elmoudjahid_after_check << link unless Article.where(medium_id: @media.id,
                                                                        url_article: link).present?
    end
    articles_url_elmoudjahid_after_check.map do |link|
      begin
        article = Nokogiri::HTML(URI.open(link, 'User-Agent' => 'ruby/2.6.10'))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{link}"
        puts e.message
        puts
        next
      end
      new_article = Article.new
      new_article.url_article = link
      new_article.medium_id = @media.id
      new_article.language = @media.language
      category = article.css('article.module-article ul.list-details li.text-uppercase a').text
      new_article.category_article = category
      new_article.title = article.css('header.heading-article h1').text

      author_exist = Author.where(['lower(name) like ? ', 'Elmoudjahid-fr auteur'.downcase])

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = 'Elmoudjahid-fr auteur'
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id
      end
      new_article.body = article.css('article.module-article p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      get_date = article.at('#content > div:nth-child(4) > article > aside > ul > li.text-uppercase > ul > li:nth-child(2)').text

      new_article.date_published = get_date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('article.module-article figure img').map { |image_link| image_link['data-src'] }
      substring_to_remove = 'load_'
      result_string = url_array[0].gsub(substring_to_remove, '')
      new_article.url_image = result_string
      begin
        new_article.image = Down.download(result_string) if url_array.present?
      rescue Down::Error => e
        puts "Can't download this image #{result_string}"
        puts e.message
        puts
        new_article.image = nil
      end
      new_article.status = 'pending'

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end

      count += 1 if new_article.save
      # #tag_check_and_save(tags_array)
    end
    puts 'json: { crawling_count_elmoudjahid: count }'
  end
  # start method to get elmoudjahid_fr articles
  #

  def get_articles_elmoudjahid(url_media_array)
    articles_url_elmoudjahid = []
    articles_url_elmoudjahid6 = []
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
      doc.css('#main > div.UnCat > ul > li:nth-child(1) > h1 > a').map do |link|
        articles_url_elmoudjahid << link['href'] # if link['class'] == 'main_article'
      end
      doc.css('#main > div.UnCat > div > ul > li > a').map do |link|
        articles_url_elmoudjahid6 << link['href'] # if link['class'] == 'main_article'
      end
      doc.css('#main > div.CBox > div > h4 > a').map do |link|
        articles_url_elmoudjahid << link['href'] # if link['class'] == 'main_article'
      end
      first_date = doc.at('li p span').text if doc.at('li p')['style'] == 'width: 520px;'
      last_dates << first_date.split(':')[0].to_datetime
      doc.css('div.ModliArtilUne span').map do |date|
        last_dates << date.text.split(':')[0].to_datetime
      end
    end
    # last_dates = last_dates.map { |d| change_translate_date(d) }
    # last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 })}
    articles_url_elmoudjahid = articles_url_elmoudjahid.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)

    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_elmoudjahid_after_check = articles_url_elmoudjahid - list_articles_url

    articles_url_elmoudjahid6.map do |article|
      if Article.where(medium_id: @media.id).where(url_article: article)[0].nil?
        articles_url_elmoudjahid_after_check << article
      end
    end
    articles_url_elmoudjahid_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      category = article.css('#contenu > div.path > ul > li:nth-child(3)').text
      category['>'] = ''
      new_article.category_article = category
      new_article.title = article.css('div.At h1 a').text

      author_exist = if article.at('p.text-muted').nil?
                       Author.where(['lower(name) like ? ', 'Elmoudjahid auteur'.downcase])
                     else
                       Author.where(['lower(name) like ? ',
                                     article.at('p.text-muted').text.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('p.text-muted').nil? ? 'Elmoudjahid auteur' : article.at('p.text-muted').text
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id
      end
      new_article.body = article.css('#text_article').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      new_article.date_published = article.css('#contenu > div.At > span').text.split(':')[1].to_datetime.change({
                                                                                                                   hour: 0, min: 0, sec: 0
                                                                                                                 })
      url_array = article.css('#articlecontent > div.TxArtcile > div.ImgCapt > img').map { |link| link['src'] }
      new_article.url_image = url_array[0]
      begin
        new_article.image = Down.download(url_array[0]) if url_array.present?
      rescue Down::Error => e
        puts "Can't download this image #{url_array[0]}"
        puts e.message
        puts
        new_article.image = nil
      end
      new_article.status = 'pending'

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end

      # #tag_check_and_save(tags_array)
    end
    puts "json: { crawling_status_aps: 'ok' }"
  end
  # end method to get elmoudjahid_fr articles

  # start method to get elkhabar articles
  def get_articles_elkhabar(url_media_array)
    count = 0
    articles_url_elkhabar = []
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
      doc.css('h2.panel-title a').map do |link|
        articles_url_elkhabar << "https://www.elkhabar.com#{link['href']}" unless link.css('i').present?
      end
      doc.css('time').map do |date|
        last_dates << date['datetime']
      end
    end

    last_dates = last_dates.map { |d| change_translate_date(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
    articles_url_elkhabar = articles_url_elkhabar.reject(&:nil?)
    articles_url_elkhabar = articles_url_elkhabar.uniq
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_elkhabar_after_check = articles_url_elkhabar - list_articles_url
    articles_url_elkhabar_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      if article.css('section div div div div.categ-title a span').present?
        new_article.category_article = article.css('section div div div div.categ-title a span').text
      end
    new_article.title = article.css('section div div div h1.title').text if article.css('section div div div h1.title').present?
      # new_article.author = article.css('div.article-head__author div em a').text

      author_exist = if article.at('span.time-blog b').present?
                       Author.where(['lower(name) like ? ',
                                     article.at('span.time-blog b').text.downcase])

                     else
                       Author.where(['lower(name) like ? ', 'Elkhabar auteur'.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('span.time-blog b').present? ? article.at('span.time-blog b').text : 'Elkhabar auteur'
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end
      new_article.body = article.css('div#article_body_content').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('time[datetime]')['datetime']
      # d = change_translate_date(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      if article.css('div#article_img img').present?
        url_array = article.css('div#article_img img').map { |link_image| "https://www.elkhabar.com#{link_image['src']}" }
      end
      # url_image = url_array[0]
      begin
        new_article.image = Down.download(url_array[0]) if url_array.present?
      rescue Down::Error => e
        puts "Can't download this image #{url_array[0]}"
        puts e.message
        puts
        new_article.image = nil
      end
      tags_array = article.css('div#article_tags_title').map(&:text) if article.css('div#article_tags_title').present?
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end

      count += 1 if new_article.save
      # #tag_check_and_save(tags_array) if @media.tag_status == true
    end
    # render json: { crawling_status_elkhabar: count }
    puts "json: { crawling_status_elkhabar: 'ok' }"
  end
  # end method to get elkhabar articles
  #

  # start method to get elkhabar_fr articles
  def get_articles_elkhabar_fr(url_media_array)
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
      doc.css('h2.panel-title a').map do |link|
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
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      #if article.css('section div div div div a span').present?
        new_article.category_article = "Français"
      #end
      new_article.title = article.css('section div div div h1.title').text if article.css('section div div div h1.title').present?
      # new_article.author = article.css('div.article-head__author div em a').text

      author_exist = if article.at('span.time-blog b').present?
                       Author.where(['lower(name) like ? ',
                                     article.at('span.time-blog b').text.downcase])

                     else
                       Author.where(['lower(name) like ? ', 'Elkhabar-fr auteur'.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('span.time-blog b').present? ? article.at('span.time-blog b').text : 'Elkhabar-fr auteur'
        new_author.medium_id = @media.id
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
        url_array = article.css('div#article_img img').map { |link_image| "https://www.elkhabar.com#{link_image['src']}" }
      end
      # url_image = url_array[0]
      begin
        new_article.image = Down.download(url_array[0]) if url_array.present?
      rescue Down::Error => e
        puts "Can't download this image #{url_array[0]}"
        puts e.message
        puts
        new_article.image = nil
      end
      # tags_array = article.css('div#article_tags_title').map(&:text) if article.css('div#article_tags_title').present?
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end

      count += 1 if new_article.save
      # #tag_check_and_save(tags_array) if @media.tag_status == true
    end
    puts "json: { crawling_status_elkhabar_fr: 'ok' }"
  end
  # end method to get elkhabar_fr articles
  #

  # start method to get elikhbaria articles
  def get_articles_elikhbaria(url_media_array)
    articles_url_elikhbaria = []
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
      doc.css('div.col-sm-8 div.listing > article > div > h2 > a').map do |link|
        articles_url_elikhbaria << link['href'] # if link['class'] == 'main_article'
      end
      doc.css('time').map do |date|
        last_dates << date['datetime']
      end
    end
    # last_dates = last_dates.map { |d| change_translate_date(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24) }
    articles_url_elikhbaria = articles_url_elikhbaria.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_elikhbaria_after_check = articles_url_elikhbaria - list_articles_url
    articles_url_elikhbaria_after_check.map do |link|
      #  article = Nokogiri::HTML(URI.open(link))
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('nav > div > ul > li:nth-child(4)').text
      new_article.title = article.css('div.post-header.post-tp-1-header > h1 > span').text
      # new_article.author = article.css('div.article-head__author div em a').text

      # if article.at("div.subinfo b").text.nil?
      author_exist = Author.where(['lower(name) like ? ', 'Elikhbaria auteur'.downcase])
      # else
      #  author_exist = Author.where(['lower(name) like ? ',
      #                              article.at("div.subinfo b").text.downcase ])
      # end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = 'Elikhbaria auteur'
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('div.entry-content.clearfix.single-post-content').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('time[datetime]')['datetime']
      # d = change_translate_date(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24)
      url_array = # and link['class'] == 'b-loaded'
        article.css('div.post-header div.single-featured > a').map do |link|
          link['href']
        end
      url_image = url_array[0]
      begin
        new_article.image = Down.download(url_array[0]) if url_array[0].present?
      rescue Down::Error => e
        puts "Can't download this image #{url_array[0]}"
        puts e.message
        puts
        new_article.image = nil
      end
      tags_array = article.css('div.entry-terms a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end

      # tag_check_and_save(tags_array) if @media.tag_status == true
    end
    puts "json: { crawling_status_aps: 'ok' }"
  end
  # end method to get elikhbaria articles

  # start method to get algerieco articles
  def get_articles_algerieco(url_media_array)
    articles_url_algerieco = []
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
      doc.css('div.td-pb-span8 h3.entry-title a.td-eco-title').map do |link|
        articles_url_algerieco << link['href']
      end
      doc.css('time').map do |date|
        last_dates << date['datetime']
      end
    end
    # last_dates = last_dates.map { |d| change_translate_date(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
    articles_url_algerieco = articles_url_algerieco.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_algerieco_after_check = articles_url_algerieco - list_articles_url
    articles_url_algerieco_after_check.map do |link|
      #  article = Nokogiri::HTML(URI.open(link))
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('ul.td-category li:nth-child(1).entry-category a').text
      new_article.title = article.css('header.td-post-title h1.entry-title').text
      # new_article.author = article.css('div.article-head__author div em a').text

      if article.at('div.td-module-meta-info div').text.nil?
        author_exist = Author.where(['lower(name) like ? ', 'Algerieco auteur'.downcase])
      else
        author = article.at('div.td-module-meta-info div').text
        author_exist = Author.where(['lower(name) like ? ',
                                     author.downcase])
      end

      new_author = Author.new
      if author_exist.count.zero?
        author = article.at('div.td-module-meta-info div').text
        new_author.name = article.at('div.td-module-meta-info div').text.nil? ? 'Algerieco auteur' : author
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end
      new_article.body = article.css('div.td-post-content').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      new_article.body = new_article.body.gsub(%r{<div class="td-post-featured-image">(.*?)</a></div>}, '')
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('time[datetime]')['datetime']
      # d = change_translate_date(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('div.td-post-featured-image img').map { |link| link['src'] }
      url_image = url_array[0]
      begin
        new_article.image = Down.download(url_array[0]) if url_array[0].present?
      rescue Down::Error => e
        puts "Can't download this image #{url_array[0]}"
        puts e.message
        puts
        new_article.image = nil
      end

      # tags_array = article.css('div#article_tags_title').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end

      # #tag_check_and_save(tags_array)
    end
    puts "json: { crawling_status_aps: 'ok' }"
  end
  # end method to get algerieco articles

  # start method to get chiffreaffaire articles
  def get_articles_chiffreaffaire(url_media_array)
    articles_url_chiffreaffaire = []

    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end
      doc.css('div.listing h2 a').map do |link|
        articles_url_chiffreaffaire << link['href']
      end
    end
    articles_url_chiffreaffaire = articles_url_chiffreaffaire.reject(&:nil?)

    articles_url_chiffreaffaire_after_check = []
    articles_url_chiffreaffaire.map do |link|
      articles_url_chiffreaffaire_after_check << link unless Article.where(medium_id: @media.id,
                                                                           url_article: link).present?
    end

    articles_url_chiffreaffaire_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('div.post-header.post-tp-1-header > div.post-meta-wrap.clearfix > div.term-badges > span > a').text
      new_article.title = article.css('h1 span.post-title').text
      # new_article.author = article.css('div.article-head__author div em a').text

      if article.at('span.post-author-name').text.nil?
        author_exist = Author.where(['lower(name) like ? ', 'Chiffreaffaire auteur'.downcase])
      else
        author = article.at('span.post-author-name').text
        author_exist = Author.where(['lower(name) like ? ',
                                     author.downcase])
      end

      new_author = Author.new
      if author_exist.count.zero?
        author = article.at('span.post-author-name').text
        new_author.name = article.at('span.post-author-name').text.nil? ? 'Chiffreaffaire auteur' : author
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end
      new_article.body = article.css('div.entry-content').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('time[datetime]')['datetime']
      # d = change_translate_date(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24)
      url_array = article.css('div.single-featured a').map { |link| link['href'] }
      url_image = url_array[0]
      #  new_article.image = Down.download(url_array[0]) if url_array[0].present?

      begin
        new_article.image = Down.download(url_array[0]) if url_array[0].present?
      rescue Down::Error => e
        puts "Can't download this image #{url_array[0]}"
        puts e.message
        puts
        new_article.image = nil
      end

      tags_array = article.css('div.entry-terms a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end

      # tag_check_and_save(tags_array)
    end
    puts "json: { crawling_status_chiffreaffaire: 'ok' }"
  end
  # end method to get chiffreaffaire articles

  # start method to get elhiwar articles
  def get_articles_elhiwar(url_media_array)
    articles_url_elhiwar = []
    last_dates = []
    url_media_array.map do |url|
      # doc = Nokogiri::HTML(URI.open(url))
      begin
        doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby'))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      rescue SocketError => e
        puts "Error: #{e.message}"
        puts "Skipping #{url}"
        puts
        next  
      end
      doc.css('header.entry-header h2.entry-title a').map do |link|
        articles_url_elhiwar << link['href']
      end
      doc.css('time').map do |date|
        last_dates << date['datetime']
      end
    end
    # last_dates = last_dates.map { |d| change_translate_date(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24) }
    articles_url_elhiwar = articles_url_elhiwar.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_elhiwar_after_check = articles_url_elhiwar - list_articles_url
    articles_url_elhiwar_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('header > div.penci-entry-categories > span > a:nth-child(1)').text
      new_article.title = article.css('header > h1.entry-title').text
      # new_article.author = article.css('div.article-head__author div em a').text

      if article.at('span.author').text.nil?
        author_exist = Author.where(['lower(name) like ? ', 'Elhiwar auteur'.downcase])
      else
        author = article.at('span.author').text
        author_exist = Author.where(['lower(name) like ? ',
                                     author.downcase])
      end

      new_author = Author.new
      if author_exist.count.zero?
        author = article.at('span.author').text
        new_author.name = article.at('span.author').text.nil? ? 'Elhiwar auteur' : author
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end
      new_article.body = article.css('div.penci-entry-content').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('time[datetime]')['datetime']
      # d = change_translate_date(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24)
      url_array = article.css('div.entry-media img').map { |link| link['src'] }

      url_image = url_array[0]
      #  new_article.image = Down.download(url_array[0]) if url_array[0].present?

      begin
        new_article.image = Down.download(url_array[0]) if url_array[0].present?
      rescue Down::ResponseError => e
        puts "Can't download this image #{url_array[0]}"
        puts e.message
        puts
        new_article.image = nil
      end

      # tags_array = article.css('div.entry-terms a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end

      # #tag_check_and_save(tags_array)
    end
    puts "json: { crawling_status_elhiwar: 'ok' }"
  end
  # end method to get elhiwar articles

  # start method to get visadz articles
  def get_articles_visadz(url_media_array)
    articles_url_visadz = []
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
    # last_dates = last_dates.map { |d| change_translate_date(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24) }
    articles_url_visadz = articles_url_visadz.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
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
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end
      new_article.body = article.css('p.article__desc').inner_html + article.css('div.article__cntn').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('time[datetime]')['datetime']
      # d = change_translate_date(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24)
      # url_array = article.css('div.entry-media img').map {  |link| link['src'] }
      # url_image = url_array[0]
      # new_article.image = Down.download(url_array[0]) if url_array[0].present?
      # tags_array = article.css('div.entry-terms a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end

      # #tag_check_and_save(tags_array)
    end
    puts "json: { crawling_status_visadz: 'ok' }"
  end
  # end method to get visadz articles

  # start method to get santenews articles
  def get_articles_santenews(url_media_array)
    articles_url_santenews = []
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
      doc.css('article.item-list h2.post-box-title a').map do |link|
        articles_url_santenews << link['href']
      end

      doc.css('span.tie-date').map do |date|
        last_dates << date.text
      end
    end
    last_dates = last_dates.map { |d| change_translate_date(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
    articles_url_santenews = articles_url_santenews.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_santenews_after_check = articles_url_santenews - list_articles_url
    articles_url_santenews_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('#crumbs > span:nth-child(3) > a').text
      new_article.title = article.css('div.post-inner h1.name').text
      # new_article.author = article.css('div.article-head__author div em a').text

      author_exist = Author.where(['lower(name) like ? ', 'Santenews auteur'.downcase])

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = 'Santenews auteur'
        new_author.medium_id = @media.id
        new_author.save!
      else

        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name

      end
      new_article.author_id = new_author.id
      new_article.body = article.css('#the-post > div.post-inner > div.entry').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('span.tie-date').text
      date = change_translate_date(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('div.single-post-thumb  img').map { |link| link['src'] }
      url_image = url_array[0]
      begin
        new_article.image = Down.download(url_array[0]) if url_array[0].present?
      rescue Down::Error => e
        puts "Can't download this image #{url_array[0]}"
        puts e.message
        puts
        new_article.image = nil
      end
      # tags_array = article.css('div.entry-terms a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
      # #tag_check_and_save(tags_array)
    end
    puts "json: { crawling_status_elhiwar: 'ok' }"
  end
  # end method to get elhiwar articles

  # start method to get shihabpresse articles
  def get_articles_shihabpresse(url_media_array)
    articles_url_shihabpresse = []
    count = 0
    url_media_array.map do |url|
      # doc = Nokogiri::HTML(URI.open(url))

      begin
        doc = Nokogiri::HTML(URI.open(url))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end

      doc.css('div.post-details h2.post-title a').map do |link|
        articles_url_shihabpresse << link['href']
      end
    end
    articles_url_shihabpresse = articles_url_shihabpresse.reject(&:nil?)

    articles_url_shihabpresse_after_check = []
    articles_url_shihabpresse.map do |link|
      articles_url_shihabpresse_after_check << link unless Article.where(medium_id: @media.id,
                                                                         url_article: link).present?
    end

    articles_url_shihabpresse_after_check.map do |link|
      begin
        article = Nokogiri::HTML(URI.open(link))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{link}"
        puts e.message
        puts
        next
      rescue RuntimeError => e
        puts "Can't access #{link}"
        puts e.message
        puts
        next
      end
      new_article = Article.new
      new_article.url_article = link
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('div.entry-header span.post-cat-wrap a').text
      new_article.title = article.css('div.entry-header h1.post-title.entry-title').text
      # new_article.author = article.css('div.article-head__author div em a').text

      author_exist = Author.where(['lower(name) like ? ',
                                   'shihabpresse auteur'.downcase])

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = 'shihabpresse auteur'
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end
      new_article.body = article.css('div.entry-content.entry.clearfix p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date = article.at('span.date.meta-item.tie-icon').text
      new_article.date_published = get_date_from_string(date)

      unless article.at_css('div.featured-area figure img').nil?
        url_array = article.css('div.featured-area figure img').map { |link| link['src'] }
      end
      new_article.url_image = url_array[0]

      # new_article.image = Down.download(url_array[0]) if url_array[0].present?

      begin
        new_article.image = Down.download(url_array[0]) if url_array[0].present?
      rescue Down::ResponseError => e
        puts "Can't download this image #{url_array[0]}"
        puts e.message
        puts
        new_article.image = nil
      end

      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      count += 1 if new_article.save
      # tag_check_and_save(tags_array)if @media.tag_status == true

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end

      # #tag_check_and_save(tags_array)
    end
    puts "json: { crawling_status_shihabpresse: 'ok' }"
  end
  # end method to get shihabpresse articles

  # start method to get expression articles
  def get_articles_lexpressiondz(url_media_array)
    articles_url_lexpressiondz = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(open(url, 'User-Agent' => 'ruby'))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end

      doc.css('article h2 a').map do |link|
        articles_url_lexpressiondz << link['href']
      end
    end
    articles_url_lexpressiondz = articles_url_lexpressiondz.reject(&:nil?)

    articles_url_lexpressiondz_after_check = []
    articles_url_lexpressiondz.map do |link|
      articles_url_lexpressiondz_after_check << link unless Article.where(medium_id: @media.id,
                                                                          url_article: link).present?
    end

    articles_url_lexpressiondz_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('#content > nav > ol > li:nth-child(3) > a').text
      new_article.title = "#{article.css('article header.heading-a p').text}, #{article.css('article header.heading-a h1').text}"
      # new_article.author = article.css('div.article-head__author div em a').text
      author_exist = if article.css('h3.scheme-user').text == ''
                       Author.where(['lower(name) like ? ', "L'expressiondz auteur".downcase])
                     else
                       a = article.css('h3.scheme-user').text
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.css('h3.scheme-user').text == '' ? "L'expressiondz auteur" : article.css('h3.scheme-user').text
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('div.module-article p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')

      date_published_array = article.at('ul.list-details li').text
      new_article.date_published = date_published_array.split('|')[1].to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('figure.image-featured img').map { |link| link['data-src'] }
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
    end
    puts "json: { crawling_status_expression: 'ok' }"
  end
  # end method to get expression articles
  #

  # start method to get lematin articles
  def get_articles_lematin(url_media_array)
    articles_url_lematin = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(open(url, 'User-Agent' => 'ruby'))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end

      doc.css('div.card.h-100 a').map do |link|
        articles_url_lematin << link['href']
      end
    end
    articles_url_lematin = articles_url_lematin.reject(&:nil?)

    articles_url_lematin_after_check = []
    articles_url_lematin.map do |link|
      articles_url_lematin_after_check << link unless Article.where(medium_id: @media.id, url_article: link).present?
    end

    articles_url_lematin_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('h3.title-section.mb-2').text
      new_article.title = article.css('h1#title').text
      # new_article.author = article.css('div.article-head__author div em a').text
      author_exist_array = article.css('p.author span a').map { |link| link['title'] }
      author_exist_final = author_exist_array.reject(&:nil?)
      author_exist = if author_exist_final.count.zero?
                       Author.where(['lower(name) like ? ', 'Lematin auteur'.downcase])
                     else
                       a = author_exist_final[0]
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = author_exist_final.count.zero? ? 'Lematin auteur' : author_exist_final[0]
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('p.lead.caption').inner_html + article.css('div.card-body.p-2').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')

      date_published_array = article.css('p.author span meta').map do |date|
        date['content'] if date['itemprop'] == 'datePublished'
      end
      new_article.date_published = date_published_array.reject(&:nil?)[0].nil? ? Date.today.change({ hour: 0, min: 0, sec: 0 }) : date_published_array.reject(&:nil?)[0].to_datetime.change({ hour: 0, min: 0,
                                                                                               sec: 0 })
      url_array = article.css('img.d-block.w-100').map { |link_image| link_image['src'] }
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
    end
    puts "json: { crawling_status_lematin: 'ok' }"
  end
  # end method to get lematin articles
  #

  # start method to get almaghreb24 articles
  def get_articles_almaghreb24(url_media_array)
    articles_url_almaghreb24 = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(open(url, 'User-Agent' => 'ruby'))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end

      doc.css('h2.post-title a').map do |link|
        articles_url_almaghreb24 << link['href']
      end
    end
    articles_url_almaghreb24 = articles_url_almaghreb24.reject(&:nil?)

    articles_url_almaghreb24_after_check = []
    articles_url_almaghreb24.map do |link|
      articles_url_almaghreb24_after_check << link unless Article.where(medium_id: @media.id,
                                                                        url_article: link).present?
    end

    articles_url_almaghreb24_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('#breadcrumb > a:nth-child(3)').text
      new_article.title = article.css('div.entry-header h1.post-title.entry-title').text
      # new_article.author = article.css('div.article-head__author div em a').text
      author_exist_final = article.css('span.meta-author a').text
      author_exist = if author_exist_final.nil? || author_exist_final == ''
                       Author.where(['lower(name) like ? ', 'Almaghreb24 auteur'.downcase])
                     else
                       a = author_exist_final
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = author_exist_final.nil? || author_exist_final == '' ? 'Almaghreb24 auteur' : author_exist_final
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('div.entry-content.entry.clearfix p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')

      new_article.date_published = Date.today.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('figure.single-featured-image img').map { |link| link['src'] }
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
    end
    puts "json: { crawling_status_Almaghreb24: 'ok' }"
  end
  # end method to get Almaghreb24 articles

  # start method to get aujourdhui articles
  def get_articles_aujourdhui(url_media_array)
    articles_url_aujourdhui = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(open(url, 'User-Agent' => 'ruby'))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end

      doc.css('h2.cat-list-title a').map do |link|
        articles_url_aujourdhui << link['href']
      end
    end
    articles_url_aujourdhui = articles_url_aujourdhui.reject(&:nil?)

    articles_url_aujourdhui_after_check = []
    articles_url_aujourdhui.map do |link|
      articles_url_aujourdhui_after_check << link unless Article.where(medium_id: @media.id, url_article: link).present?
    end

    articles_url_aujourdhui_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('div.entry-cat a').text
      new_article.title = article.css('h1.entry-title').text
      # new_article.author = article.css('div.article-head__author div em a').text
      author_exist_final = article.css('span.meta-author a').text
      author_exist = if author_exist_final.nil? || author_exist_final == ''
                       Author.where(['lower(name) like ? ', 'Aujourdhui-MA auteur'.downcase])
                     else
                       a = author_exist_final
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = author_exist_final.nil? || author_exist_final == '' ? 'Aujourdhui-MA auteur' : author_exist_final
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('div.entry-content.clearfix p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      new_article.date_published = article.at('time.entry-date').attr('datetime').to_datetime.change({ hour: 0, min: 0,
                                                                                                       sec: 0 }) + (1.0 / 24)
      url_array = article.css('div.entry-content.clearfix figure.post-thumbnail img').map do |link|
        link['src'] if link['src'].include? 'https'
      end
      url_array = url_array.reject(&:nil?)
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
    end
    puts "json: { crawling_status_aujourdhui: 'ok' }"
  end
  # end method to get Aujourdhui articles

  # start method to get eldjazaireldjadida articles
  def get_articles_eldjazaireldjadida(url_media_array)
    articles_url_eldjazaireldjadida = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.10', 'From' => 'foo@bar.invalid'), nil, 'UTF-8')
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      rescue Net::OpenTimeout => e
        puts "TRY #{url}/n ERROR: timed out while trying to connect #{url}"
        puts e.message
        puts
        next
      end

      doc.css('h2.post-title a').map do |link|
        articles_url_eldjazaireldjadida << link['href']
      end
    end
    articles_url_eldjazaireldjadida = articles_url_eldjazaireldjadida.reject(&:nil?)

    articles_url_eldjazaireldjadida_after_check = []
    articles_url_eldjazaireldjadida.map do |link|
      articles_url_eldjazaireldjadida_after_check << link unless Article.where(medium_id: @media.id,
                                                                               url_article: link).present?
    end

    articles_url_eldjazaireldjadida_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('header.entry-header-outer div.entry-header span.post-cat-wrap a:last-child').text
      new_article.title = article.css('h1.post-title.entry-title').text
      # new_article.author = article.css('div.article-head__author div em a').text
      author_exist_final = article.at('span.meta-item.meta-author-wrapper span.meta-author').text
      author_exist = if author_exist_final.nil? || author_exist_final == ''
                       Author.where(['lower(name) like ? ', 'ELDJAZAIR-ELDJADIDA auteur'.downcase])
                     else
                       a = author_exist_final
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = author_exist_final.nil? || author_exist_final == '' ? 'ELDJAZAIR-ELDJADIDA auteur' : author_exist_final
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('div.entry-content.entry.clearfix p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date_arabe = article.at('span.date.meta-item.tie-icon').text
      date = change_translate_date(date_arabe)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('figure.single-featured-image img').map do |link|
        link['src'] if link['src'].include? 'https'
      end
      url_array = url_array.reject(&:nil?)
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
    end
    puts "json: { crawling_status_eldjazaireldjadida: 'ok' }"
  end
  # end method to get eldjazaireldjadida articles

  # start method to get algeriepatriotique articles
  def get_articles_algeriepatriotique(url_media_array)
    articles_url_algeriepatriotique = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.10', 'From' => 'foo@bar.invalid'), nil, 'UTF-8')
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end

      doc.css('div.blog-content.grid-layout h2.entry-title a').map do |link|
        articles_url_algeriepatriotique << link['href']
      end
    end
    articles_url_algeriepatriotique = articles_url_algeriepatriotique.reject(&:nil?)

    articles_url_algeriepatriotique_after_check = []
    articles_url_algeriepatriotique.map do |link|
      articles_url_algeriepatriotique_after_check << link unless Article.where(medium_id: @media.id,
                                                                               url_article: link).present?
    end

    articles_url_algeriepatriotique_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('header.entry-header ul.breadcrumbs  li:nth-child(2) a').text
      new_article.title = article.css('h1.entry-title').text
      # new_article.author = article.css('div.article-head__author div em a').text
      author_exist_final = article.at('div.entry-info span.posted-date span.author.vcard a').text
      author_exist = if author_exist_final.nil? || author_exist_final == ''
                       Author.where(['lower(name) like ? ', 'ALGERIE-PATRIOTIQUE auteur'.downcase])
                     else
                       a = author_exist_final
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = author_exist_final.nil? || author_exist_final == '' ? 'ALGERIE-PATRIOTIQUE auteur' : author_exist_final
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('div.the-content  p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date_arabe = article.at('div.entry-info span.posted-date').text
      date = change_translate_date(date_arabe.split('-')[0])
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('div.post-formats-wrapper a.post-image img').map { |link| link['src'] }
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
    end
    puts "json: { crawling_status_algeriepatriotique: 'ok' }"
  end
  # end method to get algeriepatriotique articles

  # start method to get elmaouid articles
  def get_articles_elmaouid(url_media_array)
    articles_url_elmaouid = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.10', 'From' => 'foo@bar.invalid'), nil, 'UTF-8')
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end

      doc.css('h2.post-box-title a').map do |link|
        articles_url_elmaouid << link['href']
      end
    end
    articles_url_elmaouid = articles_url_elmaouid.reject(&:nil?)

    articles_url_elmaouid_after_check = []
    articles_url_elmaouid.map do |link|
      articles_url_elmaouid_after_check << link unless Article.where(medium_id: @media.id, url_article: link).present?
    end

    articles_url_elmaouid_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('header.entry-header-outer div.entry-header span.post-cat-wrap a:last-child').text
      new_article.title = article.css('h1.name.post-title.entry-title').text
      # new_article.author = article.css('div.article-head__author div em a').text
      author_exist_final = 'Elmaouid auteur'
      author_exist = if author_exist_final.nil? || author_exist_final == ''
                       Author.where(['lower(name) like ? ', 'Elmaouid auteur'.downcase])
                     else
                       a = author_exist_final
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = author_exist_final.nil? || author_exist_final == '' ? 'Elmaouid auteur' : author_exist_final
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('div.post-inner div.entry').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date = article.at('span.tie-date').text
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array =  article.css('div.single-post-thumb img').map { |link| link['src'] }
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
    end
    puts "json: { crawling_status_elmaouid: 'ok' }"
  end
  # end method to get elmaouid articles

  # start method to get alyaoum24 articles
  def get_articles_alyaoum24(url_media_array)
    articles_url_alyaoum24 = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.10', 'From' => 'foo@bar.invalid'), nil, 'UTF-8')
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
      articles_url_alyaoum24_after_check << link unless Article.where(medium_id: @media.id, url_article: link).present?
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('ul.breadcrumb li:nth(2)').text
      new_article.title =  article.css('div.infoSingle h1').text
      # new_article.author = article.css('div.article-head__author div em a').text
      author_exist_final = article.at('div.nameAuthor').text
      author_exist = if author_exist_final.nil? || author_exist_final == ''
                       Author.where(['lower(name) like ? ', 'Alyaoum24 auteur'.downcase])
                     else
                       a = author_exist_final
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = author_exist_final.nil? || author_exist_final == '' ? 'Alyaoum24 auteur' : author_exist_final
        new_author.medium_id = @media.id
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
    end
    puts "json: { crawling_status_alyaoum24: 'ok' }"
  end
  # end method to get alyaoum24 articles

  # start method to get elwatan articles
  def get_articles_elwatan(url_media_array)
    articles_url_elwatan = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.10', 'From' => 'foo@bar.invalid'), nil, 'UTF-8')
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end

      doc.css('h3.title-14 a').map do |link|
        articles_url_elwatan << link['href']
      end
    end
    articles_url_elwatan = articles_url_elwatan.reject(&:nil?)

    articles_url_elwatan_after_check = []
    articles_url_elwatan.map do |link|
      articles_url_elwatan_after_check << link unless Article.where(medium_id: @media.id, url_article: link).present?
    end

    articles_url_elwatan_after_check.map do |link|
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('ul > li:nth-child(2) > a:nth-child(2)').text
      new_article.title = article.css('h1.title-21').text
      # new_article.author = article.css('div.article-head__author div em a').text
      author_exist_final = article.at('div.author-tp-2 a').text
      author_exist = if author_exist_final.nil? || author_exist_final == ''
                       Author.where(['lower(name) like ? ', 'Elwatan auteur'.downcase])
                     else
                       a = author_exist_final
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = author_exist_final.nil? || author_exist_final == '' ? 'Elwatan auteur' : author_exist_final
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('div.texte p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date = article.at('div.date-tp-4').text
      new_article.date_published = date.split('à')[0].to_datetime.change({ hour: 0, min: 0, sec: 0 })
      new_article.url_image = nil
      new_article.status = 'pending'

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
    end
    puts "json: { crawling_status_elwatan: 'ok' }"
  end
  # end method to get elwatan articles

  # start method to get radioalgerie-ar articles
  def get_articles_radioalgerie_ar(url_media_array)
    articles_url_radioalgerie_ar = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.10', 'From' => 'foo@bar.invalid'), nil, 'UTF-8')
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
      articles_url_radioalgerie_ar_after_check << link unless Article.where(medium_id: @media.id,
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('div.content div.field.field--name-field-categories.field--type-entity-reference.field--label-hidden.field__item a').text
      new_article.title = article.css('h1.title').text
      # new_article.author = article.css('div.article-head__author div em a').text
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
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('div.content p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      check_date = article.at('div.content span.field.field--name-created.field--type-created.field--label-inline')
      date = check_date.present? ? article.at('div.content span.field.field--name-created.field--type-created.field--label-inline').text : Date.today
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      check_url_pic = "https://news.radioalgerie.dz#{article.at('div.col-lg-8 picture img')}"
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
    end
    puts "json: { crawling_status_radioalgerie_ar: 'ok' }"
  end
  # end method to get radioalgerie-ar articles

  # start method to get radioalgerie-fr articles
  def get_articles_radioalgerie_fr(url_media_array)
    articles_url_radioalgerie_fr = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.10', 'From' => 'foo@bar.invalid'), nil, 'UTF-8')
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end

      doc.css('h3 a').map do |link|
        articles_url_radioalgerie_fr << "https://news.radioalgerie.dz#{link['href']}"
      end
    end
    articles_url_radioalgerie_fr = articles_url_radioalgerie_fr.reject(&:nil?)

    articles_url_radioalgerie_fr_after_check = []
    articles_url_radioalgerie_fr.map do |link|
      articles_url_radioalgerie_fr_after_check << link unless Article.where(medium_id: @media.id,
                                                                            url_article: link).present?
    end

    articles_url_radioalgerie_fr_after_check.map do |link|
      puts '******'
      puts link
      puts '******'
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('div.content div.field.field--name-field-categories.field--type-entity-reference.field--label-hidden.field__item a').text
      new_article.title = article.css('h1.title').text
      # new_article.author = article.css('div.article-head__author div em a').text
      author_exist_final = 'Radioalgerie-FR auteur'
      author_exist = if author_exist_final.nil? || author_exist_final == ''
                       Author.where(['lower(name) like ? ', 'Radioalgerie-FR auteur'.downcase])
                     else
                       a = author_exist_final
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = author_exist_final.nil? || author_exist_final == '' ? 'Radioalgerie-AR auteur' : author_exist_final
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('div.content p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      check_date = article.at('div.content span.field.field--name-created.field--type-created.field--label-inline')
      date = check_date.present? ? article.at('div.content span.field.field--name-created.field--type-created.field--label-inline').text : Date.today
      puts date
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
    end
    puts "json: { crawling_status_radioalgerie_ar: 'ok' }"
  end
  # end method to get radioalgerie-fr articles

  # start method to get maroco360 articles
  def get_articles_maroco360(url_media_array)
    articles_url_maroco360 = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.10', 'From' => 'foo@bar.invalid'), nil, 'UTF-8')
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
    articles_url_maroco360.map do |link|
    end

    articles_url_maroco360_after_check = []
    articles_url_maroco360.map do |link|
      articles_url_maroco360_after_check << link unless Article.where(medium_id: @media.id, url_article: link).present?
    end
    articles_url_maroco360_after_check.map do |link|
    end

    articles_url_maroco360_after_check.map do |link|
      puts '*****'
      puts link
      puts '*****'
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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('#block-system-main > div > div.content-block > div.label-ttl.label-node > div:nth-child(1)').text
      new_article.title =  article.css('div.articles-holder h1').text
      # new_article.author = article.css('div.article-head__author div em a').text
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
        new_author.medium_id = @media.id
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

      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articles_tags_url = link
      end
      puts "This Url : #{articles_tags_url} will be add to the tag articles list"

      new_article.save!
      if articles_tags_url.present?
        puts 'add article'
        @articles_for_auto_tag << Article.where(url_article: articles_tags_url)[0]
      end
    end
    puts "json: { crawling_status_maroco360: 'ok' }"
  end
  # end method to get maroco360 articles

  # tag_check_and_savetag_check_and_save
  def tag_check_and_save(tags_array)
    tags_array.map do |t|
      tag_exist = Tag.where(['lower(name) like ? ', t.downcase.strip]).count
      next unless tag_exist.zero?

      tag = Tag.new
      tag.name = t.strip
      tag.save!
    end
  end

  # # change_date_autobip_aps
  # def change_date_autobip_aps(d)
  #   d.split.map do |m|
  #     case m.downcase
  #     when 'Janvier'.downcase
  #       'January'
  #     when 'Février'.downcase
  #       'February'
  #     when 'Mars'.downcase
  #       'March'
  #     when 'Avril'.downcase
  #       'April'
  #     when 'Mai'.downcase
  #       'May'
  #     when 'Juin'.downcase
  #       'June'
  #     when 'Juillet'.downcase
  #       'July'
  #     when 'juillet'.downcase
  #       'July'
  #     when 'Octobre'.downcase
  #       'October'
  #     when 'Novembre'.downcase
  #       'November'
  #     when 'Décembre'.downcase
  #       'December'
  #     when 'Septembre'.downcase
  #       'September'
  #     when 'Aout'.downcase
  #       'August'
  #     when 'août,'.downcase
  #       'August'
  #     when 'août'.downcase
  #       'August'
  #     else
  #       m
  #     end
  #   end.join(' ')
  # end
  # # change_date_autobip_aps
  # #

  # change_translate_date
  def change_translate_date(d)
    d.split.map do |m|
      case m.downcase
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
      when 'juillet'.downcase
        'July'
      when 'Octobre'.downcase
        'October'
      when 'Novembre'.downcase
        'November'
      when 'Décembre'.downcase
        'December'
      when 'Septembre'.downcase
        'September'
      when 'Aout'.downcase
        'August'
      when 'août,'.downcase
        'August'
      when 'août'.downcase
        'August'
        
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
      when 'أوت'.downcase
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
  # change_translate_date

  #auto_tag
  def auto_tag(articles_for_autoTag)
    # slug_id = params[:slug_id]
    # start_date = params[:start_date]
    # end_date = params[:start_date]
    reject = []
    # articles_for_autoTag.delete_if { |v| reject << v if Article.where(url_article: v.url_article) }
    campaigns = Campaign.all
    puts "campaigns count#{campaigns.count}"
    puts "articles count#{articles_for_autoTag.count}"
    puts "reject articles count#{reject.count}"

    campaigns.map do |campaign|
      all_tags = campaign.tags.empty? ? [] : campaign.tags.where(status: true)
      camp_media = campaign.media
      camp_media_array = camp_media.map(&:id)
      articles = []
      # all_tags = Tag.where(status: true)
      next if articles_for_autoTag.empty?

      filtered_articles = []
      puts 'array camp_media_array'
      puts camp_media_array
      puts 'array camp_media_array'

      articles_for_autoTag.map do |article|
        puts article.medium_id
        filtered_articles << article if camp_media_array.include? article.medium_id
      end

      @tags = []
      filtered_articles.map do |article|
        @tags_objects = []
        all_tags.map do |tag|
          if article.body.downcase.include? tag.name.downcase
            @tags << tag.name unless @tags.include? tag.name
            @tags_objects << tag unless @tags_objects.include? tag.name
          end
        unless article.title.nil?
          if article.title.downcase.include? tag.name.downcase
            @tags << tag.name unless @tags.include? tag.name
            @tags_objects << tag unless @tags_objects.include? tag.name
          end
        end
        end
        old_tags = article.media_tags.nil? ? [] : article.media_tags.split(',')
        old_tags << @tags
        #  article.media_tags = old_tags.join(',')
        @tags_objects.map do |tag_object|
          next if ArticleTag.where(article_id: article.id, tag_id: tag_object.id, slug_id: campaign.slug_id,
                                   campaign_id: campaign.id).present?

          @article_tag = ArticleTag.new article_id: article.id, tag_id: tag_object.id, slug_id: campaign.slug_id,
                                        campaign_id: campaign.id
          if @article_tag.save
            puts 'Article_tag well added '
          else
            puts 'Article_tag error'
          end
        end

        # article.is_tagged = true if @tags_objects.length.positive?

        articles << article if @tags_objects.length.positive?
        article.reindex
      end
      puts '******************************'
      puts "Nombre d'articles :#{articles.count}"
      puts '******************************'
      puts 'tag******************************tag'
      puts @tags
      puts 'tag******************************tag'
      # campaigns = Campaign.all
      next unless campaign.present?

      users = User.where(slug_id: campaign.slug_id)
      # camp_tags = campaign.tags
      #   camp_media = campaign.media
      article_to_send = []
      tag_to_send = []
      # camp_tags_array = camp_tags.map(&:id)
      # camp_media_array = camp_media.map(&:id)
      articles.map do |article|
        article_tags = article.tags.map(&:id)
        tag_to_send << @tags
        # status_tag = camp_tags_array.any? { |i| article_tags.include? i }
        # status_media = camp_media_array.any? { |i| [article.medium_id].include? i }
        article_to_send << article
        #  article_to_send << article if status_tag == true && status_media == true
      end
      if article_to_send.length.positive?
        users.map { |user| UserMailer.taggedarticles(article_to_send, user, tag_to_send.uniq).deliver }
      end
    end
    puts "json: { tags: 'ok' }"
    # render json: { tags: 'ok' }
  end

  def get_date_from_string(string)
    puts '*******************'
    puts string
    puts '*******************'

    if string.include?('ثانية') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    elsif string.include?('ثوان') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    elsif string.include?('ساعتين') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    elsif string.include?('دقيقة') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    elsif string.include?('دقائق') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    elsif string.include?('دقيقتين') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    elsif string.include?('منذ ساعة واحدة') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    elsif string.include?('ساعات') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    elsif string.include?('ساعة') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    elsif string.include?('منذ يوم واحد') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 }) - 1
    elsif string.include?('منذ يومين') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 }) - 2
    elsif string.include?('منذ أسبوعين') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 }) - 14
    elsif string.include?('منذ أسبوع واحد') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 }) - 7
    elsif string.include?('أيام') == true
      array = string.split(' ')
      number = array[1]
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 }) - number.to_i
    elsif string.include?('أسابيع') == true
      array = string.split(' ')
      number = array[0]
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 }) - number.to_i * 7
    else
      string.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    end
  end

  # auto_tag
end
