# frozen_string_literal: true

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
