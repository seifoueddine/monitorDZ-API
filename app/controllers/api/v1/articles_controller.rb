class Api::V1::ArticlesController < ApplicationController
  # before_action :authenticate_user! , except: :pdf_export
  before_action :set_article, only: %i[show update destroy]
  require 'nokogiri'
  require 'open-uri'
  require 'openssl'
  require 'net/http'
  #require 'resolv-replace'

  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
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

    conditions[:medium_type] = params[:medium_type].split(',') unless params[:medium_type].blank?

    conditions[:media_area] = params[:media_area].split(',') unless params[:media_area].blank?

    conditions[:author_id] = params[:authors_ids].split(',') unless params[:authors_ids].blank?

    conditions[:language] = params[:language].split(',') unless params[:language].blank?


    if params[:start_date].blank?
      conditions[:date_published] = { gte: Date.today.to_datetime
                                               .change({ hour: 0, min: 0, sec: 0 }), lte: Date.today.to_datetime
                                                                                              .change({ hour: 0, min: 0, sec: 0 }) }

    else
      conditions[:date_published] = { gte: params[:start_date].to_datetime
                                                              .change({ hour: 0, min: 0, sec: 0 }), lte: params[:end_date].to_datetime
                                                                                                                          .change({ hour: 0, min: 0, sec: 0 }) }
    end

    conditions[:tag_name] = params[:tag_name] unless params[:tag_name].blank?
    # conditions[:tags] = params[:tag] unless params[:tag].blank?

    @articles_client = Article.search '*',
                                      where: conditions,
                                      page: params[:page],
                                      per_page: params[:per_page]


    set_pagination_headers :articles_client
    json_string = ArticleSerializer.new(@articles_client)
    media_serializer = MediumSerializer.new(media)

    render json: { articles: json_string, media: media_serializer, tags: all_tags }
  end

  def articles_by_medium
    start_date = params[:start_date]
    end_date = params[:end_date]

    @articles_for_dash = Article.where('date_published >= :start AND date_published <= :end', start: start_date.to_datetime.change({ hour: 0, min: 0, sec: 0 }) , end: end_date.to_datetime.change({ hour: 0, min: 0, sec: 0 }))
                                .joins(:medium)
                                .group('media.name').count
    sort = @articles_for_dash.sort_by {|_key, value| value}.reverse.to_h

    render json: sort
  end

  def articles_by_author
    start_date = params[:start_dat] || Date.today.change({ hour: 0, min: 0, sec: 0 })
    end_date = params[:end_dat] || Date.today.change({ hour: 0, min: 0, sec: 0 })
    @article_auth_for_dash = Article.joins(:author).where(date_published: start_date.to_datetime.beginning_of_day..end_date.to_datetime.end_of_day)
                                    .group('authors.name').order('count(authors.id) desc').limit(5).count
    render json: @article_auth_for_dash
  end

  def articles_by_tag
    start_date = params[:start_datt] || Date.today.change({ hour: 0, min: 0, sec: 0 })
    end_date = params[:end_datt] || Date.today.change({ hour: 0, min: 0, sec: 0 })
    @article_tag_for_dash = Article.where(date_published: start_date.to_datetime.beginning_of_day..end_date.to_datetime.end_of_day).joins(:tags).group('tags.name').count
    render json: @article_tag_for_dash
  end


=begin
  def articles_client_by_tag
    @article_tag_for_dash = ArticleTag.where(created_at: Date.today.beginning_of_day..Date.today.end_of_day).joins(:article).joins(:tag).group('tags.name').count
    render json: @article_tag_for_dash
  end
=end




  def articles_by_date
    days = params[:number_days] || 7
    @article_date_for_dash = Article.group('date_published').order('date_published desc').limit(days).count
    render json: @article_date_for_dash
  end

  def tags_by_date
    start_date = params[:start_d]
    end_date = params[:end_d]
    @tags_by_date = ArticleTag.where(created_at: start_date.to_datetime.beginning_of_day..end_date.to_datetime.end_of_day)
                              .joins(:tag).group('tags.name').count
    render json: @tags_by_date
  end



  def tags_client_by_date
    start_date = params[:start_d]
    end_date = params[:end_d]
    slug_id = get_slug_id
    @tags_by_date = ArticleTag.where(slug_id: slug_id, created_at: start_date.to_datetime.beginning_of_day..end_date.to_datetime.end_of_day)
                              .joins(:tag).group('tags.name').count
    render json: @tags_by_date
  end

  def articles_client_by_medium
    slug_id = get_slug_id

    campaign = Campaign.where(slug_id: slug_id)
    media = campaign[0].media
    media_ids = []
    media.map do |media|
      media_ids << media['id']
    end
    start_date = params[:start_date]
    end_date = params[:end_date]

    @articles_for_client_dash = Article.where(medium_id: media_ids).where('date_published >= :start AND date_published <= :end', start: start_date.to_datetime.change({ hour: 0, min: 0, sec: 0 }) , end: end_date.to_datetime.change({ hour: 0, min: 0, sec: 0 }))
                                       .joins(:medium)
                                       .group('media.name').count
    render json: @articles_for_client_dash
  end

  def articles_client_by_author
    slug_id = get_slug_id
    start_date = params[:start_dat] || Date.today.change({ hour: 0, min: 0, sec: 0 })
    end_date = params[:end_dat] || Date.today.change({ hour: 0, min: 0, sec: 0 })
    campaign = Campaign.where(slug_id: slug_id)
    media = campaign[0].media
    media_ids = []
    media.map do |media|
      media_ids << media['id']
    end
    @article_auth_for_client_dash = Article.joins(:author).where(medium_id: media_ids, date_published: start_date.to_datetime.beginning_of_day..end_date.to_datetime.end_of_day )
                                           .group('authors.name').order('count(authors.id) desc').limit(5).count
    render json: @article_auth_for_client_dash
  end

  def articles_client_by_tag
    slug_id = get_slug_id
    start_date = params[:start_datt] || Date.today.change({ hour: 0, min: 0, sec: 0 })
    end_date = params[:end_datt] || Date.today.change({ hour: 0, min: 0, sec: 0 })
    campaign = Campaign.where(slug_id: slug_id)
    media = campaign[0].media
    media_ids = []
    media.map do |media|
      media_ids << media['id']
    end
    @article_tag_for_client_dash = Article.where(medium_id: media_ids, date_published: start_date.to_datetime.beginning_of_day..end_date.to_datetime.end_of_day).joins(:tags)
                                          .group('tags.name').count
    render json: @article_tag_for_client_dash
  end

  def articles_client_by_date
    slug_id = get_slug_id

    campaign = Campaign.where(slug_id: slug_id)
    media = campaign[0].media
    media_ids = []
    media.map do |media|
      media_ids << media['id']
    end
    days = params[:number_days] || 7
    @article_date_for_client_dash = Article.where(medium_id: media_ids).group('date_published').order('date_published desc').limit(days).count
    render json: @article_date_for_client_dash
  end

  # GET /articlesclass
  def index
    @articles = if params[:media_id].blank?
                  Article.order(order_and_direction).page(page).per(per_page)
                else
                  Article.order(order_and_direction).where(medium_id: params[:media_id].split(',')).page(page).per(per_page)
                end
    set_pagination_headers :articles
    json_string = ArticleSerializer.new(@articles, include: %i[medium]).serializable_hash.to_json
    render json: json_string
  end

  # GET /articles/1
  def show
    slug_id = get_slug_id
    similar = @article.similar(fields: [:title])
    similar_json_string = ArticleSerializer.new(similar)
    json_string = ArticleSerializer.new(@article, include: %i[medium author])
    article_tag = @article.article_tags
    article_tag_filterd = article_tag.where(slug_id: slug_id)
    tag_ids = article_tag_filterd.map(&:tag_id)
    tags = Tag.where(id: tag_ids)
    render json: { article: json_string, similar: similar_json_string, tags: tags }
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
      @article.reindex
      render json: json_string
    else
      render json: @article.errors, status: :unprocessable_entity
    end
  end

  # auto tags@article_for_indexing
  def auto_tag
    slug_id = params[:slug_id]
    start_date = params[:start_date]
    end_date = params[:end_date]
    campaign = Campaign.where(slug_id: slug_id)
    all_tags = campaign[0].tags.where(status: true)
    camp_media = campaign[0].media
    camp_media_array = camp_media.map(&:id)
    puts "******************************"
    puts "start date :#{all_tags.count.to_s}"
    puts "******************************"
    puts "******************************"
    puts start_date
    puts start_date.to_datetime.beginning_of_day
    puts "******************************"
    puts "******************************"
    puts end_date
    puts end_date.to_datetime.end_of_day
    puts "******************************"
    articles = []
    # all_tags = Tag.where(status: true)
    articles_with_date = Article.where(medium_id: camp_media_array, date_published: start_date.to_datetime.beginning_of_day..end_date.to_datetime.end_of_day)
    puts "******************************"
    puts "articles_with_date :#{articles_with_date.count.to_s}"
    puts "******************************"
    @tags = []
    articles_with_date.map do |article|

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
        if ArticleTag.where(article_id: article.id, tag_id: tag_object.id, slug_id: slug_id, campaign_id: campaign[0].id).present?
          next
        end
        @article_tag = ArticleTag.new article_id: article.id, tag_id: tag_object.id, slug_id: slug_id, campaign_id: campaign[0].id
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
    puts "******************************"
    puts "Nombre d'articles :#{articles.count.to_s}"
    puts "******************************"
    puts "tag******************************tag"
    puts @tags
    puts "tag******************************tag"
    campaigns = Campaign.all
    if campaign[0].present?
      users = User.where(slug_id: campaign[0].slug_id)
      # camp_tags = campaign[0].tags
      #   camp_media = campaign[0].media
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


    render json: { tags: 'ok' }
  end
  # auto tags


  # export PDF
  def pdf_export
    id = params[:id]
    @article = Article.find(id)
    @html = @article.language == 'ar' ? get_html_ar : get_html_fr
    pdf = WickedPdf.new.pdf_from_string(@html)
    send_data pdf, filename: "Article_#{@article.id.to_s}.pdf" , type: 'application/pdf'
  end

  def get_html_fr
    '<!DOCTYPE html>
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
              <td align="left" valign="center"
              style="padding-bottom:40px;border-top:0;height:100% !important;width:150px !important;">
                <img style="height:100px" src="' + 'https://api.mediasmonitoring.com' + @article.medium.avatar.url + ' " />
              </td>
              <td align="center" valign="center"
                style="padding-bottom:40px;border-top:0;height:100% !important;width:auto !important;">
                <span style="color: #8f8f8f; font-weight: normal; line-height: 2; font-size: 14px;"> ' + @article.author.name + ' | ' + @article.date_published.strftime('%d - %m - %Y') + '</span>
              </td>
 <td align="center" valign="center"
                style="padding-bottom:40px;border-top:0;height:100% !important;width:auto !important;">

              </td>
            </tr>
            <tr>
              <td colSpan="2" style="padding-top:10px;border-top:1px solid #e4e2e2">
                <h2 style="color:#303030; font-size:20px; line-height: 1.6; font-weight:500;"><b>' + @article.title + '</b> </h2>
                ' + @article.body + '
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
                  PDF généré par MediaDZ app le ' + Date.today.strftime('%d - %m - %Y') + '
                </p>
                <p style="font-size: 12px; line-height:1; color:#909090;  margin-top:5px; margin-bottom:5px;">
                  <a href="#" style="color: #00365a;text-decoration:none;">Alger</a> , <a href="#"
                    style="color: #00365a;text-decoration:none; ">Algerie</a>
                </p>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </body>
</html>'
  end

  def get_html_ar
    '<!DOCTYPE html>
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
              <td align="left" valign="center"
              style="padding-bottom:40px;border-top:0;height:100% !important;width:30% !important;">
                <img style="height:100px" src="' + 'https://api.mediasmonitoring.com' + @article.medium.avatar.url + ' " />
              </td>
              <td align="center" valign="center"
                style="padding-bottom:40px;border-top:0;height:100% !important;width:auto  !important;">
                <span style="color: #8f8f8f; font-weight: normal; line-height: 2; font-size: 14px;">' + @article.author.name + ' | ' + @article.date_published.strftime('%d - %m - %Y') + '</span>
              </td>
            <td align="center" valign="center"
                style="padding-bottom:40px;border-top:0;height:100% !important;width:auto !important;">

              </td>
            </tr>
            <tr>
              <td colSpan="2" style="padding-top:10px;border-top:1px solid #e4e2e2;direction: rtl;">
                <h2 style="color:#303030; font-size:20px; line-height: 1.6; font-weight:500;direction: rtl;"><b>' + @article.title + ' </b></h2>
                ' + @article.body + '
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
                  PDF généré par MediaDZ app le ' + Date.today.strftime('%d - %m - %Y') + '
                </p>
                <p style="font-size: 12px; line-height:1; color:#909090;  margin-top:5px; margin-bottom:5px;">
                  <a href="#" style="color: #00365a;text-decoration:none;">Alger</a> , <a href="#"
                    style="color: #00365a;text-decoration:none; ">Algerie</a>
                </p>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </body>
</html>'
  end

  # export PDF


  def send_email
    @article_for_email = Article.find(params[:article_id])
    @current_user = current_user
    email = params[:email]
    UserMailer.articleMail(@article_for_email, email, @current_user).deliver!
  end

  def crawling
    # @all_tags = Tag.all
    @media = Medium.find(params[:media_id])
    if @media.url_crawling?
      url_media_array = @media.url_crawling.split(',')
      get_articles(url_media_array)
      Article.where(medium_id: params[:media_id], created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day).where.not(id: Article.group(:url_article).select('min(id)')).destroy_all

    else
      render json: { crawling_status: 'No url_crawling', media: @media.name, status: 'error' }
    end
    # unless @media.name == 'LIBERTE'
      # Author.all.where.not(id: Author.group(:name).select('min(id)')).destroy_all
      # end

  end

  # DELETE /articles/1
  def destroy
    @article.destroy
  end

  def search_article
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

    conditions[:medium_type] = params[:medium_type].split(',') unless params[:medium_type].blank?

    conditions[:media_area] = params[:media_area].split(',') unless params[:media_area].blank?

    conditions[:author_id] = params[:authors_ids].split(',') unless params[:authors_ids].blank?

    conditions[:language] = params[:language].split(',') unless params[:language].blank?


    unless params[:start_date].blank?
      conditions[:date_published] = { gte: params[:start_date].to_datetime
                                                              .change({ hour: 0, min: 0, sec: 0 }),
                                      lte: params[:end_date].to_datetime
                                                            .change({ hour: 0, min: 0, sec: 0 }) }
    end

    conditions[:tag_name] = params[:tag_name] unless params[:tag_name].blank?



    result_articles = Article.search params[:search],
                                     where: conditions,
                                     fields: %i[title body author_name],
                                     suggest: true,
                                     page: params[:page],
                                     per_page: params[:per_page],
                                     order: { date_published: :desc }

    @articles_res = result_articles

    set_pagination_headers :articles_res
    json_string = ArticleSerializer.new(@articles_res)
    media_serializer = MediumSerializer.new(media)

    render json: { result_articles: json_string,
                   media: media_serializer,
                   time: result_articles.took,
                   suggestions: @articles_res.suggestions,
                   tags: all_tags
                 }

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

    slug_id = get_slug_id

    campaign = Campaign.where(slug_id: slug_id)
    #  media = campaign[0].media
    # all_tags = campaign[0].tags
    media_ids = []
    # Medium.all.map do |media|
    # media_ids << media['id']
    # end

    conditions = {}
    conditions[:medium_id] = params[:media_id].split(',') unless params[:media_id].blank?
    #conditions[:status] = 'confirmed'

    conditions[:medium_type] = params[:medium_type].split(',') unless params[:medium_type].blank?

    conditions[:media_area] = params[:media_area].split(',') unless params[:media_area].blank?

    conditions[:author_id] = params[:authors_ids].split(',') unless params[:authors_ids].blank?

    conditions[:language] = params[:language].split(',') unless params[:language].blank?


    unless params[:start_date].blank?
      # conditions[:date_published] = { gte: Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 }), lte: Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }

      #  else
      conditions[:date_published] = { gte: params[:start_date].to_datetime.change({ hour: 0, min: 0, sec: 0 }), lte: params[:end_date].to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
    end

    conditions[:tag_name] = params[:tag_name] unless params[:tag_name].blank?
    # conditions[:tags] = params[:tag] unless params[:tag].blank?

    @articles = Article.search '*',
                                      where: conditions,
                                      page: params[:page],
                                      per_page: params[:per_page],
                                      order: { date_published: :desc }


    set_pagination_headers :articles
    json_string = ArticleSerializer.new(@articles)
    #  media_serializer = MediumSerializer.new(media)

    #  render json: { articles: json_string, media: media_serializer, tags: all_tags }






=begin

    if params[:media_id].blank?

      @articles = Article.order(order_and_direction).page(page).per(per_page)
    else

      @articles = Article.order(order_and_direction).where(medium_id: params[:media_id].split(',')).page(page).per(per_page)

    end
=end
    archived = Article.where(status: 'archived').count
    pending = Article.where(status: 'pending').count
    # set_pagination_headers :articles
    #  json_string = ArticleSerializer.new(@articles)
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
      get_articles_elmoudjahid_fr(url_media_array)
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
    when 'ALGERIEPARTPLUS'
      get_articles_algerie_part(url_media_array)
    when '24H-DZ'
      get_articles_24hdz(url_media_array)
    when 'REPORTERS'
      get_articles_reporters(url_media_array)
    when 'SHIHABPRESSE'
      get_articles_shihabpresse(url_media_array)
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
    when 'ELMAOUID'
      get_articles_elmaouid(url_media_array)
    when 'HUFFINGTON-POST'
      get_articles_huffingtonpost(url_media_array)
    when 'ELWATAN'
      get_articles_elwatan(url_media_array)
    when 'ALYAOUM24'
      get_articles_alyaoum24(url_media_array)
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
        #  tag_check_and_save(tags_array) if @media.tag_status == true
      end

    render json: { crawling_status_autobip: 'ok' }
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
      new_article.save!
      count += 1 if new_article.save
        # tag_check_and_save(tags_array)if @media.tag_status == true
    end
    render json: { crawling_count_elcherouk: count }
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
      new_article.date_published = article.at('time[datetime]')['datetime'].to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24)
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
      new_article.save!
      # tag_check_and_save(tags_array)
    end
    render json: { crawling_status_ennahar: 'ok' }
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
      new_article.category_article = article.css('div.article__meta a.article__meta-category').nil? ? article.css('div.anarticle__meta div a.article-meta__category').text : article.css('div.article__meta a.article__meta-category').text
      new_article.title = article.css('div.article__title').nil? ? article.css('h2.anarticle__title span').text : article.css('div.article__title').text
      # new_article.author = article.css('div.article-head__author div em a').text

      author_exist = if article.at('span.article__meta-author').nil?
                       Author.where(['lower(name) like ? ', ('TSA auteur').downcase])
                     else
                       Author.where(['lower(name) like ? ',
                                     article.at('span.article__meta-author').text.downcase])
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
      begin
        doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby', read_timeout: 3600))
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end
      doc.css('#itemListLeading h3 a').map do |link|
        articles_url_aps << "http://www.aps.dz#{link['href']}"# if link['class'] == 'main_article'
      end
      doc.css('span.catItemDateCreated').map do |date|
        last_dates << date.text
      end
    end
    last_dates = last_dates.map { |d| change_date_autobip_aps(d) }
    last_dates = last_dates.map{ |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
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
        article = Nokogiri::HTML(URI.open(link,read_timeout: 3600))
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

      author_exist = if article.at('span.article__meta-author').nil?
                       Author.where(['lower(name) like ? ', ('APS auteur').downcase])
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
      d = change_date_autobip_aps(date)
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
      new_article.save!
        # tag_check_and_save(tags_array)if @media.tag_status == true
    end
    render json: { crawling_status_aps: 'ok' }
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
      doc.css('div.categorie-liste-details a:nth-child(2)').map do |link|
        articles_url_le_soir << "https://www.lesoirdalgerie.com#{link['href']}"
      end
    end
    articles_url_le_soir = articles_url_le_soir.reject(&:nil?)

    articles_url_le_soir_after_check = []
    articles_url_le_soir .map do |link|
      articles_url_le_soir_after_check << link unless Article.where(medium_id: @media.id,url_article: link).present?
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
                       Author.where(['lower(name) like ? ', 'Le soir auteur'.downcase ])
                     else
                       Author.where(['lower(name) like ? ',
                                     article.css('div.published a').text.downcase ])
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

      new_article.body =  article.css('div.text p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date_published = article.at('/html/body/section[3]/div/div[2]/div/div[2]/text()[2]').text
      first = date_published.split(',')[0]
      date = first.sub! 'le', ''
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })

      url_array = article.css('div.article-content div.article-details div.picture img')
                         .map{ |link| "https://www.lesoirdalgerie.com#{link['data-original']}"}
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
      ##tag_check_and_save(tags_array)if @media.tag_status == true
    end
    render json: { crawling_status_le_soir: 'ok' }
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
        articles_url_liberte << "https://www.liberte-algerie.com#{link['href']}"# if link['class'] == 'main_article'
      end
      doc.css('div.right-side div.date-heure span.date').map do |date|
        last_dates << date.text
      end
    end
    last_dates = last_dates.map { |d| change_date_autobip_aps(d) }
    last_dates = last_dates.map{ |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
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
                       Author.where(['lower(name) like ? ', ('Liberté auteur').downcase])
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

      # d = change_date_autobip_aps(date)
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
      #tags_array = article.css('ul.itemTags li').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      #tag_check_and_save(tags_array)if @media.tag_status == true
    end
    render json: { crawling_status_liberte: 'ok' }
  end
  # end method to get _liberte articles




  # start method to get 24hdz articles
  def get_articles_24hdz(url_media_array)
    articles_url_24hdz = []
    last_dates = []
    url_media_array.map do |url|
      puts "Start category parsing : #{url} :) "
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
      doc.css('time.entry-date.updated.td-module-date').map do |date|
        last_dates << date['datetime']
      end
    end
    last_dates = last_dates.map { |d| change_date_autobip_aps(d) }
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24) }
    # last_dates = last_dates.map(&:to_datetime.change({ hour: 0, min: 0, sec: 0 }))
    articles_url_24hdz = articles_url_24hdz.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_24hdz_after_check = articles_url_24hdz - list_articles_url
    articles_url_24hdz_after_check.map do |link|
      puts "Start article parsing : #{link} :) "
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
      if article.at('div.td-post-author-name').nil?
        author_exist = Author.where(['lower(name) like ? ', '24h-dz auteur'.downcase ])
      else
        author_exist = Author.where(['lower(name) like ? ',
                                     article.at('div.td-post-author-name').text.downcase ])
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

      # d = change_date_autobip_aps(date)
      new_article.date_published = article.at('time[datetime]')['datetime'].to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24)
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
      #tags_array = article.css('ul.itemTags li').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      puts "URLBefoooooooooooooor:#{link}"
      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articlesTagsUrl = link
      end
      puts "URLURLURLURLURLURLURLURLURLURLURLURLURLURLURL: #{articlesTagsUrl}"

      new_article.save!
    end
    render json: { crawling_status_24hdz: 'ok' }
  end
  # end method to get 24hdz articles




  # start method to get reporters articles
  def get_articles_reporters(url_media_array)
    articles_url_reporters = []
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
      doc.css('h3.entry-title.td-module-title a').map do |link|
        articles_url_reporters << link['href']
      end
      doc.css('time.entry-date.updated.td-module-date').map do |date|
        last_dates << date['datetime']
      end
    end
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
    # last_dates = last_dates.map(&:to_datetime.change({ hour: 0, min: 0, sec: 0 }))
    articles_url_reporters = articles_url_reporters.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates)
    list_articles_url = []
    last_articles.map do |article|
      list_articles_url << article.url_article
    end
    articles_url_reporters_after_check = articles_url_reporters - list_articles_url
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
      if article.at('div.td-post-author-name').nil?
        author_exist = Author.where(['lower(name) like ? ', 'reporters auteur'.downcase ])
      else
        author_exist = Author.where(['lower(name) like ? ',
                                     article.at('div.td-post-author-name').text.downcase ])
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

      # d = change_date_autobip_aps(date)
      new_article.date_published = article.at('time[datetime]')['datetime'].to_datetime.change({ hour: 0, min: 0, sec: 0 })
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
      #tags_array = article.css('ul.itemTags li').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      #if articlesTagsUrl.present?
        # puts 'add article'
        # @articles_for_auto_tag << Article.where(url_article: articlesTagsUrl)[0]
        #end
      ##tag_check_and_save(tags_array)if @media.tag_status == true
    end
    puts "json: { crawling_status_reporteur: 'ok' }"
  end
  # end method to get reporters articles



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
        articles_url_biled_after_check << link unless Article.where(medium_id: @media.id,url_article: link).present?
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
      new_article.category_article =  article.css('#content > header > ul.list-breadcrumbs > li:nth-child(2)').text
      new_article.title = article.css('#content > header > h1').text
      # new_article.author = article.css('div.article-head__author div em a').text
      author_exist = if article.at('ul.list-share li a span.strong').text == '0'
                       Author.where(['lower(name) like ? ', ('Bilad auteur').downcase])
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
      date_array = article.css('ul.list-share li a span').map{ |span| span.text }
      new_article.date_published = date_array.to_s.include?('0') ? Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 }) : date_published_array[1].split(',')[0].to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('article.module-detail img').map{ |link| link['data-src'] }
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
        #  tag_check_and_save(tags_array)if @media.tag_status == true
    end
    render json: { crawling_status_aps: 'ok' }
  end
  # end method to get bilad articles
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
      author_exist = Author.where(['lower(name) like ? ', ('Maghrebemergent auteur').downcase])
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
    d = change_date_maghrebemergen(date)
    new_article.date_published = d.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    url_array = article.css('section div div div div div div.elementor-widget-wrap div.elementor-widget-container div.elementor-image img').map { |link| link['src'] }
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
    new_article.save!
    # tag_check_and_save(tags_array)
  end
    render json: { crawling_status_aps: 'ok' }
  end
  # end method to get maghrebemergent articles
  #


  # start method to get elmoudjahid articles
  def get_articles_elmoudjahid_fr(url_media_array)
    articles_url_elmoudjahid = []

    count = 0
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'Googlebot/2.1'))
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
    puts articles_url_elmoudjahid.count
      articles_url_elmoudjahid = articles_url_elmoudjahid.reject(&:nil?)

      articles_url_elmoudjahid_after_check = []
      articles_url_elmoudjahid.map do |link|
        unless Article.where(medium_id: @media.id,url_article: link).present?
          articles_url_elmoudjahid_after_check << link
        end
      end
    puts articles_url_elmoudjahid_after_check.count
    articles_url_elmoudjahid_after_check.map do |link|
      begin
        article = Nokogiri::HTML(URI.open(link, 'User-Agent' => 'Googlebot/2.1'))
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


      author_exist = Author.where(['lower(name) like ? ', ('Elmoudjahid-fr auteur').downcase])


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
      url_array = article.css('article.module-article figure img').map{ |link| link['data-src'] }
      new_article.url_image = url_array[0]
      new_article.image = Down.download(url_array[0]) if url_array[0].present?
      new_article.status = 'pending'
      new_article.save!
      count += 1 if new_article.save
      # tag_check_and_save(tags_array)
    end
    render json: { crawling_count_elmoudjahid: count }
  end
  # end method to get elmoudjahid articles
  # start method to get elmoudjahid_fr articles
  #
  #
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


      author_exist = if article.at('p.text-muted').nil?
                       Author.where(['lower(name) like ? ', ('Elmoudjahid auteur').downcase])
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
      new_article.date_published = article.css('#contenu > div.At > span').text.split(':')[1].to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('#articlecontent > div.TxArtcile > div.ImgCapt > img').map { |link| link['src'] }
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
      # tag_check_and_save(tags_array)
    end
    render json: { crawling_status_aps: 'ok' }
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
        articles_url_elkhabar << "https://www.elkhabar.com#{link['href']}" unless link.css('i').present?
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
      new_article.title = article.css('h2.title').text if article.css('h2.title').present?
      # new_article.author = article.css('div.article-head__author div em a').text

      author_exist = if article.at('span.time-blog b').present?
                       Author.where(['lower(name) like ? ',
                                     article.at('span.time-blog b').text.downcase])
                     else
                       Author.where(['lower(name) like ? ', ('Elkhabar auteur').downcase])

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
      # d = change_date_maghrebemergen(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      if article.css('div#article_img img').present?
        url_array = article.css('div#article_img img').map { |link| "https://www.elkhabar.com#{link['src']}" }
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
      new_article.save!
      count += 1 if new_article.save
        # tag_check_and_save(tags_array) if @media.tag_status == true
    end
    render json: { crawling_status_elkhabar: count }
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
      author_exist = Author.where(['lower(name) like ? ', ('Elikhbaria auteur').downcase])
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
        # tag_check_and_save(tags_array) if @media.tag_status == true
    end
    render json: { crawling_status_aps: 'ok' }
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
        author_exist = Author.where(['lower(name) like ? ', ('Algerieco auteur').downcase])
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
    last_dates = last_dates.map { |d| d.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24) }
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
        author_exist = Author.where(['lower(name) like ? ', ('Chiffreaffaire auteur').downcase])
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
      # d = change_date_maghrebemergen(date)
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
      new_article.save!
        #  tag_check_and_save(tags_array)
    end
    render json: { crawling_status_aps: 'ok' }
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
        author_exist = Author.where(['lower(name) like ? ', ('Elhiwar auteur').downcase])
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
        author_exist = Author.where(['lower(name) like ? ', ('Visa Algérie auteur').downcase])
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
      # d = change_date_maghrebemergen(date)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24)
      #url_array = article.css('div.entry-media img').map {  |link| link['src'] }
      # url_image = url_array[0]
      # new_article.image = Down.download(url_array[0]) if url_array[0].present?
      # tags_array = article.css('div.entry-terms a').map(&:text)
      # new_article.media_tags = tags_array.join(',')
      new_article.status = 'pending'
      new_article.save!
      # tag_check_and_save(tags_array)
    end
    render json: { crawling_status_visadz: 'ok' }
  end
  # end method to get elhiwar articles




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
      new_article.medium_id = @media.id
      new_article.language = @media.language
      new_article.category_article = 'algerie360.com'
      new_article.title = article.css('h1.single-post__entry-title.mt-0').text
      #  new_article.author = article.css('div.article-head__author div em a').text
      author_exist = if article.at('li.entry__meta-author a').nil?
                       Author.where(['lower(name) like ? ', ('Algérie360 auteur').downcase])
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
      d = change_date_maghrebemergen(date)
      new_article.date_published = d.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      # new_article.date_published =
      url_array = article.css('div.entry__img-holder.px-2.px-md-0 img').map { |link| link['data-src'] }
      puts "this is url  image"
      puts url_array
      puts "this is url  image "
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
      ##tag_check_and_save(tags_array)if @media.tag_status == true
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
    last_dates = last_dates.map { |d| change_date_autobip_aps(d) }
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
      article.css('div.tdb-category.td-fix-index a.tdb-entry-category').map do |category|
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
      d = change_date_autobip_aps(date)
      new_article.date_published = d.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      new_article.url_image = nil
      new_article.status = 'pending'
      puts "URLBefoooooooooooooor:#{link}"
      if Article.where(url_article: link).present?
        puts 'article present'
      else
        articlesTagsUrl = link
      end
      puts "URLURLURLURLURLURLURLURLURLURLURLURLURLURLURL: #{articlesTagsUrl}"

      new_article.save!
    end
    render json: { crawling_status_algeriepart: 'ok' }
  end
  # end method to get algeriepart





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


      author_exist = Author.where(['lower(name) like ? ', ('Santenews auteur').downcase])


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
      new_article.save!
      # tag_check_and_save(tags_array)
    end
    render json: { crawling_status_elhiwar: 'ok' }
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
      unless Article.where(medium_id: @media.id,url_article: link).present?
        articles_url_shihabpresse_after_check << link
      end
    end

    articles_url_shihabpresse_after_check.map do |link|
      puts "link link link link link link link link"
      puts link
      puts "link link link link link link link link"
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
        url_array = article.css('div.featured-area figure img').map{ |link| link['src'] }
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
    end
    render json: { crawling_count_shihabpresse: count }
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
      unless Article.where(medium_id: @media.id,url_article: link).present?
        articles_url_lexpressiondz_after_check << link
      end
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
      new_article.category_article =  article.css('#content > nav > ol > li:nth-child(3) > a').text
      new_article.title = "#{article.css('article header.heading-a p',).text}, #{article.css('article header.heading-a h1',).text}"
      # new_article.author = article.css('div.article-head__author div em a').text
      author_exist = if article.css('h3.scheme-user').text == ''
                       Author.where(['lower(name) like ? ', ("L'expressiondz auteur").downcase])
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
      url_array = article.css('figure.image-featured img').map{ |link|  link['data-src']}
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
      #  tag_check_and_save(tags_array)if @media.tag_status == true
    end
    render json: { crawling_status_expression: 'ok' }
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
      articles_url_lematin_after_check << link unless Article.where(medium_id: @media.id,url_article: link).present?
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
      new_article.category_article =   article.css('h3.title-section.mb-2').text
      new_article.title = article.css('h1#title').text
      # new_article.author = article.css('div.article-head__author div em a').text
      author_exist_array = article.css('p.author span a').map{ |link|  link['title']}
      author_exist_final = author_exist_array.reject(&:nil?)
      author_exist = if author_exist_final.count.zero?
                       Author.where(['lower(name) like ? ', ("Lematin auteur").downcase])
                     else
                       a = author_exist_final[0]
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = author_exist_final.count.zero? ? "Lematin auteur" : author_exist_final[0]
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('p.lead.caption').inner_html + article.css('div.card-body.p-2').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')

      date_published_array =  article.css('p.author span meta').map { |date|  
                                if date['itemprop'] == 'datePublished'
                                                                                date['content']
                                                                              end }
      new_article.date_published = date_published_array.reject(&:nil?)[0].to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('img.d-block.w-100').map{ |link|  link['src']}
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
      #  tag_check_and_save(tags_array)if @media.tag_status == true
    end
    render json: { crawling_status_expression: 'ok' }
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
      articles_url_almaghreb24_after_check << link unless Article.where(medium_id: @media.id,url_article: link).present?
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
                       Author.where(['lower(name) like ? ', ("Almaghreb24 auteur").downcase])
                     else
                       a = author_exist_final
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = (author_exist_final.nil? || author_exist_final == '') ? "Almaghreb24 auteur" : author_exist_final
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('div.entry-content.entry.clearfix p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')


      new_article.date_published = Date.today.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('figure.single-featured-image img').map{ |link|  link['src']}
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
    end
    render json: { crawling_status_almaghreb24: 'ok' }
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
      articles_url_aujourdhui_after_check << link unless Article.where(medium_id: @media.id,url_article: link).present?
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
                       Author.where(['lower(name) like ? ', ("Aujourdhui-MA auteur").downcase])
                     else
                       a = author_exist_final
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = (author_exist_final.nil? || author_exist_final == '') ? "Aujourdhui-MA auteur" : author_exist_final
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('div.entry-content.clearfix p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      new_article.date_published = article.at('time.entry-date').attr('datetime').to_datetime.change({ hour: 0, min: 0, sec: 0 }) + (1.0 / 24)
      url_array = article.css('div.entry-content.clearfix figure.post-thumbnail img').map{ |link|  
                    if link['src'].include? 'https'
                     link['src']
                      end }
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
      new_article.save!
    end
    render json: { crawling_status_aujourdhui: 'ok' }
  end
  # end method to get Aujourdhui articles




  # start method to get eldjazaireldjadida articles
  def get_articles_eldjazaireldjadida(url_media_array)
    articles_url_eldjazaireldjadida = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url,'User-Agent' => 'ruby/2.6.5', 'From' => 'foo@bar.invalid'), nil, "UTF-8")
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
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
      articles_url_eldjazaireldjadida_after_check << link unless Article.where(medium_id: @media.id,url_article: link).present?
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
                       Author.where(['lower(name) like ? ', ('ELDJAZAIR-ELDJADIDA auteur').downcase])
                     else
                       a = author_exist_final
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = (author_exist_final.nil? || author_exist_final == '') ? "ELDJAZAIR-ELDJADIDA auteur" : author_exist_final
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('div.entry-content.entry.clearfix p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date_arabe = article.at('span.date.meta-item.tie-icon').text
      date = change_date_maghrebemergen(date_arabe)
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('figure.single-featured-image img').map{ |link|
        if link['src'].include? 'https'
          link['src']
        end }
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
      new_article.save!
    end
    render json: { crawling_status_eldjazaireldjadida: 'ok' }
  end
  # end method to get eldjazaireldjadida articles


  # start method to get algeriepatriotique articles
  def get_articles_algeriepatriotique(url_media_array)
    articles_url_algeriepatriotique = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url,'User-Agent' => 'ruby/2.6.5', 'From' => 'foo@bar.invalid'), nil, "UTF-8")
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
      articles_url_algeriepatriotique_after_check << link unless Article.where(medium_id: @media.id,url_article: link).present?
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
                       Author.where(['lower(name) like ? ', ('ALGERIE-PATRIOTIQUE auteur').downcase])
                     else
                       a = author_exist_final
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = (author_exist_final.nil? || author_exist_final == '') ? "ALGERIE-PATRIOTIQUE auteur" : author_exist_final
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('div.the-content  p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date_arabe = article.at('div.entry-info span.posted-date').text
      date = change_date_maghrebemergen(date_arabe.split('-')[0])
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array = article.css('div.post-formats-wrapper a.post-image img').map{ |link| link['src'] }
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
    end
    render json: { crawling_status_algeriepatriotique: 'ok' }
  end
  # end method to get algeriepatriotique articles



  # start method to get elmaouid articles
  def get_articles_elmaouid(url_media_array)
    articles_url_elmaouid = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url,'User-Agent' => 'ruby/2.6.5', 'From' => 'foo@bar.invalid'), nil, "UTF-8")
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
      articles_url_elmaouid_after_check << link unless Article.where(medium_id: @media.id,url_article: link).present?
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
                       Author.where(['lower(name) like ? ', ('Elmaouid auteur').downcase])
                     else
                       a = author_exist_final
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = (author_exist_final.nil? || author_exist_final == '') ? "Elmaouid auteur" : author_exist_final
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
      url_array =  article.css('div.single-post-thumb img').map{ |link| link['src'] }
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
    end
    render json: { crawling_status_elmaouid: 'ok' }
  end
  # end method to get elmaouid articles 




  # start method to get huffingtonpost articles
  def get_articles_huffingtonpost(url_media_array)
    articles_url_huffingtonpost = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url,'User-Agent' => 'ruby/2.6.5', 'From' => 'foo@bar.invalid'), nil, "UTF-8")
      rescue OpenURI::HTTPError => e
        puts "Can't access #{url}"
        puts e.message
        puts
        next
      end

      doc.css('div#zone-twilight1 div.zone__content a').map do |link|
        articles_url_huffingtonpost << link['href']
      end
    end
    articles_url_huffingtonpost = articles_url_huffingtonpost.reject(&:nil?)

    articles_url_huffingtonpost_after_check = []
    articles_url_huffingtonpost.map do |link|
      articles_url_huffingtonpost_after_check << link unless Article.where(medium_id: @media.id,url_article: link).present?
    end

    articles_url_huffingtonpost_after_check.map do |link|

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
      new_article.category_article = article.css('div.page__content header.entry__header.yr-entry-header a.entry-eyebrow span').text
      new_article.title = article.css('h1.headline__title').text + article.css('h2.headline__subtitle').text
      # new_article.author = article.css('div.article-head__author div em a').text
      find_author = article.at('a.author-card__details__name').present? ? article.at('a.author-card__details__name').text : article.at('span.author-card_details_name').text
      author_exist_final = find_author
      author_exist = if author_exist_final.nil? || author_exist_final == ''
                       Author.where(['lower(name) like ? ', ('Huffington-post auteur').downcase])
                     else
                       a = author_exist_final
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = (author_exist_final.nil? || author_exist_final == '') ? "Huffington-post auteur" : author_exist_final
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('div.content-list-component.text p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date = article.at('div.timestamp span').text
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array =  article.css('div.post-contents.yr-entry-text img.image__src').map{ |link| link['src'] }
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
    end
    render json: { crawling_status_huffingtonpost: 'ok' }
  end
  # end method to get huffingtonpost articles





  # start method to get elwatan articles
  def get_articles_elwatan(url_media_array)
    articles_url_elwatan = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url,'User-Agent' => 'ruby/2.6.5', 'From' => 'foo@bar.invalid'), nil, "UTF-8")
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
      articles_url_elwatan_after_check << link unless Article.where(medium_id: @media.id,url_article: link).present?
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
                       Author.where(['lower(name) like ? ', ('Elwatan auteur').downcase])
                     else
                       a = author_exist_final
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = (author_exist_final.nil? || author_exist_final == '') ? "Elwatan auteur" : author_exist_final
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
      new_article.save!
    end
    render json: { crawling_status_elwatan: 'ok' }
  end
  # end method to get elwatan articles




  # start method to get alyaoum24 articles
  def get_articles_alyaoum24(url_media_array)
    articles_url_alyaoum24 = []
    url_media_array.map do |url|
      begin
        doc = Nokogiri::HTML(URI.open(url,'User-Agent' => 'ruby/2.6.5', 'From' => 'foo@bar.invalid'), nil, "UTF-8")
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
      articles_url_alyaoum24_after_check << link unless Article.where(medium_id: @media.id,url_article: link).present?
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
      author_exist_final =  article.at('div.nameAuthor').text
      author_exist = if author_exist_final.nil? || author_exist_final == ''
                       Author.where(['lower(name) like ? ', ('Alyaoum24 auteur').downcase])
                     else
                       a = author_exist_final
                       Author.where(['lower(name) like ? ',
                                     a.downcase])
                     end

      new_author = Author.new
      if author_exist.count.zero?

        new_author.name = (author_exist_final.nil? || author_exist_final == '') ? "Alyaoum24 auteur" : author_exist_final
        new_author.medium_id = @media.id
        new_author.save!
        new_article.author_id = new_author.id
      else
        new_article.author_id = author_exist.first.id

      end

      new_article.body = article.css('div.post_content p').inner_html
      new_article.body = new_article.body.gsub(/<img[^>]*>/, '')
      date = article.at('span.timePost').text
      new_article.date_published = date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
      url_array =  article.css('div.article-image img.attachment-full.size-full.wp-post-image').map{  |link| link['src'] }
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
    end
    render json: { crawling_status_alyaoum24: 'ok' }
  end
  # end method to get alyaoum24 articles





  # Only allow a trusted parameter "white list" through.
  def article_params
    params.permit(:title, :date_published, :author, :body,
                  :media_tags, :language, :url_image, :author_id)
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
    end.join(' ')
  end
  # change_date_autobip_aps
  #

  # change_date_maghrebemergent
  def change_date_maghrebemergen(d)

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

      else
        m
      end
    end.join(' ')
  end
  # change_date_maghrebemergents
  #                 <p style="font-size: 12px; line-height: 1; color:brown; margin-top:5px;">
  #                  TAGS :  <%= article.tags.map(&:name).uniq.join(' - ')  %>
  #
  #                 </p>
  #        <p style="font-size: 12px; line-height: 1; color:brown; margin-top:5px;direction: rtl;">
  #                       الكلمات الدالة :  <%= article.tags.map(&:name).uniq.join(' - ')  %>
  #                     </p>
  def get_date_from_string(string)
    puts "*******************"
    puts string
    string = string.gsub! 'أسابيع', 'weeks'
    puts string
    puts "*******************"
    case string
    when string.include?('ثانية') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    when string.include?('ساعتين') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    when string.include?('دقيقة') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    when string.include?('دقيقتين') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    when string.include?('منذ ساعة واحدة') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    when string.include?('ساعات') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    when string.include?('ساعة') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    when string.include?('منذ يوم واحد') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 }) - 1
    when string.include?('منذ يومين') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 }) - 2
    when string.include?('منذ أسبوعين') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 }) - 14
    when string.include?('منذ أسبوع واحد') == true
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 }) - 7
    when string.include?('أيام') == true
      array = string.split(' ')
      number = array[1]
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 }) - number.to_i
    when string.include?('weeks') == true
      array = string.split(' ')
      number = array[1]
      Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 }) - number.to_i * 7
    else
      string.to_datetime.change({ hour: 0, min: 0, sec: 0 })
    end
  end
end
