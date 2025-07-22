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
  fuzzily_searchable :question_and_answer

  def self.markdown_renderer
    @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  end

  def self.render_markdown(content)
    markdown_renderer.render(content)
  end

  ##########################
  # Fuzzily search helpers #
  ##########################
  def question_and_answer
    "#{title} #{content}"
  end

  def saved_change_to_question_and_answer?
    saved_change_to_title? || saved_change_to_content?
  end

  #############
  # Rendering #
  #############
  def html_content
    Faq.render_markdown(content)
  end
end
