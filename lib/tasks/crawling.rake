require 'nokogiri'
require 'open-uri'
require 'openssl'
#require 'resolv-replace'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
namespace :crawling do


  desc 'carwling all media'
  task scraping: :environment do

    Medium.all.each { |m|
      @media = m
      @articles_for_auto_tag = []
      if m.url_crawling? && m.name != 'APS'
        url_media_array = m.url_crawling.split(',')
        puts url_media_array
        get_articles(url_media_array,m)
        Article.where(medium_id: m.id,created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day).where.not(id: Article.group(:url_article).select('min(id)')).destroy_all

      else
        puts "crawling_status: 'No url_crawling', media: m.name, status: 'error'"
      end

    }
    puts 'call auto tag'
    auto_tag(@articles_for_auto_tag)
    puts 'end auto tag'
  end


  def get_articles(url_media_array, media)
    puts  'get article of ' + media.name
    case media.name
    when 'AUTOBIP'
      get_articles_autobip(url_media_array)
    when 'ELCHEROUK'
      get_articles_elcherouk(url_media_array)
    when 'ENNAHAR'
      get_articles_ennahar(url_media_array)
    when 'TSA'
      get_articles_tsa(url_media_array)
    when 'APS'
      get_articles_aps(url_media_array)
    when 'MAGHREBEMERGENT'
      get_articles_maghrebemergent(url_media_array)
    when 'ELBILAD'
      get_articles_bilad(url_media_array)
    # when 'ELMOUDJAHID'
    #   get_articles_elmoudjahid(url_media_array)
    # when 'ELMOUDJAHID-FR'
      get_articles_elmoudjahid_fr(url_media_array)
    when 'ELKHABAR'
      get_articles_elkhabar(url_media_array)
    when 'ELIKHABARIA'
      get_articles_elikhbaria(url_media_array)
    when 'ALGERIECO'
      get_articles_algerieco(url_media_array)
    # when 'CHIFFREAFFAIRE'
    #   get_articles_chiffreaffaire(url_media_array)
    when 'ELHIWAR'
      get_articles_elhiwar(url_media_array)
    when 'LE SOIR'
      get_articles_le_soir(url_media_array)
    when 'LIBERTE'
      get_articles_liberte(url_media_array)
    when 'VISAALGERIE'
      get_articles_visadz(url_media_array)
    when 'SANTENEWS'
      get_articles_santenews(url_media_array)
    when 'ALGERIE360'
      get_articles_algerie360(url_media_array)
    else
      puts  "crawling_status: 'No media name found!! ', status: 'error' "
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

    last_dates = last_dates.map { |d| change_date_autobip_aps(d) }
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
                                     article.at("//a[@itemprop = 'author']").text.downcase ])
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

        d = change_date_autobip_aps(article.at("//span[@itemprop = 'datePublished']").text)
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
        new_article.save!
      #tag_check_and_save(tags_array) if @media.tag_status == true
      end

    puts "json: { crawling_status_autobip: 'ok' }"
  end
    # end method to get autobip articles

    # start method to get elcherouk articles
  def get_articles_elcherouk(url_media_array)
    articles_url_cherouk = []
    last_dates = []
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
      doc.css('div.ech-card__mtil').map do |date|
        last_dates << DateTime.parse(date.text)
      end
    end
    articles_url_cherouk = articles_url_cherouk.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_cherouk_after_check = articles_url_cherouk - list_articles_url
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
                                   article.css('article div.d-f.fxd-c.ai-fs a').text.downcase ])

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.css('article div.d-f.fxd-c.ai-fs a').text
        new_author.medium_id = @media.id
        new_author.save!
      else

        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name

      end
      new_article.author_id = new_author.id
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
      new_article.save!

      if new_article.save
        count += 1
        @articles_for_auto_tag.push(new_article)
      end
      #tag_check_and_save(tags_array)if @media.tag_status == true
    end
    puts 'json: { crawling_count_elcherouk:  count  }'
  end
    # end method to get elcherouk articles


    # start method to get ennahar articles
  def get_articles_ennahar(url_media_array)
    articles_url_ennahar = []
    last_dates = []
    url_media_array.map do |url|
     # doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.5'))


      begin
        doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.5'))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end

      doc.css('div.article__image.article__image--medium a').map do |link|
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
        article = Nokogiri::HTML(URI.open(link, 'User-Agent' => 'ruby/2.6.5'))
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
      new_article.category_article = article.css('div.article-section > div > div.article-section__main.wrap__main > article > div.full-article__meta > div.article__category > a').text
      new_article.title = article.css('body > div.article-section > div > div.article-section__main.wrap__main > article > h2').text
      # new_article.author = article.css('div.article-head__author div em a').text

      author_exist = Author.where(['lower(name) like ? ',
                                   article.at('body > div.article-section > div > div.article-section__main.wrap__main > article > div.full-article__author-share > div > span > em').text.downcase ])

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('body > div.article-section > div > div.article-section__main.wrap__main > article > div.full-article__author-share > div > span > em').text
        new_author.medium_id = @media.id
        new_author.save!
      else

        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name

      end
      new_article.author_id = new_author.id
      new_article.body = article.css('body > div.article-section > div > div.article-section__main.wrap__main > article > div.full-article__content').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      new_article.date_published = article.at('time[datetime]')['datetime'].to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24)
      url_array = article.css('body > div.article-section > div > div.article-section__main.wrap__main > article > div.full-article__featured-image > img').map { |link| link['src'] }
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
      new_article.save!
      if new_article.save
        @articles_for_auto_tag.push(new_article)
      end
      # #tag_check_and_save(tags_array)
    end
    puts "json: { crawling_status_elcherouk: 'ok' }"
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
        articles_url_tsafr << link['href']# if link['class'] == 'main_article'
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
      new_article.category_article = article.css('div.article__meta a.article__meta-category').text
      new_article.title = article.css('div.article__title').text
      # new_article.author = article.css('div.article-head__author div em a').text

      if article.at('span.article__meta-author').nil?
        author_exist = Author.where(['lower(name) like ? ', ('TSA auteur').downcase ])
      else
        author_exist = Author.where(['lower(name) like ? ',
                                     article.at('span.article__meta-author').text.downcase ])
      end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('span.article__meta-author').nil? ? 'TSA auteur' : article.at('span.article__meta-author').text
        new_author.medium_id = @media.id
        new_author.save!
      else

        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name

      end
      new_article.author_id = new_author.id
      new_article.body = article.css('div.article__content').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date = article.at('time[datetime]')['datetime']
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('body > div.article-section > div > div.article-section__main.wrap__main > article > div.full-article__featured-image > img').map { |link| link['src'] }
      new_article.url_image = url_array[0]
      begin
           if url_array[0].present?
             new_article.image = Down.download(url_array[0])
           end
         rescue Down::Error => e
           puts "Can't download this image #{url_array[0]}"
           puts e.message
           puts
           new_article.image = nil
         end
      # tags_array = article.css('div.article-core__tags a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      if new_article.save
        @articles_for_auto_tag.push(new_article)
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
        doc = Nokogiri::HTML(URI.open(url))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end
      doc.css('#itemListLeading h3 a').map do |link|
        articles_url_aps << 'http://www.aps.dz' + link['href']# if link['class'] == 'main_article'
      end
      doc.css('span.catItemDateCreated').map do |date|
        last_dates << date.text
      end
    end
    last_dates = last_dates.map { |d| change_date_autobip_aps(d) }
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
      new_article.category_article = article.css('nav.wrap.t3-navhelper > div > ol > li a').text == '' ? article.css('body > div.t3-wrapper > nav.wrap.t3-navhelper > div > ol > li:nth-child(2) > span').text : article.css('nav.wrap.t3-navhelper > div > ol > li a').text
      new_article.title = article.css('div.itemHeader h2.itemTitle').text
      # new_article.author = article.css('div.article-head__author div em a').text

      if article.at('span.article__meta-author').nil?
        author_exist = Author.where(['lower(name) like ? ', ('APS auteur').downcase ])
      else
        author_exist = Author.where(['lower(name) like ? ',
                                     article.at('span.article__meta-author').text.downcase ])
      end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('span.article__meta-author').nil? ? 'APS auteur' : article.at('span.article__meta-author').text
        new_author.medium_id = @media.id
        new_author.save!
      else

        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name

      end
      new_article.author_id = new_author.id
      new_article.body = article.css('div.itemIntroText strong').inner_html + article.css('div.itemFullText').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date = article.css('span.itemDateCreated').text
      date['Publié le : '] = ''
      d = change_date_autobip_aps(date)
      new_article.date_published = d.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      # new_article.date_published =
      url_array = article.css('div.itemImageBlock span.itemImage img').map { |link| 'http://www.aps.dz' + link['src'] }
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
      new_article.save!
      if new_article.save
        @articles_for_auto_tag.push(new_article)
      end
      #tag_check_and_save(tags_array)if @media.tag_status == true
    end
    puts "json: { crawling_status_aps: 'ok' }"
  end
    # end method to get APS articles



    # start method to get le soir articles
  def get_articles_le_soir(url_media_array)
    articles_url_le_soir = []
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
      doc.css('div.description a').map do |link|
        articles_url_le_soir << 'https://www.lesoirdalgerie.com' + link['href']# if link['class'] == 'main_article'
      end
      doc.css('div.description div.type-date').map do |date|
        last_dates << date.text
      end
    end
    last_dates = last_dates.map { |d| change_date_autobip_aps(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
    # last_dates = last_dates.map(&:to_datetime.change({ hour: 0, min: 0, sec: 0 }))
    articles_url_le_soir = articles_url_le_soir.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_le_soir_after_check = articles_url_le_soir - list_articles_url
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
      new_article.category_article = article.css('div.content div div.title-category').text
      new_article.title = article.css('div.article-content div div h1 span.grey-text').text + ' : ' + article.css('div.article-content div div h1 span.black-text').text
      # new_article.author = article.css('div.article-head__author div em a').text
      anchor = []
      article.css('div.published').each do |header|
        anchor << header.text

      end
      if article.at('div.category-content div div.published a').nil?
        author_exist = Author.where(['lower(name) like ? ', ('Le soir auteur').downcase ])
      else
        author_exist = Author.where(['lower(name) like ? ',
                                     article.at('div.category-content div div a').text.downcase ])
      end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('div.category-content div div a').nil? ? 'Le soir auteur' : article.at('div.category-content div div a').text
        new_author.medium_id = @media.id
        new_author.save!
      else

        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name

      end
      new_article.author_id = new_author.id
      new_article.body = article.css('div.article-content div.text').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date = article.css('div.category-content div div.published').text
      date['le '] = ''
      # d = change_date_autobip_aps(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      # new_article.date_published =
      url_array = article.css('div.article-details div.picture img').map { |link| 'https://www.lesoirdalgerie.com' + link['src'] }
      new_article.url_image = url_array[0]
      begin
        new_article.image = Down.download(url_array[0]) if url_array[0].present?
      rescue Down::Error => e
        puts "Can't download this image #{url_array[0]}"
        puts e.message
        puts
        new_article.image = nil
      end
      #tags_array = article.css('ul.itemTags li').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      if new_article.save
        @articles_for_auto_tag.push(new_article)
      end
        ##tag_check_and_save(tags_array)if @media.tag_status == true
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
        articles_url_liberte << 'https://www.liberte-algerie.com' + link['href']# if link['class'] == 'main_article'
      end
      doc.css('div.right-side div.date-heure span.date').map do |date|
        last_dates << date.text
      end
    end
    last_dates = last_dates.map { |d| change_date_autobip_aps(d) }
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
      new_article.title = article.css('div#main-post span h4').text + ' : ' + article.css('div#main-post span h4').text
      #  new_article.author = article.css('div.article-head__author div em a').text
      if article.at('div#side-post div div p a').nil?
        author_exist = Author.where(['lower(name) like ? ', ('Liberté auteur').downcase ])
      else
        author_exist = Author.where(['lower(name) like ? ',
                                     article.at('div#side-post div div p a').text.downcase ])
      end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('div#side-post div div p a').nil? ? 'Liberté auteur' : article.at('div#side-post div div p a').text.delete(' ')
        new_author.medium_id = @media.id
        new_author.save!
      else

        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name

      end
      new_article.author_id = new_author.id
      new_article.body = article.css('div#text_core').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date = article.css('div#side-post div div.date-heure span')[0].text.delete(' ')

      # d = change_date_autobip_aps(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      # new_article.date_published =
      url_array = article.css('div.media img.post-image').map { |link|  link['src'] }
      new_article.url_image = url_array[0]
      begin
        new_article.image = Down.download(url_array[0]) if url_array[0].present?
      rescue Down::Error => e
        puts "Can't download this image #{url_array[0]}"
        puts e.message
        puts
        new_article.image = nil
      end
      #tags_array = article.css('ul.itemTags li').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      if new_article.save
        @articles_for_auto_tag.push(new_article)
      end
      ##tag_check_and_save(tags_array)if @media.tag_status == true
    end
    puts "json: { crawling_status_liberte: 'ok' }"
  end
    # end method to get _liberte articles








    # start method to get algerie360
  def get_articles_algerie360(url_media_array)
    articles_url_algerie360 = []
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
      doc.css('div.entry__header h2 a').map do |link|
        articles_url_algerie360 << link
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
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_algerie360_after_check = articles_url_algerie360 - list_articles_url
    articles_url_algerie360_after_check.map do |link|
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
      new_article.category_article = 'algerie360.com'
      new_article.title = article.css('h1.single-post__entry-title mt-0').text
      #  new_article.author = article.css('div.article-head__author div em a').text
      if article.at('li.entry__meta-author a').nil?
        author_exist = Author.where(['lower(name) like ? ', ('Liberté auteur').downcase ])
      else
        author_exist = Author.where(['lower(name) like ? ',
                                     article.at('li.entry__meta-author a').text.downcase ])
      end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('li.entry__meta-author a').nil? ? 'Liberté auteur' : article.at('li.entry__meta-author a').text.delete(' ')
        new_author.medium_id = @media.id
        new_author.save!
      else

        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name

      end
      new_article.author_id = new_author.id
      new_article.body = article.css('div.entry__article').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date_with_time = article.css('li.entry__meta-date pt-xl-1 d-block d-md-inline').text
      date_with_a = date_with_time.text.split('à')[0]
      date = date_with_a
      d = change_date_maghrebemergen(date)
      new_article.date_published = d.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      # new_article.date_published =
      url_array = article.css('div.entry__img-holder px-2 px-md-0 img').map { |link|  link['src'] }
      new_article.url_image = url_array[0]
      begin
        new_article.image = Down.download(url_array[0]) if url_array[0].present?
      rescue Down::Error => e
        puts "Can't download this image #{url_array[0]}"
        puts e.message
        puts
        new_article.image = nil
      end
      #tags_array = article.css('ul.itemTags li').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      if new_article.save
        @articles_for_auto_tag.push(new_article)
      end
      ##tag_check_and_save(tags_array)if @media.tag_status == true
    end
    puts "json: { crawling_status_algerie360: 'ok' }"
  end
    # end method to get algerie360
















    # start method to get bilad articles
  def get_articles_bilad(url_media_array)
    articles_url_bilad = []
    last_dates = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(open(url, 'User-Agent' => 'ruby'))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end
      doc.css('div.typo a.post_title').map do |link|
        articles_url_bilad << 'http://www.elbilad.net' + link['href']
      end
      doc.css('span.date').map do |date|
        last_dates << date.text.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      end
    end
    articles_url_bilad = articles_url_bilad.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_bilad_after_check = articles_url_bilad - list_articles_url
    articles_url_bilad_after_check.map do |link|


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
      new_article.category_article = article.css('div#right_area a').text
      new_article.title = article.css('div.right_area h1').text
      # new_article.author = article.css('div.article-head__author div em a').text
      auteur_date = article.css('div#post_conteur .date_heure').map(&:text)
      author_exist = if auteur_date[1].nil?
                       Author.where(['lower(name) like ? ', ('Bilad auteur').downcase ])
                     else
                       Author.where(['lower(name) like ? ',
                                     auteur_date[1].downcase ])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = auteur_date[1].nil? ? 'Bilad auteur' : auteur_date[1]
        new_author.medium_id = @media.id
        new_author.save!
      else

        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name

      end
      new_article.author_id = new_author.id
      new_article.body = article.css('#flash_post_head p').inner_html + article.css('#text_space p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      new_article.date_published =  auteur_date[0].to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('#post_banner img').map { |link| link['src'] }
      new_article.url_image = url_array[0]
      begin
           if url_array[0].present?
             new_article.image = Down.download(url_array[0])
           end
         rescue Down::Error => e
           puts "Can't download this image #{url_array[0]}"
           puts e.message
           puts
           new_article.image = nil
         end
      tags_array = article.css('#tags a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      if new_article.save
        @articles_for_auto_tag.push(new_article)
      end
      #tag_check_and_save(tags_array)if @media.tag_status == true
    end
    puts "json: { crawling_status_aps: 'ok' }"
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
      end
      doc.css('article a.elementor-post__thumbnail__link').map do |link|

        articles_url_maghrebemergent << link['href']
      end
      doc.css('article div div span.elementor-post-date').map do |date|
        last_dates << date.text
      end
    end
    last_dates = last_dates.map { |d| change_date_maghrebemergen(d) }
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
      author_exist = Author.where(['lower(name) like ? ', ('Maghrebemergent auteur').downcase ])
    else
      author_exist = Author.where(['lower(name) like ? ',
                                   article.at('div.elementor-widget-container ul li a span.elementor-icon-list-text elementor-post-info__item elementor-post-info__item--type-author').text.downcase ])
    end

    new_author = Author.new
    if author_exist.count.zero?

      new_author.name = article.at('div.elementor-widget-container ul li a span.elementor-icon-list-text elementor-post-info__item elementor-post-info__item--type-author').nil? ? 'Maghrebemergent auteur' : article.at('div.elementor-widget-container ul li a span.elementor-icon-list-text elementor-post-info__item elementor-post-info__item--type-author').text
      new_author.medium_id = @media.id
      new_author.save!
    else

      new_author.id = author_exist.first.id
      new_author.name = author_exist.first.name

    end
    new_article.author_id = new_author.id
    new_article.body = article.css('div.elementor-element.elementor-element-c93088c.elementor-widget.elementor-widget-theme-post-content').inner_html
    new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
    # date = article.at('p.text-capitalize span').text
    # date[','] = ''
    date = article.at('div.elementor-widget-container ul li a span.elementor-icon-list-text.elementor-post-info__item.elementor-post-info__item--type-date').text
    d = change_date_maghrebemergen(date)
    new_article.date_published = d.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    url_array = article.css('div.elementor-element.elementor-element-c05ee34.elementor-widget.elementor-widget-theme-post-featured-image.elementor-widget-image div div img').map  { |link| link['src'] }
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
    if new_article.save
      @articles_for_auto_tag.push(new_article)
    end
    # #tag_check_and_save(tags_array)
  end
    puts "json: { crawling_status_aps: 'ok' }"
  end
    # end method to get maghrebemergent articles
    #


    # start method to get elmoudjahid articles
  def get_articles_elmoudjahid_fr(url_media_array)
    articles_url_elmoudjahid = []
    last_dates = []
    new_last_dates = []
    count = 0
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end
      doc.css('article ul li h2 a').map do |link|
        articles_url_elmoudjahid << link['href'] # if link['class'] == 'main_article'
      end
      # doc.css('#main > div.UnCat > div > ul > li > a').map do |link|
        # articles_url_elmoudjahid6 << link['href'] # if link['class'] == 'main_article'
        # end
      # doc.css('#main > div.CBox > div > h4 > a').map do |link|
        # articles_url_elmoudjahid << link['href'] # if link['class'] == 'main_article'
        #  end
      # if doc.at('li p')['style'] == 'width: 520px;'
        #  first_date = doc.at('li p span').text
        # end
      # last_dates << first_date.split(':')[0].to_datetime
      doc.css('article ul li ul li').map do |date|
        last_dates << date.text unless date.text.include? ':'
      end
      last_dates.first(12).map do |date|
        new_last_dates << date.to_datetime
      end
    end
    # last_dates = last_dates.map { |d| change_date_maghrebemergen(d) }
    # last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 })}
    articles_url_elmoudjahid = articles_url_elmoudjahid.reject(&:nil?)
    last_dates = new_last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)

    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_elmoudjahid_after_check = articles_url_elmoudjahid - list_articles_url

    #  articles_url_elmoudjahid6.map do |article|

      #   if Article.where(medium_id: @media.id).where(url_article: article)[0].nil?
        #   articles_url_elmoudjahid_after_check << article
        #  end
      #  end
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
      category = article.css('aside ul.list-details li.text-uppercase a').text
      new_article.category_article = category
      new_article.title = article.css('header.heading-article h1').text


      if article.at('p.text-muted').nil?
        author_exist = Author.where(['lower(name) like ? ', ('Elmoudjahid-fr auteur').downcase ])
      else
        author_exist = Author.where(['lower(name) like ? ',
                                     article.at('p.text-muted').text.downcase ])
      end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('p.text-muted').nil? ? 'Elmoudjahid-fr auteur' : article.at('p.text-muted').text
        new_author.medium_id = @media.id
        new_author.save!
      else
        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name
      end
      new_article.author_id = new_author.id
      new_article.body = article.css('article.module-article section').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      get_dates = []

      article.css('aside ul li.text-uppercase ul li').map do |date|
        get_dates << date.text unless date.text.include? ':'
      end

      new_article.date_published = get_dates[0].to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('article section figure img').attr('data-src')
      new_article.url_image = url_array
      new_article.image = Down.download(url_array) if url_array.present?
      new_article.status = 'pending'
      new_article.save!

      if new_article.save
        count += 1
        @articles_for_auto_tag.push(new_article)
      end
      # #tag_check_and_save(tags_array)
    end
    puts 'json: { crawling_count_aps: count }'
  end
    # end method to get elmoudjahid articles
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
      if doc.at('li p')['style'] == 'width: 520px;'
        first_date = doc.at('li p span').text
      end
      last_dates << first_date.split(':')[0].to_datetime
      doc.css('div.ModliArtilUne span').map do |date|
        last_dates << date.text.split(':')[0].to_datetime
      end
    end
    # last_dates = last_dates.map { |d| change_date_maghrebemergen(d) }
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


      if article.at('p.text-muted').nil?
        author_exist = Author.where(['lower(name) like ? ', ('Elmoudjahid auteur').downcase ])
      else
        author_exist = Author.where(['lower(name) like ? ',
                                     article.at('p.text-muted').text.downcase ])
      end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('p.text-muted').nil? ? 'Elmoudjahid auteur' : article.at('p.text-muted').text
        new_author.medium_id = @media.id
        new_author.save!
      else
        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name
      end
      new_article.author_id = new_author.id
      new_article.body = article.css('#text_article').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      new_article.date_published = article.css('#contenu > div.At > span').text.split(':')[1].to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('#articlecontent > div.TxArtcile > div.ImgCapt > img').map { |link| link['src'] }
      new_article.url_image = url_array[0]
      begin
           if url_array[0].present?
             new_article.image = Down.download(url_array[0])
           end
         rescue Down::Error => e
           puts "Can't download this image #{url_array[0]}"
           puts e.message
           puts
           new_article.image = nil
         end
      new_article.status = 'pending'
      new_article.save!
      if new_article.save
        @articles_for_auto_tag.push(new_article)
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
      doc.css('h3.panel-title a').map do |link|
        unless link.css('i').present?
          articles_url_elkhabar << 'https://www.elkhabar.com' + link['href']
        end
      end
      doc.css('time').map do |date|
        last_dates << date['datetime']
      end
    end

    last_dates = last_dates.map { |d| change_date_maghrebemergen(d) }
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
      if article.css('span.category-blog').present?
        new_article.category_article = article.css('span.category-blog').text
      end
      if article.css('h2.title').present?
        new_article.title = article.css('h2.title').text
      end
      # new_article.author = article.css('div.article-head__author div em a').text

      if article.at('span.time-blog b').present?
        author_exist = Author.where(['lower(name) like ? ',
                                     article.at('span.time-blog b').text.downcase ])

      else
        author_exist = Author.where(['lower(name) like ? ', ('Elkhabar auteur').downcase ])
      end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at('span.time-blog b').present? ? article.at('span.time-blog b').text :  'Elkhabar auteur'
        new_author.medium_id = @media.id
        new_author.save!
      else

        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name

      end
      new_article.author_id = new_author.id
      new_article.body = article.css('div#article_body_content').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('time[datetime]')['datetime']
      # d = change_date_maghrebemergen(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      if article.css('div#article_img img').present?
        url_array = article.css('div#article_img img').map { |link| 'https://www.elkhabar.com' + link['src'] }
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
      if article.css('div#article_tags_title').present?
        tags_array = article.css('div#article_tags_title').map(&:text)
      end
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!

      if new_article.save
        count += 1
        @articles_for_auto_tag.push(new_article)
      end
      # #tag_check_and_save(tags_array) if @media.tag_status == true
    end
   # render json: { crawling_status_elkhabar: count }
    puts "json: { crawling_status_elkhabar: 'ok' }"
  end
    # end method to get elkhabar articles
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


        articles_url_elikhbaria << link['href']# if link['class'] == 'main_article'

      end
      doc.css('time').map do |date|
        last_dates << date['datetime']
      end
    end
    # last_dates = last_dates.map { |d| change_date_maghrebemergen(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
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
      author_exist = Author.where(['lower(name) like ? ', ('Elikhbaria auteur').downcase ])
      # else
      #  author_exist = Author.where(['lower(name) like ? ',
      #                              article.at("div.subinfo b").text.downcase ])
      # end


      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = 'Elikhbaria auteur'
        new_author.medium_id = @media.id
        new_author.save!
      else

        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name

      end

      new_article.author_id = new_author.id
      new_article.body = article.css('div.entry-content.clearfix.single-post-content').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('time[datetime]')['datetime']
      # d = change_date_maghrebemergen(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24)
      url_array = article.css('div.post-header div.single-featured > a').map  { |link| link['href'] }# and link['class'] == 'b-loaded'
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
      new_article.save!
      if new_article.save
        @articles_for_auto_tag.push(new_article)
      end
      #tag_check_and_save(tags_array) if @media.tag_status == true
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
    # last_dates = last_dates.map { |d| change_date_maghrebemergen(d) }
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
        author_exist = Author.where(['lower(name) like ? ', ('Algerieco auteur').downcase ])
      else
        author = article.at('div.td-module-meta-info div').text
        author['Par '] = ''
        author[' - '] = ''
        author_exist = Author.where(['lower(name) like ? ',
                                     author.downcase ])
      end

      new_author = Author.new
      if author_exist.count.zero?
        author = article.at('div.td-module-meta-info div').text
        author['Par '] = ''
        author[' - '] = ''
        new_author.name = article.at('div.td-module-meta-info div').text.nil? ? 'Algerieco auteur' : author
        new_author.medium_id = @media.id
        new_author.save!
      else

        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name

      end
      new_article.author_id = new_author.id
      new_article.body = article.css('div.td-post-content').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      new_article.body = new_article.body.gsub(%r{<div class="td-post-featured-image">(.*?)<\/a><\/div>}, '')
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('time[datetime]')['datetime']
      # d = change_date_maghrebemergen(date)
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

      #tags_array = article.css('div#article_tags_title').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      if new_article.save
        @articles_for_auto_tag.push(new_article)
      end
        ##tag_check_and_save(tags_array)
    end
    puts "json: { crawling_status_aps: 'ok' }"
  end
    # end method to get algerieco articles



    # start method to get chiffreaffaire articles
  def get_articles_chiffreaffaire(url_media_array)
    articles_url_chiffreaffaire = []
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
      doc.css('div.listing h2 a').map do |link|


        articles_url_chiffreaffaire << link['href']

      end
      doc.css('time').map do |date|
        last_dates << date['datetime']
      end
    end
    # last_dates = last_dates.map { |d| change_date_maghrebemergen(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (2.0 / 24) }
    articles_url_chiffreaffaire = articles_url_chiffreaffaire.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_chiffreaffaire_after_check = articles_url_chiffreaffaire - list_articles_url
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
        author_exist = Author.where(['lower(name) like ? ', ('Chiffreaffaire auteur').downcase ])
      else
        author = article.at('span.post-author-name').text
        author['par '] = ''
        author_exist = Author.where(['lower(name) like ? ',
                                     author.downcase ])
      end

      new_author = Author.new
      if author_exist.count.zero?
        author = article.at('span.post-author-name').text
        author['par '] = ''
        new_author.name = article.at('span.post-author-name').text.nil? ? 'Chiffreaffaire auteur' : author
        new_author.medium_id = @media.id
        new_author.save!
      else

        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name

      end
      new_article.author_id = new_author.id
      new_article.body = article.css('div.entry-content').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('time[datetime]')['datetime']
      # d = change_date_maghrebemergen(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (2.0 / 24)
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
      new_article.save!
      if new_article.save
        @articles_for_auto_tag.push(new_article)
      end
      #tag_check_and_save(tags_array)
    end
    puts "json: { crawling_status_aps: 'ok' }"
  end
    # end method to get chiffreaffaire articles


    # start method to get elhiwar articles
  def get_articles_elhiwar(url_media_array)
    articles_url_elhiwar = []
    last_dates = []
    url_media_array.map do |url|
      #doc = Nokogiri::HTML(URI.open(url))
      begin
        doc = Nokogiri::HTML(URI.open(url))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
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
    # last_dates = last_dates.map { |d| change_date_maghrebemergen(d) }
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
        author_exist = Author.where(['lower(name) like ? ', ('Elhiwar auteur').downcase ])
      else
        author = article.at('span.author').text
        author_exist = Author.where(['lower(name) like ? ',
                                     author.downcase ])
      end

      new_author = Author.new
      if author_exist.count.zero?
        author = article.at('span.author').text
        new_author.name = article.at('span.author').text.nil? ? 'Elhiwar auteur' : author
        new_author.medium_id = @media.id
        new_author.save!
      else

        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name

      end
      new_article.author_id = new_author.id
      new_article.body = article.css('div.penci-entry-content').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('time[datetime]')['datetime']
      # d = change_date_maghrebemergen(date)
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
      new_article.save!
      if new_article.save
        @articles_for_auto_tag.push(new_article)
      end
        # #tag_check_and_save(tags_array)
    end
    puts "json: { crawling_status_aps: 'ok' }"
  end
    # end method to get elhiwar articles


    # start method to get visadz articles
  def get_articles_visadz(url_media_array)
    articles_url_visadz = []
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
    # last_dates = last_dates.map { |d| change_date_maghrebemergen(d) }
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
      new_article.category_article = article.css('div.article__cat').text
      new_article.title = article.css('h1.article__title').text
      # new_article.author = article.css('div.article-head__author div em a').text

      if article.at('em.article__atnm').text.nil?
        author_exist = Author.where(['lower(name) like ? ', ('Visa Algérie auteur').downcase ])
      else
        author = article.at('em.article__atnm').text
        author_exist = Author.where(['lower(name) like ? ',
                                     author.downcase ])
      end

      new_author = Author.new
      if author_exist.count.zero?
        author = article.at('em.article__atnm').text
        new_author.name = article.at('em.article__atnm').text.nil? ? 'Visa Algérie auteur' : author
        new_author.medium_id = @media.id
        new_author.save!
      else

        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name

      end
      new_article.author_id = new_author.id
      new_article.body = article.css('p.article__desc').inner_html + article.css('div.article__cntn').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('time[datetime]')['datetime']
      # d = change_date_maghrebemergen(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24)
      #url_array = article.css('div.entry-media img').map {  |link| link['src'] }
      # url_image = url_array[0]
      # new_article.image = Down.download(url_array[0]) if url_array[0].present?
      # tags_array = article.css('div.entry-terms a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      if new_article.save
        @articles_for_auto_tag.push(new_article)
      end
      # #tag_check_and_save(tags_array)
    end
    puts "json: { crawling_status_aps: 'ok' }"
  end
    # end method to get elhiwar articles



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
    last_dates = last_dates.map { |d| change_date_autobip_aps(d) }
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


      author_exist = Author.where(['lower(name) like ? ', ('Santenews auteur').downcase ])


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
      date = change_date_autobip_aps(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('div.single-post-thumb  img').map { |link| link['src'] }
      url_image = url_array[0]
      begin
           if url_array[0].present?
             new_article.image = Down.download(url_array[0])
           end
         rescue Down::Error => e
           puts "Can't download this image #{url_array[0]}"
           puts e.message
           puts
           new_article.image = nil
         end
      # tags_array = article.css('div.entry-terms a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      if new_article.save
        @articles_for_auto_tag.push(new_article)
      end
      # #tag_check_and_save(tags_array)
    end
    puts "json: { crawling_status_aps: 'ok' }"
  end
    # end method to get elhiwar articles


      # tag_check_and_savetag_check_and_save
  def tag_check_and_save(tags_array)
    tags_array.map do |t|
      tag_exist = Tag.where(['lower(name) like ? ', t.downcase.strip ]).count
      next unless tag_exist.zero?

      tag = Tag.new
      tag.name = t.strip
      tag.save!
    end
  end

  # change_date_autobip_aps
  def change_date_autobip_aps(d)

    d.split.map { |m|
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
      else
        m
      end
    }.join(' ')
  end
  # change_date_autobip_aps
  #

  # change_date_maghrebemergent
  def change_date_maghrebemergen(d)

    d.split.map { |m|
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
      else
        m
      end
    }.join(' ')
  end
  # change_date_maghrebemergents









  #auto_tag


  def auto_tag(articles_for_autoTag)
    # slug_id = params[:slug_id]
    # start_date = params[:start_date]
    # end_date = params[:start_date]



    campaigns = Campaign.all
    puts "campaigns count#{campaigns.count}"
    campaigns.map do |campaign|
      all_tags = campaign.tags.empty? ? [] :  campaign.tags.where(status: true)
      camp_media = campaign.media
      camp_media_array = camp_media.map(&:id)
      articles = []
    # all_tags = Tag.where(status: true)
      next if articles_for_autoTag.empty?

      filtered_articles = articles_for_autoTag.where(medium_id: camp_media_array)

      @tags = []
      filtered_articles.map do |article|

        @tags_objects = []
        all_tags.map do |tag|
          if article.body.downcase.include? tag.name.downcase
            @tags << tag.name unless @tags.include? tag.name
            @tags_objects << tag unless @tags_objects.include? tag.name
          end
          if article.title.downcase.include? tag.name.downcase
            @tags << tag.name unless @tags.include? tag.name
            @tags_objects << tag unless @tags_objects.include? tag.name
          end
        end
        old_tags = article.media_tags.nil? ? [] : article.media_tags.split(',')
        old_tags << @tags
        #  article.media_tags = old_tags.join(',')
        @tags_objects.map do |tag_object|
          next if ArticleTag.where(article_id: article.id, tag_id: tag_object.id, slug_id: slug_id, campaign_id: campaign.id).present?

          @article_tag = ArticleTag.new article_id: article.id, tag_id: tag_object.id, slug_id: slug_id, campaign_id: campaign.id
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
      puts "Nombre d'articles :" + articles.count.to_s
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
      #camp_media_array = camp_media.map(&:id)
      articles.map do |article|
        article_tags = article.tags.map(&:id)
        tag_to_send << @tags
        #status_tag = camp_tags_array.any? { |i| article_tags.include? i }
        #status_media = camp_media_array.any? { |i| [article.medium_id].include? i }
        article_to_send << article
          #  article_to_send << article if status_tag == true && status_media == true
      end
      if article_to_send.length.positive?
        users.map { |user| UserMailer.taggedarticles(article_to_send, user, tag_to_send.uniq).deliver }
      end





    end
    puts "json: { tags: 'ok' }"
    #render json: { tags: 'ok' }
  end



  #auto_tag

end
