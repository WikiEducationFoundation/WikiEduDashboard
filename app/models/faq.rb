# frozen_string_literal: true

# == Schema Information
#
# Table name: faqs
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  title      :string(255)      not null
#  content    :text(65535)
#
class Faq < ApplicationRecord
  def self.markdown_renderer
    @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  end

  def self.render_markdown(content)
    markdown_renderer.render(content)
  end

  def html_content
    Faq.render_markdown(content)
  end
end
