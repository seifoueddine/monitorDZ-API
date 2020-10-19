class Api::V1::ListUsersController < ApplicationController
  before_action :set_list_user, only: %i[show update destroy]
  before_action :authenticate_user!
  # GET /list_users
  def index
    @user = current_user
    @list_users =
        if params[:search].blank?
          ListUser.where(user_id: @user.id).order(order_and_direction).page(page).per(per_page)
        else
          ListUser.where(user_id: @user.id).order(order_and_direction).page(page).per(per_page)
              .where(['lower(name) like ? ',
                      '%' + params[:search].downcase + '%'])
        end
    set_pagination_headers :list_users
    json_string = ListUserSerializer.new(@list_users).serializable_hash.to_json
    render json: json_string

  end

  # GET /list_users/1
  def show
    json_string = ListUserSerializer.new(@list_user).serializable_hash.to_json
    render json: json_string
  end

  # POST /list_users
  def create
    @user = current_user
    params[:user_id] = @user.id
    @list_user = ListUser.new(list_user_params)

    if @list_user.save
      render json: @list_user, status: :created
    else
      render json: @list_user.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /list_users/1
  def update
    if @list_user.update(list_user_params)

      @list_user.articles.clear

      ids = params[:article_id].split(',')
      @article = if ids.length != 1
                   Article.where(id: ids)
                 else
                   Article.where(id: params[:article_id])
                end

      @list_user.articles = @article

      render json: @list_user
    else
      render json: @list_user.errors, status: :unprocessable_entity
    end
  end




  # DELETE /list_users/1
  def destroy
    @list_user.destroy
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_list_user
    @list_user = ListUser.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def list_user_params
    params.permit(:name, :user_id,:article_id)
  end
end