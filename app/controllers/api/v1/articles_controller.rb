class Api::V1::ArticlesController < ApplicationController
  # before_action :authenticate_user!
  before_action :set_article, only: %i[show update destroy]
  require 'nokogiri'
  require 'open-uri'
  # GET /articles
  def index
    @articles = Article.order(order_and_direction).page(page).per(per_page)
    set_pagination_headers :articles
    json_string = ArticleSerializer.new(@articles, include: [:medium]).serialized_json
    render  json: json_string
  end

  # GET /articles/1
  def show
    json_string = ArticleSerializer.new(@article, include: [:medium]).serialized_json
    
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

  def crawling
    # doc_autobip = Nokogiri::HTML(URI.open('https://www.autobip.com/fr/actualite/covid_19_reamenagement_des_horaires_du_confinement_pour_6_communes_de_tebessa/16767'))
     @media = Medium.find(params[:media_id])
     if @media.url_crawling?
       @doc = Nokogiri::HTML(URI.open(@media.url_crawling))
       get_articles
     else
       render json: { crawling_status: 'No url_crawling' , media: @media.name , status: 'error' }
     end

    #  doc = doc_autobip.css('.fotorama.mnmd-gallery-slider.mnmd-post-media-wide img').map { |link| link['src'] }
    #  doc = doc_autobip.at("//div[@class = 'fotorama__stage__frame']")
    # render json: { render: doc }
    end

  # DELETE /articles/1
  def destroy
    @article.destroy
  end

  private

  def get_articles
    case @media.name
    when 'AUTOBIP'
      get_articles_autobip
    when 'ELCHEROUK'
      get_articles_elcherouk
    else
      render json: { crawling_status: 'No media name found!! ', status: 'error'}
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_article
    @article = Article.find(params[:id])
  end

  # start method to get autobip articles
  def get_articles_autobip
    articles_url_doc_autobip = @doc.css('div.post__text a').map do |link|
    link['href'] if link['itemprop'] == 'url'
    end
    articles_url_autobip = articles_url_doc_autobip.reject(&:nil?)

    if @media.last_article.nil?
      articles_url_autobip_after_check = articles_url_autobip
    else
      index_article = articles_url_autobip.index(@media.last_article)
      articles_url_autobip_after_check = articles_url_autobip.slice(0, index_article)
    end
    unless articles_url_autobip_after_check.empty?
      @media.last_article = articles_url_autobip_after_check.first
      @media.save!
    end


    articles_url_autobip_after_check.map do |link|
      article = Nokogiri::HTML(URI.open(URI.escape(link)))
      new_article = Article.new
      new_article.url_article = link
      new_article.medium_id = @media.id
      new_article.title = article.css('h1.entry-title').text
      new_article.author = article.at("//a[@itemprop = 'author']").text
      new_article.body = article.css('div.pt-4.bp-2.entry-content.typography-copy').inner_html
      new_article.date_published = article.at("//span[@itemprop = 'datePublished']").text
      url_array = article.css('.fotorama.mnmd-gallery-slider.mnmd-post-media-wide img').map { |link| link['src'] }
      new_article.url_image = url_array[0]
      new_article.article_tags = article.css('a.post-tag').map(&:text).join(',')
      new_article.save! 
    end
    render json: { crawling_status_autobip: 'ok' }
  end
  # end method to get autobip articles

  # start method to get elcherouk articles
  def get_articles_elcherouk

    articles_url_cherouk = @doc.css('article div div h2.title.title--small a').map do |link|
      link['href']
    end
    articles_url_cherouk = articles_url_cherouk.reject(&:nil?)

    if @media.last_article.nil?
      articles_url_cherouk_after_check = articles_url_cherouk
    else
      index_article = articles_url_cherouk.index(@media.last_article)
      articles_url_cherouk_after_check = articles_url_cherouk.slice(0, index_article)
    end
    unless articles_url_cherouk_after_check.empty?
      @media.last_article = articles_url_cherouk_after_check.first
      @media.save!
    end
    articles_url_cherouk_after_check.map do |link|
      article = Nokogiri::HTML(URI.open(link))
      new_article = Article.new
      new_article.url_article = link
      new_article.medium_id = @media.id      
      new_article.title = article.css('h2.title.title--middle.unshrink em').text
      new_article.author = article.css('div.article-head__author div em a').text
      new_article.body = article.css('div.the-content').inner_html
      new_article.date_published = article.css('ul.article-head__details time').text
      url_array = article.css('div.article-head__media-content div a').map { |link| link['href'] }
      new_article.url_image = url_array[0]
      new_article.article_tags = article.css('div.article-core__tags a').map(&:text).join(',')
      new_article.save!
    end
    render json: { crawling_status_elcherouk: 'ok' }
  end
  # end method to get elcherouk articles




  # Only allow a trusted parameter "white list" through.
  def article_params
    params.permit(:title, :date_published, :author, :body, 
                  :article_tags, :language, :url_image)
  end
end
