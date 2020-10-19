class Api::V1::ListUsersController < ApplicationController
  before_action :set_list_user, only: %i[show update destroy]

  # GET /list_users
  def index
    @list_users =
        if params[:search].blank?
          ListUser.order(order_and_direction).page(page).per(per_page)
        else
          ListUser.order(order_and_direction).page(page).per(per_page)
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
    params[:user_id] = current_user.id
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
    params.permit(:name, :user_id)
  end
end
