# frozen_string_literal: true

module QuestionHelper
  def question_text_html_from_markdown(string)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(string)
  end

  def question_plain_text_from_markdown(string)
    strip_tags(question_text_html_from_markdown(string))
  end
end
