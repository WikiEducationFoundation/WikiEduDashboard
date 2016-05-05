class AlertMailer < ApplicationMailer
  include ArticleHelper

  def alert(alert, recipient)
    return unless Features.email?
    @recipient = recipient
    @alert = alert
    @type = @alert.type
    @article = @alert.article
    @article_url = article_url(@article)
    mail(to: @recipient.email, subject: "#{@type}: #{@article.title}")
  end
end
