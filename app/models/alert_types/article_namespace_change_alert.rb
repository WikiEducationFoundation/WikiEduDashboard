# frozen_string_literal: true

# == Schema Information
#
# Table name: alerts
#
#  id             :integer          not null, primary key
#  course_id      :integer
#  user_id        :integer
#  article_id     :integer
#  revision_id    :integer
#  type           :string(255)
#  email_sent_at  :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  message        :text(65535)
#  target_user_id :integer
#  subject_id     :integer
#  resolved       :boolean          default(FALSE)
#  details        :text(65535)
#

# frozen_string_literal: true

class ArticleNamespaceChangeAlert < Alert
  def main_subject
    "#{article.title}"
  end

  def url
    article_url
  end

  # def email_body
  #   <<~BODY
  #     Hi #{content_expert.username},

  #     The article "#{article.title}" has been moved from the #{namespace_name(old_namespace)} namespace to the #{namespace_name(new_namespace)} namespace.

  #     #{url}

  #     Thanks,
  #     #{site_name} #{signature}
  #   BODY
  # end

  # private

  def article
    @article ||= Article.find_by(id: article_id)
  end
end

