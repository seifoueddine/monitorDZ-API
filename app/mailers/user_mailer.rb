class UserMailer < ApplicationMailer
  def taggedarticles(articles, user, camp_tags)
    @articles = articles
    @user = user
    @tags = camp_tags
    mail to: user.email, subject: 'test email after auto tag'
  end
end
