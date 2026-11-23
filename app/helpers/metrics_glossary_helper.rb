# frozen_string_literal: true

#= Helpers for the /metrics glossary page (AboutThisSiteController#metrics)
module MetricsGlossaryHelper
  DIVERGENCE_STATUS_LABELS = {
    'undecided' => 'Not yet decided',
    'intentional' => 'Intentional',
    'bug' => 'Bug',
    'fixed' => 'Fixed'
  }.freeze

  # Definitions are Markdown. escape_html neutralizes any literal HTML, so
  # the output is safe to mark html_safe.
  def glossary_markdown(text)
    return if text.blank?
    renderer = Redcarpet::Render::HTML.new(escape_html: true)
    Redcarpet::Markdown.new(renderer, autolink: true).render(text).html_safe
  end

  # The English text of a translation key, as the Dashboard shows it. It's
  # escaped like any other string, including keys that hold HTML.
  def glossary_i18n_text(key)
    I18n.t(key, locale: :en, default: '')
  end

  # A pointer that no longer resolves fails the glossary spec, but the page
  # shows it as plain text rather than failing to render.
  def glossary_code_link(ref)
    return content_tag(:code, ref.label) if ref.error
    location = ref.line ? "#{ref.path}:#{ref.line}" : ref.path
    link = link_to(ref.label, ref.url, class: 'metrics-glossary__code-link')
    note = ref.note.present? ? content_tag(:span, ref.note, class: 'metrics-glossary__note') : nil
    location_tag = content_tag(:span, location, class: 'metrics-glossary__location')
    safe_join([link, ' ', location_tag, note].compact)
  end

  # A link to another entry, or plain text when that entry is hidden from
  # this viewer.
  def glossary_metric_link(key)
    metric = @glossary.metrics[key]
    return key unless metric
    return metric.name unless @visible_metric_keys.include?(key)
    link_to metric.name, "##{key}"
  end

  # Plain text, for the collapsed summary line (a summary shouldn't hold links).
  def glossary_metric_name(key)
    @glossary.metrics[key]&.name || key
  end

  def glossary_divergence_status_label(divergence)
    DIVERGENCE_STATUS_LABELS.fetch(divergence.status, divergence.status)
  end

  def glossary_divergence_status(divergence)
    label = glossary_divergence_status_label(divergence)
    return label unless divergence.issue
    issue_url = "#{MetricsGlossary::REPO_URL}/issues/#{divergence.issue}"
    safe_join([label, ' (', link_to("##{divergence.issue}", issue_url), ')'])
  end

  def glossary_divergences_for(metric)
    @divergences.select { |divergence| divergence.metric_keys.include?(metric.key) }
  end
end
