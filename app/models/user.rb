# frozen_string_literal: true

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  extend Devise::Models #added this line to extend devise model
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  include DeviseTokenAuth::Concerns::User
  mount_uploader :avatar, AvatarUploader
  belongs_to :slug

  
  def token_validation_response
    as_json(include: :slug)
  end
end
