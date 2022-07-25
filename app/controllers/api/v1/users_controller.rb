# frozen_string_literal: true

module Api
  module V1
    class UsersController < ::ApplicationController
      before_action :authenticate_user!
      before_action :set_user, only: %i[show update change_password]

      # GET /users
      def index
        @users = if params[:search].present?
                   User.order(order_and_direction).page(page).per(per_page)
                   .where(['lower(name) like ?', "%#{params[:search].downcase}%"])
                 else
                  User.order(order_and_direction).page(page).per(per_page)
                 end
        set_pagination_headers :users
        json_string = UserSerializer.new(@users, include: [:slug]).serializable_hash.to_json
        render json: json_string
      end

      # GET /users/1
      def show
        json_string = UserSerializer.new(@user).serializable_hash.to_json
        render json: json_string
      end

      def change_password
        if @user.update(user_params)
          render json: @user
        else
          render json: @user.errors, status: :unprocessable_entity
        end
      end

      # POST /users
      def create
        @user = User.new(user_params)
        if @user.save
          render json: @user, status: :created
        else
          render json: @user.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /users/1
      def update
        if @user.update(user_params)
          render json: @user
        else
          render json: @user.errors, status: :unprocessable_entity
        end
      end

      # DELETE /users/1
      def destroy
        ids = params[:id].split(',')
        if ids.length != 1
          User.where(id: params[:id].split(',')).destroy_all
        else
          User.find(params[:id]).destroy
        end
      end

      private

      # Use callbacks to share common setup or constraints between actions.
      def set_user
        @user = User.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def user_params
        params.permit(:email, :password, :name, :created_at, :updated_at, :role,
                      :avatar, :slug_id)
      end
    end
  end
end
