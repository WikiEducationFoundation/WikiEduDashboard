# frozen_string_literal: true

# Rails' default field_error_proc wraps errored inputs in
# <div class="field_with_errors">…</div>. This override preserves that
# wrapper (so existing CSS selectors keep working) and additionally
# injects aria-invalid="true" onto the input/select/textarea element
# itself, so assistive technologies can identify the failing field
# programmatically (WCAG 2.1 3.3.1 Error Identification).

ActionView::Base.field_error_proc = proc do |html_tag, _instance|
  modified = html_tag.to_s.sub(/<(input|select|textarea)\b/, '<\1 aria-invalid="true"')
  "<div class=\"field_with_errors\">#{modified}</div>".html_safe
end
