class UserMailer < ApplicationMailer
  def taggedarticles(articles, user)
    @articles = articles
    @user = user
    mail to: user.email, subject: 'test email after auto tag'
  end
end
