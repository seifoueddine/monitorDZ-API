# frozen_string_literal: true

module Api
  module V1
    class CampaignsController < ::ApplicationController
      before_action :authenticate_user!
      before_action :set_campaign, only: %i[show update destroy]

      # GET /campaigns
      def index
        @campaigns =
          if params[:search].present?
            Campaign.order(order_and_direction).page(page).per(per_page)
            .where(['lower(name) like ? ',
                    "%#{params[:search].downcase}%"])
          else
            Campaign.order(order_and_direction).page(page).per(per_page)

          end
        set_pagination_headers :campaigns
        json_string = CampaignSerializer.new(@campaigns, include: %i[media slug]).serializable_hash.to_json

        render json: json_string
      end

      # GET /campaigns/1
      def show
        json_string = CampaignSerializer.new(@campaigns, include: [:media]).serializable_hash.to_json
        render json: json_string
      end

      # POST /campaigns
      def create
        @campaign = Campaign.new(campaign_params)

        # sector_ids = params[:sector_id].split(',')
        # @sector = if sector_ids.length != 1
        #             Sector.where(id: sector_ids)
        #           else
        #             Sector.where(id: params[:sector_id])
        #           end
        campaign_params[:media_id] ||= params[:media_id]
        campaign_params[:tag_id] ||= params[:tag_id]
        if campaign_params[:media_id].present?
          madia_ids = campaign_params[:media_id].split(',')
          # @media = if madia_ids.length != 1
          #            Medium.where(id: madia_ids)
          #          else
          #            Medium.where(id: campaign_params[:media_id])
          #          end
          @media = Medium.where(id: madia_ids)
          pp @media
          @campaign.media << @media
          pp '**************'
          pp @campaign.media
        end

        if campaign_params[:tag_id].present?

         tag_ids = campaign_params[:tag_id].split(',')
        #  @tag = if tag_ids.length != 1
        #          Tag.where(id: tag_ids)
        #        else
        #          Tag.where(id: params[:tag_id])
        #        end
        @tag =  Tag.where(id: tag_ids)
        @campaign.tags << @tag
        end
       # @campaign.sectors = @sector
        if @campaign.save
          render json: @campaign, status: :created
        else
          render json: @campaign.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /campaigns/1
      def update
        if @campaign.update(campaign_params)

         # @campaign.media.clear
        #  @campaign.sectors.clear
         
          # sector_ids = params[:sector_id].split(',')
          # @sector = if sector_ids.length != 1
          #             Sector.where(id: sector_ids)
          #           else
          #             Sector.where(id: params[:sector_id])
          #           end
          campaign_params[:media_id] ||= params[:media_id]
          campaign_params[:tag_id] ||= params[:tag_id]
          if campaign_params[:media_id].present?
            @campaign.media.clear
            madia_ids = campaign_params[:media_id].split(',')
            # @media = if madia_ids.length != 1
            #          Medium.where(id: madia_ids)
            #        else
            #          Medium.where(id: campaign_params[:media_id])
            #        end
                   @media = Medium.where(id: madia_ids)
            @campaign.media = @media
          end
        
          if campaign_params[:tag_id].present?
          @campaign.tags.clear
          tag_ids = campaign_params[:tag_id].split(',')
          # @tag = if tag_ids.length != 1
          #          Tag.where(id: tag_ids)
          #        else
          #          Tag.where(id: campaign_params[:tag_id])
          #        end
          @tag = Tag.where(id: tag_ids)
          @campaign.tags = @tag
          end       
         
       
          #@campaign.sectors = @sector

          json_string = CampaignSerializer.new(@campaign, include: %i[media]).serializable_hash.to_json
          render json: json_string

        else
          render json: @campaign.errors, status: :unprocessable_entity
        end
      end

      # DELETE /campaigns/1
      def destroy
        @campaign.destroy
      end

      private

      # Use callbacks to share common setup or constraints between actions.
      def set_campaign
        @campaign = Campaign.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def campaign_params
        params.require(:campaign).permit(:name, :start_date, :end_date, :slug_id, :media_id, :tag_id)
      end
    end
  end
end
