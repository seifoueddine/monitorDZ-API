# frozen_string_literal: true

module Api
  module V1
    class SectorsController < ApplicationController
      before_action :set_sector, only: %i[show update destroy]

      # GET /sectors
      def index
        @sectors =
          if params[:search].blank?
            Sector.order(order_and_direction).page(page).per(per_page)
          else
            Sector.order(order_and_direction).page(page).per(per_page)
                  .where(['lower(name) like ? ',
                          "%#{params[:search].downcase}%"])
          end
        set_pagination_headers :sectors
        json_string = SectorSerializer.new(@sectors).serializable_hash.to_json
        render json: json_string
      end

      # GET /sectors/1
      def show
        render json: @sector
      end

      # POST /sectors
      def create
        @sector = Sector.new(sector_params)

        if @sector.save
          render json: @sector, status: :created
        else
          render json: @sector.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /sectors/1
      def update
        if @sector.update(sector_params)
          render json: @sector
        else
          render json: @sector.errors, status: :unprocessable_entity
        end
      end

      # DELETE /slugs/1
      def destroy
        check_media = @sector.media.count.positive?
        check_campaign = @sector.campaigns.positive?
        if check_media == true
          render json: {
            code: 'E001',
            message: 'This sector belongs to media'
          },  status: 406
        elsif check_campaign == true
          render json: {
            code: 'E002',
            message: 'This sector belongs to campaign'
          },  status: 406

        else
          @sector.destroy
        end
      end

      def destroy_all
        Sector.where(id: params[:ids]).destroy_all
      end

      private

      # Use callbacks to share common setup or constraints between actions.
      def set_sector
        @sector = Sector.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def sector_params
        params.permit(:name)
      end
    end
  end
end
