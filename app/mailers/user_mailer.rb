class UserMailer < ApplicationMailer
  def taggedarticles(articles,camp_tags)
    @articles = articles
    @camp_tags = camp_tags
    # @user = user
    mail to: 'nouaraseifeddine@gmail.com', subject: 'test email after auto tag'
  end
end
