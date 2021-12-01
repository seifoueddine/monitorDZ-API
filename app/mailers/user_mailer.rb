# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def taggedarticles(articles, user, camp_tags)
    @articles = articles
    @user = user
    @tags = camp_tags

    mail to: user.email, subject: 'Alerte TAG', from: 'Medias Monitoring <support@mediasmonitoring.com>'
  end

  def articleMail(article, receiver, current_user)
    @article = article
    @receiver = receiver
    @current_user = current_user
    mail to: @receiver, subject: "Article de la part de #{@current_user.name}",
         from: 'Medias Monitoring <support@mediasmonitoring.com>'
  end
end
