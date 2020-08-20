class Api::V1::ArticlesController < ApplicationController
  # before_action :authenticate_user!
  before_action :set_article, only: %i[show update destroy]
  require 'nokogiri'
  require 'open-uri'
  # GET /articles
  def index
    if params[:media_id].blank?
      @articles = Article.order(order_and_direction).page(page).per(per_page)
    else
      @articles = Article.order(order_and_direction).where(medium_id: params[:media_id].split(',') ).page(page).per(per_page)
    end
    set_pagination_headers :articles
    json_string = ArticleSerializer.new(@articles, include: [:medium]).serialized_json
    render  json: json_string
  end


  # GET /articles/1
  def show
    json_string = ArticleSerializer.new(@article, include: [:medium, :tags]).serialized_json

    render json: json_string
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
      render json: @article
    else
      render json: @article.errors, status: :unprocessable_entity
    end
  end

  # auto tags
  def auto_tag
    all_tags = Tag.all
    articles_not_tagged = Article.all.where(is_tagged: nil)
    articles_not_tagged.map do |article|
      all_tags.map do |tag|
        @tags = []
        @tags_objects = []
        if article.body.include? tag.name
          @tags << tag.name unless @tags.include? tag.name
          @tags_objects << tag unless @tags_objects.include? tag.name
        end
        if article.title.include? tag.name
          @tags << tag.name unless @tags.include? tag.name
          @tags_objects << tag unless @tags_objects.include? tag.name
        end
      end
      old_tags = article.media_tags.split(',')
      old_tags << @tags
      article.media_tags = old_tags.join(',')
      article.tags = @tags_objects
      article.is_tagged = true if @tags_objects.length.positive?
      article.save!
    end
    render json: { tags: 'ok' }
  end
  # auto tags

  def crawling
    # doc_autobip = Nokogiri::HTML(URI.open('https://www.autobip.com/fr/actualite/covid_19_reamenagement_des_horaires_du_confinement_pour_6_communes_de_tebessa/16767'))
    @media = Medium.find(params[:media_id])
    if @media.url_crawling?
      url_media_array = @media.url_crawling.split(',')
      get_articles(url_media_array)
    else
      render json: { crawling_status: 'No url_crawling' , media: @media.name , status: 'error' }
    end
   # last_articles = Article.where("created_at <= :start AND created_at > :end", start: Date.today, end: 1.week.ago.to_date )
    #  doc = doc_autobip.css('.fotorama.mnmd-gallery-slider.mnmd-post-media-wide img').map { |link| link['src'] }
    #  doc = doc_autobip.at("//div[@class = 'fotorama__stage__frame']")
    #render json: { render: last_articles }
    end

  # DELETE /articles/1
  def destroy
    @article.destroy
  end

  private

  def get_articles(url_media_array)
    case @media.name
    when 'AUTOBIP'
      get_articles_autobip(url_media_array)
    when 'ELCHEROUK'
      get_articles_elcherouk(url_media_array)
    else
      render json: { crawling_status: 'No media name found!! ', status: 'error'}
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
    articles_url_autobip = articles_url_autobip.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates )
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
      new_article.category_article = article.css('header.single-header a.cat-theme-bg').text
      new_article.title = article.css('h1.entry-title').text
      new_article.author = article.at("//a[@itemprop = 'author']").text
      new_article.body = article.css('div.pt-4.bp-2.entry-content.typography-copy').inner_html
      new_article.date_published = article.at("//span[@itemprop = 'datePublished']").text
      url_array = article.css('.fotorama.mnmd-gallery-slider.mnmd-post-media-wide img').map { |link| link['src'] }
      new_article.url_image = url_array[0]
      tags_array = article.css('a.post-tag').map(&:text)
      new_article.media_tags = tags_array.join(',')
      new_article.save!
      tags_array.map do |t|
        tag = Tag.new
        tag.name = t
        tag.save!
      end
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
           last_dates << date.text
         end
       end
    articles_url_cherouk = articles_url_cherouk.reject(&:nil?)
    last_dates = last_dates.uniq
    last_articles = Article.where(medium_id: @media.id).where(date_published: last_dates )
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
      new_article.category_article = article.css('div.around.around--section ul li a span').text
      new_article.title = article.css('h2.title.title--middle.unshrink em').text
      new_article.author = article.css('div.article-head__author div em a').text
      new_article.body = article.css('div.the-content').inner_html
      new_article.date_published = article.css('ul.article-head__details time').text
      url_array = article.css('div.article-head__media-content div a').map do
      |link| link['href']
      end
      new_article.url_image = url_array[0]
      tags_array = article.css('div.article-core__tags a').map(&:text)
      new_article.media_tags = tags_array.join(',')
      new_article.save!
      tags_array.map do |t|
        tag = Tag.new
        tag.name = t
        tag.save!
      end
    end
    render json: { crawling_status_elcherouk: 'ok' }
  end
  # end method to get elcherouk articles

  # Only allow a trusted parameter "white list" through.
  def article_params
    params.permit(:title, :date_published, :author, :body,
                  :media_tags, :language, :url_image)
  end
end
