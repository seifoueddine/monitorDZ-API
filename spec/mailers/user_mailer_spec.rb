# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
#  pending "add some examples to (or delete) #{__FILE__}"
before(:all) do
  @user = FactoryBot.create(:user)
 # sign_in @user
end
  describe "Send article mail to receiver" do
    # let(:user) { @user }
    let(:author_valid_attributes) do
      {
        name: 'Mohamed Salim',
      }
    end
    let(:medium_valid_attributes) do
      {
        name: 'Elkhabar',
        url_crawling: 'www.elkhabar.com'
      }
    end
    let(:article_valid_attributes) do
      {
        title: 'Campaign Name',
        medium_id: @medium.id,
        author_id: @author.id,
        language: 'fr',
        date_published: Date.today,
        body: 'xxxxx'
      }
    end
    
  
    let(:article_mail) { described_class.articleMail(@article, @receiver, @user) }  
    let(:tagged_article) { described_class.taggedarticles([@article], @user, ['tag1']) }  

    it 'article_mail renders the headers' do
      @receiver = ['test@gmailcom']
      @medium = Medium.create! medium_valid_attributes
      @author = Author.create! author_valid_attributes
      @article = Article.create! article_valid_attributes
      #binding.pry
      expect(article_mail.subject).to eq("Article de la part de #{@user.name}")
      expect(article_mail.to).to eq(@receiver)
    end

    it 'tagged_article renders the headers' do
      @medium = Medium.create! medium_valid_attributes
      @author = Author.create! author_valid_attributes
      @article = Article.create! article_valid_attributes
      expect(tagged_article.subject).to eq('Alerte TAG')
      expect(tagged_article.to).to eq([@user.email])
    end

    # it 'renders the body' do
    #   # whatever
    # end
  end
end
