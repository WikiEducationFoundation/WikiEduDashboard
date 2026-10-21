# frozen_string_literal: true

# The operator-written part of the admin detector comparison page: the preamble
# and the curated views, from config/detector_comparison_page.yml, with their
# Markdown rendered to HTML. Read on each request, so edits show up on deploy
# without publishing the comparison data again.
class RenderDetectorComparisonIntro
  CONTENT_PATH = Rails.root.join('config/detector_comparison_page.yml')
  # The table a view's selection applies to: 'topics' or 'known_human'.
  DEFAULT_DATASET = 'topics'

  attr_reader :result

  def initialize(path: CONTENT_PATH)
    content = YAML.safe_load_file(path)
    # hard_wrap: a line break inside a paragraph is kept, as in the preamble's signature.
    @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(escape_html: true,
                                                                    hard_wrap: true),
                                        tables: true, autolink: true)
    @result = { preamble_html: render(content['preamble']),
                views: Array(content['views']).map { |view| view_row(view) } }
  end

  private

  def view_row(view)
    { key: view['key'], title: view['title'], description_html: render(view['description']),
      dataset: view['dataset'] || DEFAULT_DATASET, selection: view['selection'] || {} }
  end

  def render(text)
    text.present? ? @markdown.render(text) : ''
  end
end
