class Api::V1::ArticlesController < ApplicationController
  # before_action :authenticate_user!
  before_action :set_article, only: %i[show update destroy]
  require 'nokogiri'
  require 'open-uri'
  require 'openssl'
  # GET / client articles
  def articles_client
    slug_id = get_slug_id

    campaign = Campaign.where(slug_id: slug_id)
    media = campaign[0].media
    all_tags = campaign[0].tags
    media_ids = []
    media.map do |media|
      media_ids << media['id']
    end

    conditions = {}
    #conditions[:status] = 'confirmed'
    conditions[:medium_id] = if params[:media_id].blank?
                               media_ids
                             else
                               params[:media_id].split(',')
    end

    unless params[:medium_type].blank?
      conditions[:medium_type] = params[:medium_type].split(',')
    end

    unless params[:media_area].blank?
      conditions[:media_area] = params[:media_area]
    end

    unless params[:authors_ids].blank?
      conditions[:author_id] = params[:authors_ids].split(',')
    end

    unless params[:language].blank?
      conditions[:language] = params[:language].split(',')
    end


    unless params[:start_date].blank?
      conditions[:date_published] = { gte: params[:start_date].to_datetime.change({ hour: 0, min: 0, sec: 0 }), lte: params[:end_date].to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
    end

    unless params[:tag_name].blank?
      conditions[:tag_name] = params[:tag_name]
    end
    # conditions[:tags] = params[:tag] unless params[:tag].blank?

    @articles_client = Article.search '*',
                              suggest: true,
                              page: params[:page],
                              per_page: params[:per_page]


    set_pagination_headers :articles
    json_string = ArticleSerializer.new(@articles_client)
    media_serializer = MediumSerializer.new(media)

    render json: { articles: json_string, media: media_serializer, tags: all_tags }
  end

  # GET /articlesclass
  def index
    if params[:media_id].blank?
      @articles = Article.order(order_and_direction).page(page).per(per_page)
    else
      @articles = Article.order(order_and_direction).where(medium_id: params[:media_id].split(',')).page(page).per(per_page)
    end
    set_pagination_headers :articles
    json_string = ArticleSerializer.new(@articles, include: %i[medium]).serializable_hash.to_json
    render json: json_string
  end

  # GET /articles/1
  def show

    similar = @article.similar(fields: [:title])
    similar_json_string = ArticleSerializer.new(similar)
    json_string = ArticleSerializer.new(@article, include: %i[medium tags author])

    render json: {article:json_string, similar: similar_json_string }
  end

  # POST /articles
  def create
    @article = Article.new(article_params)

    if @article.save
      render json: @article, status: :created
    else
      render json: @article.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /articles/1
  def update
    if @article.update(article_params)
      json_string = ArticleSerializer.new(@article).serializable_hash.to_json
      render json: json_string
    else
      render json: @article.errors, status: :unprocessable_entity
    end
  end

  # auto tags@article_for_indexing
  def auto_tag
    articles = []
    all_tags = Tag.where(status: true)
    articles_not_tagged = Article.all.where(is_tagged: nil)
    articles_not_tagged.map do |article|
      @tags = []
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
      article.tags = @tags_objects
      article.is_tagged = true if @tags_objects.length.positive?
      article.save!
      articles << article if @tags_objects.length.positive?
    end
    campaigns = Campaign.all
    campaigns.map do |camp|
      users = User.where(slug_id: camp.slug_id)
      camp_tags = camp.tags
      camp_media = camp.media
      article_to_send = []
      camp_tags_array = camp_tags.map(&:id)
      camp_media_array = camp_media.map(&:id)
      articles.map do |article|
        article_tags = article.tags.map(&:id)
        status_tag = camp_tags_array.any? { |i| article_tags.include? i }
        status_media = camp_media_array.any? { |i| [article.medium_id].include? i }
        article_to_send << article if status_tag == true && status_media == true
      end
      users.map { |user| UserMailer.taggedarticles(article_to_send, user, camp_tags).deliver }
    end


    render json: { tags: 'ok' }
  end
  # auto tags


  # export PDF
  def pdf_export
    id = params[:id]
    @article = Article.find(id)
    @html = get_html
    pdf = WickedPdf.new.pdf_from_string('<h1>Seifou eddine NOUARA </h1>')
    send_data pdf, filename: 'file.pdf'
  end

  def get_html
    `<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
 <style>
      div.alwaysbreak { page-break-before: always; }
div.nobreak:before { clear:both; }
div.nobreak { page-break-inside: avoid; }
    </style>
  </head>
  <body>

<div leftmargin="0" marginwidth="0" topmargin="0" marginheight="0" offset="0"
      style="height:auto !important;width:100% !important; margin-bottom: 40px;">
      <div class="justify-content-center d-flex">
        <table bgcolor="#ffffff" border="0" cellpadding="0" cellspacing="0"
          style="max-width:600px; background-color:#ffffff;border:1px solid #e4e2e2;border-collapse:separate !important; border-radius:10px;border-spacing:0;color:#242128; margin:0;padding:40px;"
          heigth="auto">
          <tbody>
            <tr>
              <td align="right" valign="center"
              style="padding-bottom:40px;border-top:0;height:100% !important;width:100% !important;">
              <span style="color: #8f8f8f; font-weight: normal; line-height: 2; font-size: 14px;">
                  Media : #{@article.medium.name}</span>
              </td>
              <td align="right" valign="center"
                style="padding-bottom:40px;border-top:0;height:100% !important;width:100% !important;">
                <span style="color: #8f8f8f; font-weight: normal; line-height: 2; font-size: 14px;">Date de publication : #{@article.date_published.strftime('%d - %m - %Y') }</span>
              </td>
            </tr>
            <tr>
              <td colSpan="2" style="padding-top:10px;border-top:1px solid #e4e2e2">
                <h2 style="color:#303030; font-size:18px; line-height: 1.6; font-weight:500;">#{@article.title}</h2>
                #{@article.body}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="justify-content-center d-flex">
        <table style="margin-top:30px; padding-bottom:20px;; margin-bottom: 40px;">
          <tbody>
            <tr>
              <td align="center" valign="center">
                <p
                  style="font-size: 12px;line-height: 1; color:#909090; margin-top:0px; margin-bottom:5px; ">
                  PDF généré par MediaDZ app le  #{Date.today.strftime("%d - %m - %Y")}
                </p>
                <p style="font-size: 12px; line-height:1; color:#909090;  margin-top:5px; margin-bottom:5px;">
                  <a href="#" style="color: #00365a;">Alger</a> , <a href="#"
                    style="color: #00365a; ">Algerie</a>
                </p>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </body>
</html>`
  end

  # export PDF




  def crawling
    @all_tags = Tag.all
    @media = Medium.find(params[:media_id])
    if @media.url_crawling?
      url_media_array = @media.url_crawling.split(',')
      get_articles(url_media_array)
    else
      render json: { crawling_status: 'No url_crawling', media: @media.name, status: 'error' }
    end

  end

  def self.crawling_job
    # @all_tags = Tag.all
    @media = Medium.all

    @media.map do |m|
      if m.url_crawling?
        url_media_array = m.url_crawling.split(',')
        get_articles(url_media_array)
      else
        render json: { crawling_status: 'No url_crawling', media: m.name, status: 'error' }
      end
    end



  end

  # DELETE /articles/1
  def destroy
    @article.destroy
  end

  def search_article
    result_articles = Article.search params[:search],
                                     fields: %i[title body author_name],
                                     suggest: true,
                                     page: params[:page],
                                     per_page: params[:per_page]

    @articles_res = result_articles

    set_pagination_headers :articles_res
    json_string = ArticleSerializer.new(@articles_res)

    render json: { result_articles: json_string, time: result_articles.took, suggestions: @articles_res.suggestions }

  end

  def change_status
    ids = params[:ids].split(',')
    Article.where(id: [ids]).update_all(status: params[:status])

    #  if a.positive?
    #   render json: {message: 'Change status succeed'}
    #  else
    #   render json: 'Change status failed', status: :unprocessable_entity
    #  end
  end

  # GET /articles_for_sorting
  def articles_for_sorting
    if params[:media_id].blank?
      #  @articles = Article.order(order_and_direction).where.not(status: 'checked').page(page).per(per_page)
      @articles = Article.order(order_and_direction).page(page).per(per_page)
    else
      # @articles = Article.order(order_and_direction).where.not(status: 'checked').where(medium_id: params[:media_id].split(',') ).page(page).per(per_page)
      @articles = Article.order(order_and_direction).where(medium_id: params[:media_id].split(',')).page(page).per(per_page)

    end
    archived = Article.where(status: 'archived').count
    pending = Article.where(status: 'pending').count
    set_pagination_headers :articles
    json_string = ArticleSerializer.new(@articles)
    stats = { stats: { archived: archived,
                       pending: pending } }
    render json: { articles: json_string, archived: archived, pending: pending }
  end


  private

  def get_articles(url_media_array)
    case @media.name
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
    when 'ELMOUDJAHID'
      get_articles_elmoudjahid(url_media_array)
    when 'ELMOUDJAHID-FR'
      get_articles_elmoudjahid(url_media_array)
    when 'ELKHABAR'
      get_articles_elkhabar(url_media_array)
    when 'ELIKHABARIA'
      get_articles_elikhbaria(url_media_array)
    when 'ALGERIECO'
      get_articles_algerieco(url_media_array)
    when 'CHIFFREAFFAIRE'
      get_articles_chiffreaffaire(url_media_array)
    when 'ELHIWAR'
      get_articles_elhiwar(url_media_array)
    when 'VISAALGERIE'
      get_articles_visadz(url_media_array)
    when 'SANTENEWS'
      get_articles_santenews(url_media_array)
    else
      render json: { crawling_status: 'No media name found!! ', status: 'error' }
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_article
    @article = Article.find(params[:id])
  end

  # start method to get autobip articles
  def get_articles_autobip(url_media_array)
    articles_url_autobip = []
    last_dates = []
    url_media_array.map do |url|
      doc = Nokogiri::HTML(URI.open(url))
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
      article = Nokogiri::HTML(URI.open(URI.escape(link)))

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
      d = change_date_autobip_aps(article.at("//span[@itemprop = 'datePublished']").text)
      new_article.date_published = d.to_datetime
      url_array = article.css('.fotorama.mnmd-gallery-slider.mnmd-post-media-wide img').map { |link| link['src'] }
      new_article.url_image = url_array[0]
      new_article.image = Down.download(url_array[0]) if url_array[0].present?
      tags_array = article.css('a.post-tag').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      tag_check_and_save(tags_array) if @media.tag_status == true
      end

    render json: { crawling_status_autobip: 'ok' }
  end
  # end method to get autobip articles

  # start method to get elcherouk articles
  def get_articles_elcherouk(url_media_array)
    articles_url_cherouk = []
    last_dates = []
    url_media_array.map do |url|
      doc = Nokogiri::HTML(URI.open(url))
      doc.css('article div div h2.title.title--small a').map do |link|
        articles_url_cherouk << link['href']
      end
      doc.css('ul.article-horiz__meta li time').map do |date|
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
      article = Nokogiri::HTML(URI.open(link))
      new_article = Article.new
      new_article.url_article = link
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('div.around.around--section ul li a span').text
      new_article.title = article.css('h2.title.title--middle.unshrink em').text
      # new_article.author = article.css('div.article-head__author div em a').text

      author_exist = Author.where(['lower(name) like ? ',
                                   article.css('div.article-head__author div em a').text.downcase ])

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.css('div.article-head__author div em a').text
        new_author.medium_id = @media.id
        new_author.save!
      else

        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name

      end
      new_article.author_id = new_author.id
      new_article.body = article.css('div.the-content').inner_html
      new_article.date_published = DateTime.parse article.css('ul.article-head__details time').text
      url_array = article.css('div.article-head__media-content div a').map do
      |link| link['href']
      end
      new_article.url_image = url_array[0]
      new_article.image = Down.download(url_array[0]) if url_array[0].present?
      tags_array = article.css('div.article-core__tags a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      tag_check_and_save(tags_array)if @media.tag_status == true
    end
    render json: { crawling_status_elcherouk: 'ok' }
  end
  # end method to get elcherouk articles


  # start method to get ennahar articles
  def get_articles_ennahar(url_media_array)
    articles_url_ennahar = []
    last_dates = []
    url_media_array.map do |url|
      doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.5'))
      doc.css('div.article__image.article__image--medium a').map do |link|
        articles_url_ennahar << link['href']
      end
      doc.css('time').map do |date|
        last_dates << date['datetime']
      end
    end
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0/24)}
    articles_url_ennahar = articles_url_ennahar.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_ennahar_after_check = articles_url_ennahar - list_articles_url
    articles_url_ennahar_after_check.map do |link|
      article = Nokogiri::HTML(URI.open(link, 'User-Agent' => 'ruby/2.6.5'))
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
      new_article.date_published = article.at('time[datetime]')['datetime'].to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0/24)
      url_array = article.css('body > div.article-section > div > div.article-section__main.wrap__main > article > div.full-article__featured-image > img').map { |link| link['src'] }
      new_article.url_image = url_array[0]
      new_article.image = Down.download(url_array[0]) if url_array[0].present?
      # tags_array = article.css('div.article-core__tags a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      # tag_check_and_save(tags_array)
    end
    render json: { crawling_status_elcherouk: 'ok' }
  end
  # end method to get ennahar articles


  # start method to get TSA articles
  def get_articles_tsa(url_media_array)
    articles_url_tsafr = []
    last_dates = []
    url_media_array.map do |url|
      doc = Nokogiri::HTML(URI.open(url))
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
      article = Nokogiri::HTML(URI.open(link))
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
      new_article.date_published = article.at('time[datetime]')['datetime'].to_datetime
      url_array = article.css('body > div.article-section > div > div.article-section__main.wrap__main > article > div.full-article__featured-image > img').map { |link| link['src'] }
      new_article.url_image = url_array[0]
      new_article.image = Down.download(url_array[0]) if url_array[0].present?
      # tags_array = article.css('div.article-core__tags a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      # tag_check_and_save(tags_array)
    end
    render json: { crawling_status_tsa: 'ok' }
  end
  # end method to get TSA articles


  # start method to get APS articles
  def get_articles_aps(url_media_array)
    articles_url_aps = []
    last_dates = []
    url_media_array.map do |url|
      doc = Nokogiri::HTML(URI.open(url))
      doc.css('#itemListLeading h3 a').map do |link|
        articles_url_aps << 'http://www.aps.dz' + link['href']# if link['class'] == 'main_article'
      end
      doc.css('span.catItemDateCreated').map do |date|
        last_dates << date.text
      end
    end
    last_dates = last_dates.map { |d| change_date_autobip_aps(d) }
    last_dates = last_dates.map{ |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 })}
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
      article = Nokogiri::HTML(URI.open(link))
      new_article = Article.new
      new_article.url_article = link
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('nav.wrap.t3-navhelper > div > ol > li a').text == "" ? article.css('body > div.t3-wrapper > nav.wrap.t3-navhelper > div > ol > li:nth-child(2) > span').text : article.css('nav.wrap.t3-navhelper > div > ol > li a').text
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
      date = article.css('span.itemDateCreated').text
      date['Publié le : '] = ''
      d = change_date_autobip_aps(date)
      new_article.date_published = d.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      # new_article.date_published =
      url_array = article.css('div.itemImageBlock span.itemImage img').map { |link| 'http://www.aps.dz'+ link['src'] }
      new_article.url_image = url_array[0]
      new_article.image = Down.download(url_array[0]) if url_array[0].present?
      tags_array = article.css('ul.itemTags li').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      tag_check_and_save(tags_array)if @media.tag_status == true
    end
    render json: { crawling_status_aps: 'ok' }
  end
  # end method to get APS articles



  # start method to get bilad articles
  def get_articles_bilad(url_media_array)
    articles_url_bilad = []
    last_dates = []
    url_media_array.map do |url|
      doc = Nokogiri::HTML(open(url, 'User-Agent' => 'ruby'))
      doc.css('div.typo a').map do |link|
        articles_url_bilad << 'http://www.elbilad.net' + link['href']
      end
      doc.css('span.date').map do |date|
        last_dates << date.text
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
      article = Nokogiri::HTML(open(link, 'User-Agent' => 'ruby'))
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

      new_article.date_published = auteur_date[0]
      url_array = article.css('#post_banner img').map { |link| link['src'] }
      new_article.url_image = url_array[0]
      new_article.image = Down.download(url_array[0]) if url_array[0].present?
      tags_array = article.css('#tags a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      tag_check_and_save(tags_array)if @media.tag_status == true
    end
    render json: { crawling_status_aps: 'ok' }
  end
  # end method to get bilad articles



  # start method to get maghrebemergent articles
  def get_articles_maghrebemergent(url_media_array)
    articles_url_maghrebemergent = []
    last_dates = []
    url_media_array.map do |url|
      doc = Nokogiri::HTML(URI.open(url))
      doc.css('h4.entry-title a').map do |link|

        articles_url_maghrebemergent <<  link['href']
      end
      doc.css('span.date').map do |date|
        last_dates << date.text
      end
    end
    last_dates = last_dates.map { |d| change_date_maghrebemergen(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 })}
    articles_url_maghrebemergent = articles_url_maghrebemergent.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_maghrebemergent_after_check = articles_url_maghrebemergent - list_articles_url
    articles_url_maghrebemergent_after_check.map do |link|
    article = Nokogiri::HTML(URI.open(link))
    new_article = Article.new
    new_article.url_article = link
    new_article.medium_id = @media.id
    new_article.language = @media.language
    new_article.category_article = article.css('span.post-category').text
    new_article.title = article.css('h1.page-title').text
    # new_article.author = article.css('div.article-head__author div em a').text

    if article.at('p.text-muted').nil?
      author_exist = Author.where(['lower(name) like ? ', ('Maghrebemergent auteur').downcase ])
    else
      author_exist = Author.where(['lower(name) like ? ',
                                   article.at('p.text-muted').text.downcase ])
    end

    new_author = Author.new
    if author_exist.count.zero?

      new_author.name = article.at('p.text-muted').nil? ? 'Maghrebemergent auteur' : article.at('p.text-muted').text
      new_author.medium_id = @media.id
      new_author.save!
    else

      new_author.id = author_exist.first.id
      new_author.name = author_exist.first.name

    end
    new_article.author_id = new_author.id
    new_article.body = article.css('section.entry.pad-2').inner_html
    # date = article.at('p.text-capitalize span').text
    # date[','] = ''
    date = article.at('p.text-capitalize span').text
    d = change_date_maghrebemergen(date)
    new_article.date_published = d.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    url_array = article.css('div.entry-img img').map  { |link| link['data-lazy-src'] }
    new_article.url_image = url_array[0]
    new_article.image = Down.download(url_array[0]) if url_array[0].present?
    # tags_array = article.css('ul.itemTags li').map(&:text)
    # new_article.media_tags = tags_array.join(',')
    new_article.status = 'pending'
    new_article.save!
    # tag_check_and_save(tags_array)
  end
    render json: { crawling_status_aps: 'ok' }
  end
  # end method to get maghrebemergent articles
  #


  # start method to get elmoudjahid articles
  def get_articles_elmoudjahid(url_media_array)
    articles_url_elmoudjahid = []
    articles_url_elmoudjahid6 = []
    last_dates = []
    url_media_array.map do |url|
      doc = Nokogiri::HTML(URI.open(url))
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
      article = Nokogiri::HTML(URI.open(link))
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
      new_article.date_published = article.css('#contenu > div.At > span').text.split(':')[1].to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('#articlecontent > div.TxArtcile > div.ImgCapt > img').map { |link| link['src'] }
      new_article.url_image = url_array[0]
      new_article.image = Down.download(url_array[0]) if url_array[0].present?
      new_article.status = 'pending'
      new_article.save!
      # tag_check_and_save(tags_array)
    end
    render json: { crawling_status_aps: 'ok' }
  end
  # end method to get elmoudjahid articles
  # start method to get elmoudjahid_fr articles
  #
  #
  #


  def get_articles_elmoudjahid_fr(url_media_array)
    articles_url_elmoudjahid = []
    articles_url_elmoudjahid6 = []
    last_dates = []
    url_media_array.map do |url|
      doc = Nokogiri::HTML(URI.open(url))
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
      article = Nokogiri::HTML(URI.open(link))
      new_article = Article.new
      new_article.url_article = link
      new_article.medium_id = @media.id
      new_article.language = @media.language
      category = article.css('#contenu > div.path > ul > li:nth-child(3)').text
      category['>'] = ''
      new_article.category_article = category
      new_article.title = article.css('div.At h1 a').text


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
      new_article.body = article.css('#text_article').inner_html
      new_article.date_published = article.css('#contenu > div.At > span').text.split(':')[1].to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('#articlecontent > div.TxArtcile > div.ImgCapt > img').map { |link| link['src'] }
      new_article.url_image = url_array[0]
      new_article.image = Down.download(url_array[0]) if url_array[0].present?
      new_article.status = 'pending'
      new_article.save!
      # tag_check_and_save(tags_array)
    end
    render json: { crawling_status_aps: 'ok' }
  end
  # end method to get elmoudjahid_fr articles





  # start method to get elkhabar articles
  def get_articles_elkhabar(url_media_array)
    articles_url_elkhabar = []
    last_dates = []
    url_media_array.map do |url|
      doc = Nokogiri::HTML(URI.open(url))
      doc.css('a').map do |link|

        if link['class'] == 'main_article'
          articles_url_elkhabar << 'https://www.elkhabar.com' + link['href']
        end
      end
      doc.css('time').map do |date|
        last_dates << date['datetime']
      end
    end
    # last_dates = last_dates.map { |d| change_date_maghrebemergen(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 })}
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
      article = Nokogiri::HTML(URI.open(link))
      new_article = Article.new
      new_article.url_article = link
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = article.css('div#article_info a').text
      new_article.title = article.css('div.stuff_container h2').text
      # new_article.author = article.css('div.article-head__author div em a').text

      if article.at("div.subinfo b").text.nil?
        author_exist = Author.where(['lower(name) like ? ', ('Elkhabar auteur').downcase ])
      else
        author_exist = Author.where(['lower(name) like ? ',
                                     article.at("div.subinfo b").text.downcase ])
      end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = article.at("div.subinfo b").text.nil? ? 'Elkhabar auteur' : article.at("div.subinfo b").text
        new_author.medium_id = @media.id
        new_author.save!
      else

        new_author.id = author_exist.first.id
        new_author.name = author_exist.first.name

      end
      new_article.author_id = new_author.id
      new_article.body = article.css('div#article_body_content').inner_html
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('time[datetime]')['datetime']
      # d = change_date_maghrebemergen(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('div#article_img img').map { |link| 'https://www.elkhabar.com'+ link['src'] }
      url_image = url_array[0]
      new_article.image = Down.download(url_array[0]) if url_array[0].present?
      tags_array = article.css('div#article_tags_title').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      tag_check_and_save(tags_array)
    end
    render json: { crawling_status_aps: 'ok' }
  end
  # end method to get elkhabar articles
  #




  # start method to get elikhbaria articles
  def get_articles_elikhbaria(url_media_array)
    articles_url_elikhbaria = []
    last_dates = []
    url_media_array.map do |url|
      doc = Nokogiri::HTML(URI.open(url))
      doc.css('div.col-sm-8 div.listing > article > div > h2 > a').map do |link|


          articles_url_elikhbaria << link['href']# if link['class'] == 'main_article'

      end
      doc.css('time').map do |date|
        last_dates << date['datetime']
      end
    end
    # last_dates = last_dates.map { |d| change_date_maghrebemergen(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 })}
    articles_url_elikhbaria = articles_url_elikhbaria.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_elikhbaria_after_check = articles_url_elikhbaria - list_articles_url
    articles_url_elikhbaria_after_check.map do |link|
      article = Nokogiri::HTML(URI.open(link))
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
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('time[datetime]')['datetime']
      # d = change_date_maghrebemergen(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('div.post-header div.single-featured > a').map  { |link| link['href'] }# and link['class'] == 'b-loaded'
      url_image = url_array[0]
      new_article.image = Down.download(url_array[0]) if url_array[0].present?
      tags_array = article.css('div.entry-terms a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      tag_check_and_save(tags_array)
    end
    render json: { crawling_status_aps: 'ok' }
  end
  # end method to get elikhbaria articles



  # start method to get algerieco articles
  def get_articles_algerieco(url_media_array)
    articles_url_algerieco = []
    last_dates = []
    url_media_array.map do |url|
      doc = Nokogiri::HTML(URI.open(url))
      doc.css('div.td-pb-span8 h3.entry-title a.td-eco-title').map do |link|


      articles_url_algerieco << link['href']

      end
      doc.css('time').map do |date|
        last_dates << date['datetime']
      end
    end
    # last_dates = last_dates.map { |d| change_date_maghrebemergen(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 })}
    articles_url_algerieco = articles_url_algerieco.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_algerieco_after_check = articles_url_algerieco - list_articles_url
    articles_url_algerieco_after_check.map do |link|
      article = Nokogiri::HTML(URI.open(link))
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
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('time[datetime]')['datetime']
      # d = change_date_maghrebemergen(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('div.td-post-featured-image img').map { |link| link['src'] }
      url_image = url_array[0]
      new_article.image = Down.download(url_array[0]) if url_array[0].present?
      #tags_array = article.css('div#article_tags_title').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
        #tag_check_and_save(tags_array)
    end
    render json: { crawling_status_aps: 'ok' }
  end
  # end method to get algerieco articles




  # start method to get chiffreaffaire articles
  def get_articles_chiffreaffaire(url_media_array)
    articles_url_chiffreaffaire = []
    last_dates = []
    url_media_array.map do |url|
      doc = Nokogiri::HTML(URI.open(url))
      doc.css('div.listing h2 a').map do |link|


        articles_url_chiffreaffaire << link['href']

      end
      doc.css('time').map do |date|
        last_dates << date['datetime']
      end
    end
    # last_dates = last_dates.map { |d| change_date_maghrebemergen(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (2.0/24)}
    articles_url_chiffreaffaire = articles_url_chiffreaffaire.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_chiffreaffaire_after_check = articles_url_chiffreaffaire - list_articles_url
    articles_url_chiffreaffaire_after_check.map do |link|
      article = Nokogiri::HTML(URI.open(link))
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
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('time[datetime]')['datetime']
      # d = change_date_maghrebemergen(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (2.0/24)
      url_array = article.css('div.single-featured a').map { |link| link['href'] }
      url_image = url_array[0]
      new_article.image = Down.download(url_array[0]) if url_array[0].present?
      tags_array = article.css('div.entry-terms a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      tag_check_and_save(tags_array)
    end
    render json: { crawling_status_aps: 'ok' }
  end
  # end method to get chiffreaffaire articles






  # start method to get elhiwar articles
  def get_articles_elhiwar(url_media_array)
    articles_url_elhiwar = []
    last_dates = []
    url_media_array.map do |url|
      doc = Nokogiri::HTML(URI.open(url))
      doc.css('header.entry-header h2.entry-title a').map do |link|


        articles_url_elhiwar << link['href']

      end
      doc.css('time').map do |date|
        last_dates << date['datetime']
      end
    end
    # last_dates = last_dates.map { |d| change_date_maghrebemergen(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 })+ (1.0/24)}
    articles_url_elhiwar = articles_url_elhiwar.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_elhiwar_after_check = articles_url_elhiwar - list_articles_url
    articles_url_elhiwar_after_check.map do |link|
      article = Nokogiri::HTML(URI.open(link))
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
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('time[datetime]')['datetime']
      # d = change_date_maghrebemergen(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0})+ (1.0/24)
      url_array = article.css('div.entry-media img').map { |link| link['src'] }
      url_image = url_array[0]
      new_article.image = Down.download(url_array[0]) if url_array[0].present?
      # tags_array = article.css('div.entry-terms a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
        # tag_check_and_save(tags_array)
    end
    render json: { crawling_status_aps: 'ok' }
  end
  # end method to get elhiwar articles





  # start method to get visadz articles
  def get_articles_visadz(url_media_array)
    articles_url_visadz = []
    last_dates = []
    url_media_array.map do |url|
      doc = Nokogiri::HTML(URI.open(url))
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
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0/24)}
    articles_url_visadz = articles_url_visadz.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_visadz_after_check = articles_url_visadz - list_articles_url
    articles_url_visadz_after_check.map do |link|
      article = Nokogiri::HTML(URI.open(link))
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
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('time[datetime]')['datetime']
      # d = change_date_maghrebemergen(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0}) + (1.0/24)
      #url_array = article.css('div.entry-media img').map {  |link| link['src'] }
      # url_image = url_array[0]
      # new_article.image = Down.download(url_array[0]) if url_array[0].present?
      # tags_array = article.css('div.entry-terms a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      # tag_check_and_save(tags_array)
    end
    render json: { crawling_status_aps: 'ok' }
  end
  # end method to get elhiwar articles



  # start method to get santenews articles
  def get_articles_santenews(url_media_array)
    articles_url_santenews = []
    last_dates = []
    url_media_array.map do |url|
      doc = Nokogiri::HTML(URI.open(url))
      doc.css('article.item-list h2.post-box-title a').map do |link|


        articles_url_santenews << link['href']

      end

      doc.css('span.tie-date').map do |date|
        last_dates << date.text
      end
    end
    last_dates = last_dates.map { |d| change_date_autobip_aps(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 })}
    articles_url_santenews = articles_url_santenews.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_santenews_after_check = articles_url_santenews - list_articles_url
    articles_url_santenews_after_check.map do |link|
      article = Nokogiri::HTML(URI.open(link))
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
      # date = article.at('p.text-capitalize span').text
      # date[','] = ''
      date = article.at('span.tie-date').text
      date = change_date_autobip_aps(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0})
      url_array = article.css('div.single-post-thumb  img').map { |link| link['src'] }
      url_image = url_array[0]
      new_article.image = Down.download(url_array[0]) if url_array[0].present?
      # tags_array = article.css('div.entry-terms a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      # tag_check_and_save(tags_array)
    end
    render json: { crawling_status_aps: 'ok' }
  end
  # end method to get elhiwar articles



  # Only allow a trusted parameter "white list" through.
  def article_params
    params.permit(:title, :date_published, :author, :body,
                  :media_tags, :language, :url_image)
  end

  # tag_check_and_savetag_check_and_save
  def tag_check_and_save(tags_array)
    tags_array.map do |t|
      # tag_exist = Tag.where(['lower(name) like ? ',
      #                       t.downcase.lstrip.chop ]).count
      # if tag_exist.zero?
      tag = Tag.new
      tag.name = t.lstrip.chop
      tag.save!
      # end
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
end
