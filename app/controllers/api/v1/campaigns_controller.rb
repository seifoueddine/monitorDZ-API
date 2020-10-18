class Api::V1::CampaignsController < ApplicationController
  before_action :set_campaign, only: %i[show update destroy]

  # GET /campaigns
  def index
    @campaigns =
    if params[:search].blank?
      Campaign.order(order_and_direction).page(page).per(per_page)
    else
      Campaign.order(order_and_direction).page(page).per(per_page)
          .where(['lower(name) like ? ',
                           '%' + params[:search].downcase + '%'
                           ])
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

    sector_ids = params[:sector_id].split(',')
    @sector = if sector_ids.length != 1
                Sector.where(id: sector_ids)
              else
                Sector.where(id: params[:sector_id])
              end

    madia_ids = params[:media_id].split(',')
    @media = if sector_ids.length != 1
               Medium.where(id: madia_ids)
             else
               Medium.where(id: params[:media_id])
             end

    tag_ids = params[:tag_id].split(',')
    @tag = if tag_ids.length != 1
             Tag.where(id: tag_ids)
           else
             Tag.where(id: params[:tag_id])
           end
    @campaign.tags = @tag
    @campaign.media = @media
    @campaign.sectors = @sector
    if @campaign.save
      render json: @campaign, status: :created
    else
      render json: @campaign.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /campaigns/1
  def update
    if @campaign.update(campaign_params)


      @campaign.media.clear
      @campaign.sectors.clear
      @campaign.tags.clear
      sector_ids = params[:sector_id].split(',')
      @sector = if sector_ids.length != 1
                  Sector.where(id: sector_ids)
                else
                  Sector.where(id: params[:sector_id])
                end

      madia_ids = params[:media_id].split(',')
      @media = if madia_ids.length != 1
                 Medium.where(id: madia_ids)
               else
                 Medium.where(id: params[:media_id])
               end

      tag_ids = params[:tag_id].split(',')
      @tag = if tag_ids.length != 1
               Tag.where(id: tag_ids)
             else
               Tag.where(id: params[:tag_id])
             end
      @campaign.tags = @tag
      @campaign.media = @media
      @campaign.sectors = @sector

      json_string = CampaignSerializer.new(@campaign, include: %i[sectors media]).serializable_hash.to_json
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
    params.permit(:name, :start_date, :end_date, :slug_id)
  end
end
