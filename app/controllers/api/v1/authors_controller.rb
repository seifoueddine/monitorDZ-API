# frozen_string_literal: true

module Api
  module V1
    # CRUD for authors
    class AuthorsController < ::ApplicationController
      before_action :authenticate_user!
      before_action :set_author, only: %i[show update destroy]

      # GET /authors
      def index
        @authors = fetch_authors
        add_count
        set_pagination_headers :authors
        json_string = AuthorSerializer.new(@authors).serializable_hash.to_json
        render json: json_string
      end

      def authors_client
        slug_id = get_slug_id
        campaign = Campaign.where(slug_id: slug_id)
        media = campaign[0].media
        media_ids = []
        media.map do |med|
          media_ids << med['id']
        end
        @authors = Author.where(medium_id: media_ids).uniq
        json_string = AuthorSerializer.new(@authors).serializable_hash.to_json
        render json: json_string
      end

      # GET /authors/1
      def show
        json_string = AuthorSerializer.new(@author).serializable_hash.to_json
        render  json: json_string
      end

      # POST /authors
      def create
        @author = Author.new(author_params)

        if @author.save
          render json: @author, status: :created
        else
          render json: @author.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /authors/1
      def update
        if @author.update(author_params)
          render json: @author
        else
          render json: @author.errors, status: :unprocessable_entity
        end
      end

      # DELETE /authors/1
      def destroy
        if @author.articles.count.zero?
          @author.destroy
        else
          render json: {
            code: 'E010',
            message: 'Author has articles'
          },  status: 406
        end
      end

      private

      # Use callbacks to share common setup or constraints between actions.
      def set_author
        @author = Author.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def author_params
        params.require(:author).permit(:name, :medium_id, :articles_count)
      end

      # get_authors

      def fetch_authors
        if params[:search].present?
          search_authors
        elsif params[:medium_id].present?
          authors_by_media
        else
          Author.order(order_and_direction).page(page).per(per_page)
        end
      end

      # add article count to author
      def add_count
        @authors.each do |author|
          author.update articles_count: author.articles.count
        end
      end

      # search authors
      def search_authors
        Author.order(order_and_direction).page(page).per(per_page)
              .name_like(params[:search])
      end

      # search authors
      def authors_by_media
        Author.order(order_and_direction).page(page).per(per_page).where(medium_id: params[:medium_id])
      end
    end
  end
end
