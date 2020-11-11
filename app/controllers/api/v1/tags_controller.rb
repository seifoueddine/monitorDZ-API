class Api::V1::TagsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tag, only: [:show, :update, :destroy]

  # GET /tags
  def index
    @tags =
        if params[:search].blank?
          Tag.order(order_and_direction).page(page).per(per_page)
        else
          Tag.order(order_and_direction).page(page).per(per_page)
              .where(['lower(name) like ? ',
                      '%' + params[:search].downcase + '%'])
        end
    set_pagination_headers :tags
    json_string = TagSerializer.new(@tags).serializable_hash.to_json
    render  json: json_string

  end

  # GET /tags/1
  def show
    json_string = TagSerializer.new(@tag).serializable_hash.to_json
    render  json: json_string
  end

  # POST /tags
  def create

    tag_exist = Tag.where(['lower(name) like ? ',
                            params[:name].downcase ]).count
    if tag_exist.zero?
    @tag = Tag.new(tag_params)

    if @tag.save
      render json: @tag, status: :created
    else
      render json: @tag.errors, status: :unprocessable_entity
    end
    else
      render json: {
          code: 'E001',
          message: 'tag exist'
      },  status: 406
    end
  end

  # PATCH/PUT /tags/1
  def update
    if params[:name].blank?
      if @tag.update(tag_params)
        render json: @tag
      else
        render json: @tag.errors, status: :unprocessable_entity
      end
    else
      tag_exist = Tag.where(['lower(name) like ? ',
                             params[:name].downcase]).count
      if tag_exist.zero?
        if @tag.update(tag_params)
          render json: @tag
        else
          render json: @tag.errors, status: :unprocessable_entity
        end
      else
        render json: {
            code: 'E001',
            message: 'tag exist'
        },  status: 406
      end
    end
  end

  # DELETE /tags/1
  def destroy
    @tag.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
  def set_tag
    @tag = Tag.find(params[:id])
  end

    # Only allow a trusted parameter "white list" through.
  def tag_params
    params.permit(:name, :status)
  end
end
