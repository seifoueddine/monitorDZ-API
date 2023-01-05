# frozen_string_literal: true

module Api
  module V1
    class MediaController < ::ApplicationController
      before_action :authenticate_user!
      before_action :set_medium, only: %i[show update destroy]

      # GET /media
      def index
        @media = Medium.order(order_and_direction).page(page).per(per_page)
        if params[:search].present?
          @media = @media.name_like(params[:search])
        end
        set_pagination_headers :media
        render json: MediumSerializer.new(@media).serializable_hash.to_json
      end

      # GET /media/1
      def show
        render  json: MediumSerializer.new(@medium).serializable_hash.to_json
      end

      # POST /media
      def create
        @medium = Medium.new(medium_params)
        if @medium.save
          render json: @medium, status: :created
        else
          render json: @medium.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /media/1
      def update
        if @medium.update(medium_params)
          render json: @medium
        else
          render json: @medium.errors, status: :unprocessable_entity
        end
      end

      # DELETE /media/1
      def destroy
        check_campaign = @medium.campaigns.exists?
        if check_campaign
          render json: { code: 'E003', message: 'This media belongs to campaign' }, status: 406
        else
          @medium.destroy
        end
      end

      # def destroy_all
      #   Medium.where(id: params[:ids]).destroy_all
      # end

      private

      # Use callbacks to share common setup or constraints between actions.
      def set_medium
        @medium = Medium.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def medium_params
        params.require(:medium).permit(:name, :media_type, :orientation, :last_article,
                      :url_crawling, :avatar, :language, :zone, :tag_status)
      end
    end
  end
end
