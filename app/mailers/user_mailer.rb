class UserMailer < ApplicationMailer
  def taggedarticles(articles)
    @articles = articles
    # @user = user
    mail to: 'nouaraseifeddine@gmail.com', subject: 'test email after auto tag'
  end
end
