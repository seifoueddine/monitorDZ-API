class Api::V1::MediaController < ApplicationController
  before_action :set_medium, only: [:show, :update, :destroy]

  # GET /media
  def index
    @media = 
    if params[:search].blank?
      Medium.order(order_and_direction).page(page).per(per_page)
    else
      Medium.order(order_and_direction).page(page).per(per_page)
          .where(['lower(name) like ? ',
                           '%' + params[:search].downcase + '%'
                           ])
    end
    set_pagination_headers :media
    json_string = MediaSerializer.new(@media).serialized_json
    render  json: json_string
  end

  # GET /media/1
  def show
    render json: @medium
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
    @medium.destroy
  end

  def destroy_all
    Medium.where(id: params[:ids]).destroy_all
end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_medium
      @medium = Medium.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def medium_params
      params.permit(:name, :type, :orientation)
    end
end
