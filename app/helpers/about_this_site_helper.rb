# frozen_string_literal: true

#= Helpers for the about-this-site static pages
module AboutThisSiteHelper
  ACCESSIBILITY_REPORT_PATH = "#{Rails.root}/docs/vpat.md"

  # Renders the canonical VPAT Markdown file to HTML for the public
  # /accessibility page. The Markdown file in docs/ is the single
  # source of truth; rendering it here avoids a second hand-maintained
  # copy. escape_html neutralizes any literal HTML in the source, so
  # the rendered output is safe to mark html_safe.
  def accessibility_report_html
    source = File.read(ACCESSIBILITY_REPORT_PATH)
    renderer = Redcarpet::Render::HTML.new(escape_html: true)
    markdown = Redcarpet::Markdown.new(renderer, tables: true, autolink: true)
    markdown.render(source).html_safe
  end
end
