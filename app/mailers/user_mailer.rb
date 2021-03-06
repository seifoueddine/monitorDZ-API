class UserMailer < ApplicationMailer
  def taggedarticles(articles, user, camp_tags)
    @articles = articles
    @user = user
    @tags = camp_tags
    mail to: user.email, subject: 'Alerte TAG'
  end

  def articleMail(article, receiver, current_user)
    @article = article
    @receiver = receiver
    @current_user = current_user
    mail to: @receiver, subject: 'Article de la part de ' + @current_user.name
  end


end
