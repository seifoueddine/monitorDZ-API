class Api::V1::SlugsController < ApplicationController
  before_action :set_slug, only: [:show, :update, :destroy]

  # GET /slugs
  def index
    @slugs = 
    if params[:search].blank?
      Slug.order(order_and_direction).page(page).per(per_page)
    else
      Slug.order(order_and_direction).page(page).per(per_page)
          .where(['lower(name) like ? ',
                           '%' + params[:search].downcase + '%'
                           ])
    end
    set_pagination_headers :slugs
    json_string = SlugSerializer.new(@slugs).serialized_json
    render  json: json_string


  end

  # GET /slugs/1
  def show
      json_string = SlugSerializer.new(@slug).serialized_json
      render  json: json_string
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
      params.permit(:name)
    end
end
