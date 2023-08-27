# frozen_string_literal: true

module Api
  module V1
    class ListUsersController < ::ApplicationController
      before_action :set_list_user, only: %i[show update destroy]
      before_action :authenticate_user!
      before_action :set_current_user, only: %i[index create]

      # GET /list_users
      def index
        @list_users = fetch_list_users
        set_pagination_headers :list_users
        render json: ListUserSerializer.new(@list_users).serializable_hash.to_json
      end

      # GET /list_users/1
      def show
        render json: {
          lists: ListUserSerializer.new(@list_user),
          articles: ArticleSerializer.new(@list_user.articles)
        }
      end

      # POST /list_users
      def create
        @list_user = ListUser.new(list_user_params.merge(user_id: @user.id))

        if @list_user.save
          render json: @list_user, status: :created
        else
          render json: @list_user.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /list_users/1
      def update
        if @list_user.update(list_user_params)
          handle_articles if article_params_present?
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

      def set_current_user
        @user = current_user
      end

      def fetch_list_users
        query = ListUser.where(user_id: @user.id).order(order_and_direction).page(page).per(per_page)
        params[:search].present? ? query.name_like(params[:search]) : query
      end

      def set_list_user
        @list_user = ListUser.find(params[:id])
      end

      def article_params_present?
        params[:delete_article_id].present? || params[:article_id].present?
      end

      def handle_articles
        if params[:delete_article_id].present?
          article_ids = @list_user.articles.ids - [params[:delete_article_id].to_i]
          @list_user.articles = Article.where(id: article_ids)
        elsif params[:article_id].present?
          article_ids = params[:article_id].split(',').map(&:to_i) + @list_user.articles.ids
          @list_user.articles = Article.where(id: article_ids)
        end
      end

      def list_user_params
        params.require(:list_user).permit(:name, :user_id, :image)
      end
    end
  end
end
