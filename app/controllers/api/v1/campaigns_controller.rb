class Api::V1::CampaignsController < ApplicationController
  before_action :set_campaign, only: [:show, :update, :destroy]

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
    json_string = CampaignSerializer.new(@campaigns, include: [:sectors, :media]).serialized_json

    render  json: json_string
  end

  # GET /campaigns/1
  def show
    json_string = CampaignSerializer.new(@campaigns, include: [:sectors, :media]).serialized_json
    render  json: json_string
  end

  # POST /campaigns
  def create
    @campaign = Campaign.new(campaign_params)

    sector_ids = params[:sector_id].split(',')
    if sector_ids.length != 1
      @sector = Sector.where(id: sector_ids)
    else
      @sector = Sector.where(id: params[:sector_id])
    end

    madia_ids = params[:madia_id].split(',')
    if sector_ids.length != 1
      @media = Medium.where(id: madia_ids)
    else
      @media = Medium.where(id: params[:madia_id])
    end

    @campaign.media = @media 
    if @campaign.save
      render json: @campaign, status: :created
    else
      render json: @campaign.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /campaigns/1
  def update
    if @campaign.update(campaign_params)
      render json: @campaign
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
      params.permit(:name, :start_date, :end_date)
    end
end
