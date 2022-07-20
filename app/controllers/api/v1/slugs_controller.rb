# frozen_string_literal: true

module Api
  module V1
    # CRUD for authors
    class SlugsController < ::ApplicationController
      before_action :authenticate_user!
      before_action :set_slug, only: %i[show update destroy]

      # GET /slugs
      def index
        @slugs = fetch_slugs
        set_pagination_headers :slugs
        json_string = SlugSerializer.new(@slugs).serializable_hash.to_json
        render json: json_string
      end

      # GET /slugs/1
      def show
        json_string = SlugSerializer.new(@slug).serializable_hash.to_json
        render json: json_string
      end

      # POST /slugs
      def create
        @slug = Slug.new(slug_params)

        if @slug.save
          render json: @slug, status: :created
        else
          render json: @slug.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /slugs/1
      def update
        if @slug.update(slug_params)
          render json: @slug
        else
          render json: @slug.errors, status: :unprocessable_entity
        end
      end

      # DELETE /slugs/1
      def destroy
        @slug.destroy
      end

      def destroy_all
        Slug.where(id: params[:ids]).destroy_all
      end

      private

      # Use callbacks to share common setup or constraints between actions.
      def set_slug
        @slug = Slug.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def slug_params
        params.require(:slug).permit(:name)
      end

      # fet slugs
      def fetch_slugs
        if params[:search].present?
          search_slugs
        else
          Slug.order(order_and_direction).page(page).per(per_page)
        end
       
      end

      # search slugs
      def search_slugs
        Slug.order(order_and_direction).page(page).per(per_page)
            .where(['lower(name) like ? ',
                    "%#{params[:search].downcase}%"])
      end
    end
  end
end
