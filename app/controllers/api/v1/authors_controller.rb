class Api::V1::AuthorsController < ApplicationController
  before_action :set_author, only: %i[show update destroy]

  # GET /authors
  def index
    @authors = Author.all

    # set_pagination_headers :authors
    json_string = AuthorSerializer.new(@authors).serialized_json
    render json: json_string
  end


  def authors_client
    slug_id = get_slug_id
    campaign = Campaign.where(slug_id: slug_id)
    media = campaign[0].media
    media_ids = []
    media.map do |media|
      media_ids << media['id']
    end
    @authors = Author.where(medium_id: media_ids)
    json_string = AuthorSerializer.new(@authors).serialized_json
    render json: json_string
    end

    # GET /authors/1
  def show
    render json: @author
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
    @author.destroy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_author
    @author = Author.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def author_params
    params.permit(:name)
  end
end
