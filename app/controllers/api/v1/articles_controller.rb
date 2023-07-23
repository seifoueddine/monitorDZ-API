# frozen_string_literal: true

require_relative '../../../../lib/articles/export'
require_relative '../../../../lib/articles/crawling/ennahar'
require_relative '../../../../lib/articles/crawling/elcherouk'
require_relative '../../../../lib/articles/crawling/tsa'
require_relative '../../../../lib/articles/crawling/elkhabar'
require_relative '../../../../lib/articles/crawling/elkhabar_fr'
require_relative '../../../../lib/articles/crawling/bilad'
require_relative '../../../../lib/articles/crawling/reporters'
require_relative '../../../../lib/articles/crawling/lexpressiondz'
require_relative '../../../../lib/articles/crawling/algerie360'
require_relative '../../../../lib/articles/crawling/visaalgerie'
require_relative '../../../../lib/articles/crawling/alyaoum24'
require_relative '../../../../lib/articles/crawling/maroco360'
require_relative '../../../../lib/articles/crawling/radioalgerie_ar'
require_relative '../../../../lib/articles/crawling/radioalgerie_fr'
require_relative '../../../../lib/articles/crawling/hdz24'
require_relative '../../../../lib/articles/crawling/maghrebemergent'
module Api
  module V1
    # crawling articles
    class ArticlesController < ::ApplicationController
      before_action :authenticate_user! , except: :pdf_export
      before_action :set_article, only: %i[show update destroy]
      require 'nokogiri'
      require 'open-uri'
      require 'openssl'
      require 'net/http'
      # require 'resolv-replace'

      OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
      # GET / client articles
      def articles_client
        slug_id = get_slug_id

        campaign = Campaign.where(slug_id: slug_id)
        media = campaign[0].media
        all_tags = campaign[0].tags
        media_ids = []
        media.map do |med|
          media_ids << med['id']
        end

        conditions = {}
        # conditions[:status] = 'confirmed'
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

        @articles_for_dash = Article.where('date_published >= :start AND date_published <= :end',
                                           start: start_date.to_datetime.change({ hour: 0, min: 0, sec: 0 }), end: end_date.to_datetime.change({ hour: 0, min: 0, sec: 0 }))
                                    .joins(:medium)
                                    .group('media.name').count
        sort = @articles_for_dash.sort_by { |_key, value| value }.reverse.to_h

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

      #   def articles_client_by_tag
      #     @article_tag_for_dash = ArticleTag.where(created_at: Date.today.beginning_of_day..Date.today.end_of_day).joins(:article).joins(:tag).group('tags.name').count
      #     render json: @article_tag_for_dash
      #   end

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
        @tags_by_date = ArticleTag.where(slug_id: slug_id,
                                         created_at: start_date.to_datetime.beginning_of_day..end_date.to_datetime.end_of_day)
                                  .joins(:tag).group('tags.name').count
        render json: @tags_by_date
      end

      def articles_client_by_medium
        slug_id = get_slug_id

        campaign = Campaign.where(slug_id: slug_id)
        media = campaign[0].media
        media_ids = []
        media.map do |med|
          media_ids << med['id']
        end
        start_date = params[:start_date]
        end_date = params[:end_date]

        @articles_for_client_dash = Article.where(medium_id: media_ids).where(
          'date_published >= :start AND date_published <= :end', start: start_date.to_datetime.change({ hour: 0, min: 0,
                                                                                                        sec: 0 }), end: end_date.to_datetime.change({ hour: 0, min: 0, sec: 0 })
        )
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
        media.map do |med|
          media_ids << med['id']
        end
        @article_auth_for_client_dash = Article.joins(:author).where(medium_id: media_ids,
                                                                     date_published: start_date.to_datetime.beginning_of_day..end_date.to_datetime.end_of_day)
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
        media.map do |med|
          media_ids << med['id']
        end
        @article_tag_for_client_dash = Article.where(medium_id: media_ids,
                                                     date_published: start_date.to_datetime.beginning_of_day..end_date.to_datetime.end_of_day).joins(:tags)
                                              .group('tags.name').count
        render json: @article_tag_for_client_dash
      end

      def articles_client_by_date
        slug_id = get_slug_id

        campaign = Campaign.where(slug_id: slug_id)
        media = campaign[0].media
        media_ids = []
        media.map do |med|
          media_ids << med['id']
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
        puts '******************************'
        puts "start date :#{all_tags.count}"
        puts '******************************'
        puts '******************************'
        puts start_date
        puts start_date.to_datetime.beginning_of_day
        puts '******************************'
        puts '******************************'
        puts end_date
        puts end_date.to_datetime.end_of_day
        puts '******************************'
        articles = []
        # all_tags = Tag.where(status: true)
        articles_with_date = Article.where(medium_id: camp_media_array,
                                           date_published: start_date.to_datetime.beginning_of_day..end_date.to_datetime.end_of_day)
        puts '******************************'
        puts "articles_with_date :#{articles_with_date.count}"
        puts '******************************'
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
            if ArticleTag.where(article_id: article.id, tag_id: tag_object.id, slug_id: slug_id,
                                campaign_id: campaign[0].id).present?
              next
            end

            @article_tag = ArticleTag.new article_id: article.id, tag_id: tag_object.id, slug_id: slug_id,
                                          campaign_id: campaign[0].id
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
        campaigns = Campaign.all
        if campaign[0].present?
          users = User.where(slug_id: campaign[0].slug_id)
          # camp_tags = campaign[0].tags
          #   camp_media = campaign[0].media
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

        render json: { tags: 'ok' }
      end
      # auto tags

      # export PDF
      def pdf_export
        id = params[:id]
        article = Article.find(id)
        html = article.language == 'ar' ? Articles::Export.get_html_ar(article) : Articles::Export.get_html_fr(article)
        pdf = WickedPdf.new.pdf_from_string(html)
        send_data pdf, filename: "Article_#{article.id}.pdf", type: 'application/pdf'
      end
      # export PDF

      def send_email
        article_for_email = Article.find(params[:article_id])
        # @current_user = current_user
        email = params[:email]
        UserMailer.articleMail(article_for_email, email, current_user).deliver!
      end

      def crawling
        # @all_tags = Tag.all
        @media = Medium.find(params[:media_id])
        if @media.url_crawling?
          url_media_array = @media.url_crawling.split(',')
          get_articles(url_media_array)
          Article.where(medium_id: params[:media_id],
                        created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day).where.not(id: Article.group(:url_article).select('min(id)')).destroy_all

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
        media.map do |med|
          media_ids << med['id']
        end

        conditions = {}
        # conditions[:status] = 'confirmed'
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
                       tags: all_tags }
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
        # conditions[:status] = 'confirmed'

        conditions[:medium_type] = params[:medium_type].split(',') unless params[:medium_type].blank?

        conditions[:media_area] = params[:media_area].split(',') unless params[:media_area].blank?

        conditions[:author_id] = params[:authors_ids].split(',') unless params[:authors_ids].blank?

        conditions[:language] = params[:language].split(',') unless params[:language].blank?

        unless params[:start_date].blank?
          # conditions[:date_published] = { gte: Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 }), lte: Date.today.to_datetime.change({ hour: 0, min: 0, sec: 0 }) }

          #  else
          conditions[:date_published] =
            { gte: params[:start_date].to_datetime.change({ hour: 0, min: 0, sec: 0 }),
              lte: params[:end_date].to_datetime.change({ hour: 0, min: 0, sec: 0 }) }
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

        #
        #     if params[:media_id].blank?
        #
        #       @articles = Article.order(order_and_direction).page(page).per(per_page)
        #     else
        #
        #       @articles = Article.order(order_and_direction).where(medium_id: params[:media_id].split(',')).page(page).per(per_page)
        #
        #     end
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
          articles_elcherouk_crawler(url_media_array, @media)
        when 'ENNAHAR'
          articles_ennahar_crawler(url_media_array, @media)
        when 'TSA'
          articles_tsa_crawler(url_media_array, @media)
        when 'APS'
          get_articles_aps(url_media_array)
        when 'APS-AR'
          get_articles_aps_ar(url_media_array)
        when 'MAGHREBEMERGENT'
          articles_maghrebemergent_crawler(url_media_array, @media)
        when 'ELBILAD'
          articles_bilad_crawler(url_media_array, @media)
        when 'ELMOUDJAHID'
          get_articles_elmoudjahid(url_media_array)
        when 'ELMOUDJAHID-FR'
          get_articles_elmoudjahid_fr(url_media_array)
        when 'ELKHABAR'
          articles_elkhabar_crawler(url_media_array, @media)
        when 'ELKHABAR-FR'
          articles_elkhabar_fr_crawler(url_media_array, @media)
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
        when 'LIBERTE-AR'
          get_articles_liberte_ar(url_media_array)
        when 'VISAALGERIE'
          articles_visaalgerie_crawler(url_media_array, @media)
        when 'SANTENEWS'
          get_articles_santenews(url_media_array)
        when 'ALGERIE360'
          articles_algerie360_crawler(url_media_array, @media)
        when 'ALGERIEPARTPLUS'
          get_articles_algerie_part(url_media_array)
        when '24H-DZ'
          articles_24hdz_crawler(url_media_array, @media)
        when 'REPORTERS'
          articles_reporters_crawler(url_media_array, @media)
        when 'SHIHABPRESSE'
          get_articles_shihabpresse(url_media_array)
        when 'LEXPRESSIONDZ'
          articles_lexpressiondz_crawler(url_media_array, @media)
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
          articles_alyaoum24_crawler(url_media_array, @media)
        when 'RADIOALGERIE-AR'
          articles_radioalgerie_ar_crawler(url_media_array, @media)
        when 'RADIOALGERIE-FR'
          articles_radioalgerie_fr_crawler(url_media_array, @media)
        when 'MAROCO360'
          articles_maroco360_crawler(url_media_array, @media)
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
      def articles_elcherouk_crawler(url_media_array, media)
        count = Articles::Crawling::Elcherouk.get_articles_elcherouk(url_media_array, media)
        render json: { crawling_elcherouk: count }
      end
      # end method to get elcherouk articles

      def articles_ennahar_crawler(url_media_array, media)
        count = Articles::Crawling::Ennahar.get_articles_ennahar(url_media_array, media)
        render json: { crawling_ennahar: count }
      end

      def articles_tsa_crawler(url_media_array, media)
        count = Articles::Crawling::Tsa.get_articles_tsa(url_media_array, media)
        render json: { crawling_tsa: count }
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
            articles_url_aps << "http://www.aps.dz#{link['href']}" # if link['class'] == 'main_article'
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
            article = Nokogiri::HTML(URI.open(link, read_timeout: 3600))
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
          d = change_date_autobip_aps(date)
          new_article.date_published = d.to_datetime.change({ hour: 0, min: 0, sec: 0 })
          # new_article.date_published =
          url_array = article.css('div.itemImageBlock span.itemImage img').map do |link|
            "http://www.aps.dz#{link['src']}"
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
          tags_array = article.css('ul.itemTags li').map(&:text)
          # new_article.media_tags = tags_array.join(',')
          new_article.status = 'pending'
          new_article.save!
          # tag_check_and_save(tags_array)if @media.tag_status == true
        end
        render json: { crawling_status_aps: 'ok' }
      end
      # end method to get APS articles

      # start method to get APS-AR articles
      def get_articles_aps_ar(url_media_array)
        articles_url_APSar = []
        url_media_array.map do |url|
          begin
            doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.5', 'From' => 'foo@bar.invalid'), nil, 'UTF-8')
          rescue OpenURI::HTTPError => e
            puts "Can't access #{url}"
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
          pp "========================="
          pp date
          pp "========================="
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
          new_article.save!
        end
        render json: { crawling_status_APSar: 'ok' }
      end
      # end method to get APS-AR articles

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
        articles_url_le_soir.map do |link|
          articles_url_le_soir_after_check << link unless Article.where(medium_id: @media.id,
                                                                        url_article: link).present?
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
          new_article.save!
          # #tag_check_and_save(tags_array)if @media.tag_status == true
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
            articles_url_liberte << "https://www.liberte-algerie.com#{link['href']}" # if link['class'] == 'main_article'
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
          # tags_array = article.css('ul.itemTags li').map(&:text)
          # new_article.media_tags = tags_array.join(',')
          new_article.status = 'pending'
          new_article.save!
          # tag_check_and_save(tags_array)if @media.tag_status == true
        end
        render json: { crawling_status_liberte: 'ok' }
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
        last_dates = last_dates.map { |d| change_date_autobip_aps(d) }
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
          # tags_array = article.css('ul.itemTags li').map(&:text)
          # new_article.media_tags = tags_array.join(',')
          new_article.status = 'pending'
          new_article.save!
          # tag_check_and_save(tags_array)if @media.tag_status == true
        end
        render json: { crawling_status_liberte_ar: 'ok' }
      end
      # end method to get _liberte_ar articles

      # start method to get 24hdz articles
      def articles_24hdz_crawler(url_media_array, media)
        count = Articles::Crawling::Hdz24.get_articles_24hdz(url_media_array, media)
        render json: { crawling_24hdz: count }
      end
      # end method to get 24hdz articles

      # start method to get reporters articles
      def articles_reporters_crawler(url_media_array, media)
        count = Articles::Crawling::Reporters.get_articles_reporters(url_media_array, media)
        render json: { crawling_reporters: count }
      end
      # end method to get reporters articles

      # start method to get bilad articles
      def articles_bilad_crawler(url_media_array, media)
        count = Articles::Crawling::Bilad.get_articles_bilad(url_media_array, media)
        render json: { crawling_bilad: count }
      end
      # end method to get bilad articles
      #

      # start method to get maghrebemergent articles
      def articles_maghrebemergent_crawler(url_media_array, media)
        count = Articles::Crawling::Maghrebemergent.get_articles_maghrebemergent(url_media_array, media)
        render json: { crawling_maghrebemergent: count }
      end
      # end method to get maghrebemergent articles
      

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
          unless Article.where(medium_id: @media.id, url_article: link).present?
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
          url_array = article.css('article.module-article figure img').map { |link| link['data-src'] }
          new_article.url_image = url_array[0]
          pp "****************************"
          pp url_array[0]
          pp "****************************"
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
      def articles_elkhabar_crawler(url_media_array, media)
        count = Articles::Crawling::Elkhabar.get_articles_elkhabar(url_media_array, media)
        render json: { crawling_elkhabar: count }
      end
      # end method to get elkhabar articles
      #

      # start method to get elkhabar_fr articles
      def articles_elkhabar_fr_crawler(url_media_array, media)
        count = Articles::Crawling::ElkhabarFr.get_articles_elkhabar_fr(url_media_array, media)
        render json: { crawling_elkhabar_fr: count }
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
          date = article.at('time[datetime]')['datetime']
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
          new_article.save!
          # tag_check_and_save(tags_array) if @media.tag_status == true
        end
        render json: { crawling_status_aps: 'ok' }
      end
      # end method to get elikhba ria articles

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
          date = article.at('time[datetime]')['datetime']
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
          new_article.save!
          # tag_check_and_save(tags_array)
        end
        render json: { crawling_status_aps: 'ok' }
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
      def articles_visaalgerie_crawler(url_media_array, media)
        count = Articles::Crawling::Visaalgerie.get_articles_visaalgerie(url_media_array, media)
        render json: { crawling_algerie360: count }
      end
      # end method to get elhiwar articles

      # start method to get algerie360
      def articles_algerie360_crawler(url_media_array, media)
        count = Articles::Crawling::Algerie360.get_articles_algerie360(url_media_array, media)
        render json: { crawling_algerie360: count }
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
          unless Article.where(medium_id: @media.id, url_article: link).present?
            articles_url_shihabpresse_after_check << link
          end
        end

        articles_url_shihabpresse_after_check.map do |link|
          puts 'link link link link link link link link'
          puts link
          puts 'link link link link link link link link'
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
        end
        render json: { crawling_count_shihabpresse: count }
      end
      # end method to get shihabpresse articles

      # start method to get expression articles
      def articles_lexpressiondz_crawler(url_media_array, media)
        count = Articles::Crawling::Lexpressiondz.get_articles_lexpressiondz(url_media_array, media)
        render json: { crawling_lexpressiondz: count }
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
          articles_url_lematin_after_check << link unless Article.where(medium_id: @media.id,
                                                                        url_article: link).present?
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
          new_article.date_published = date_published_array.reject(&:nil?)[0].to_datetime.change({ hour: 0, min: 0,
                                                                                                   sec: 0 })
          url_array = article.css('img.d-block.w-100').map { |link| link['src'] }
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
          articles_url_aujourdhui_after_check << link unless Article.where(medium_id: @media.id,
                                                                           url_article: link).present?
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
            doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.5', 'From' => 'foo@bar.invalid'), nil, 'UTF-8')
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
            doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.5', 'From' => 'foo@bar.invalid'), nil, 'UTF-8')
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
            doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.5', 'From' => 'foo@bar.invalid'), nil, 'UTF-8')
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
          articles_url_elmaouid_after_check << link unless Article.where(medium_id: @media.id,
                                                                         url_article: link).present?
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
            doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.5', 'From' => 'foo@bar.invalid'), nil, 'UTF-8')
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
          articles_url_huffingtonpost_after_check << link unless Article.where(medium_id: @media.id,
                                                                               url_article: link).present?
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
                           Author.where(['lower(name) like ? ', 'Huffington-post auteur'.downcase])
                         else
                           a = author_exist_final
                           Author.where(['lower(name) like ? ',
                                         a.downcase])
                         end

          new_author = Author.new
          if author_exist.count.zero?

            new_author.name = author_exist_final.nil? || author_exist_final == '' ? 'Huffington-post auteur' : author_exist_final
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
          url_array =  article.css('div.post-contents.yr-entry-text img.image__src').map { |link| link['src'] }
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
            doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'ruby/2.6.5', 'From' => 'foo@bar.invalid'), nil, 'UTF-8')
          rescue OpenURI::HTTPError => e
            puts "Can't access #{url}"
            puts e.message
            puts
            next
          end

          doc.css('h3.text-xl a').map do |link|
            articles_url_elwatan << link['href']
          end
        end
        articles_url_elwatan = articles_url_elwatan.reject(&:nil?)

        articles_url_elwatan_after_check = []
        articles_url_elwatan.map do |link|
          articles_url_elwatan_after_check << link unless Article.where(medium_id: @media.id,
                                                                        url_article: link).present?
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
          new_article.save!
        end
        render json: { crawling_status_elwatan: 'ok' }
      end
      # end method to get elwatan articles

      # start method to get alyaoum24 articles
      def articles_alyaoum24_crawler(url_media_array, media)
        count = Articles::Crawling::Alyaoum24.get_articles_alyaoum24(url_media_array, media)
        render json: { crawling_alyaoum24: count }
      end
      # end method to get alyaoum24 articles

      # start method to get radioalgerie-ar articles
      def articles_radioalgerie_ar_crawler(url_media_array, media)
        count = Articles::Crawling::RadioalgerieAr.get_articles_radioalgerie(url_media_array, media)
        render json: { crawling_radioalgerie_ar: count }
      end
      # end method to get radioalgerie-ar articles

      # start method to get radioalgerie-fr articles
      def articles_radioalgerie_fr_crawler(url_media_array, media)
        count = Articles::Crawling::RadioalgerieFr.get_articles_radioalgerie(url_media_array, media)
        render json: { crawling_radioalgerie_fr: count }
      end
      # end method to get radioalgerie-fr articles

      # start method to get maroco360 articles
      def articles_maroco360_crawler(url_media_array, media)
        count = Articles::Crawling::Maroco360.get_articles_maroco360(url_media_array, media)
        render json: { crawling_maroco360: count }
      end
   
      # end method to get maroco360 articles

      # Only allow a trusted parameter "white list" through.
      def article_params
        params.permit(:title, :date_published, :author, :body,
                      :media_tags, :language, :url_image, :author_id)
      end

      # tag_check_and_savetag_check_and_save not used yet
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

      # change_translate_date
      def change_translate_date(d)
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
          when 'أوت'.downcase
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
      #                 <p style="font-size: 12px; line-height: 1; color:brown; margin-top:5px;">
      #                  TAGS :  <%= article.tags.map(&:name).uniq.join(' - ')  %>
      #
      #                 </p>
      #        <p style="font-size: 12px; line-height: 1; color:brown; margin-top:5px;direction: rtl;">
      #                       الكلمات الدالة :  <%= article.tags.map(&:name).uniq.join(' - ')  %>
      #                     </p>
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
    end
  end
end
