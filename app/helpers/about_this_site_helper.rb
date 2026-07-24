# frozen_string_literal: true

#= Helpers for the about-this-site static pages
module AboutThisSiteHelper
  ACCESSIBILITY_REPORT_PATH = "#{Rails.root}/docs/vpat.md"
  CANVAS_INTEGRATION_GUIDE_PATH = "#{Rails.root}/docs/canvas_integration_guide.md"
  HECVAT_PATH = "#{Rails.root}/docs/hecvat.md"

  # Renders the canonical VPAT Markdown file to HTML for the public
  # /accessibility page. The Markdown file in docs/ is the single source of
  # truth; rendering it here avoids a second hand-maintained copy.
  def accessibility_report_html
    render_doc_markdown(ACCESSIBILITY_REPORT_PATH)
  end

  # Renders the public Canvas integration guide (docs/ Markdown) to HTML for
  # /lti/guide, same single-source-of-truth pattern as the VPAT above.
  def canvas_integration_guide_html
    render_doc_markdown(CANVAS_INTEGRATION_GUIDE_PATH)
  end

  # Renders the public HECVAT response (docs/ Markdown) to HTML for /hecvat,
  # published alongside the VPAT. Same single-source-of-truth pattern.
  def hecvat_html
    render_doc_markdown(HECVAT_PATH)
  end

  private

  # escape_html neutralizes any literal HTML in the source, so the rendered
  # output is safe to mark html_safe.
  def render_doc_markdown(path)
    renderer = Redcarpet::Render::HTML.new(escape_html: true)
    markdown = Redcarpet::Markdown.new(renderer, tables: true, autolink: true)
    markdown.render(File.read(path)).html_safe
  end
end
