# Configuration for will_paginate to use the CSS classes from pagination.styl
# which are compatible with react-paginate

require 'will_paginate/view_helpers/action_view'

module WillPaginate
  module ActionView
    def will_paginate_translate(keys, options = {})
      if defined?(::I18n)
        key = keys.shift
        ::I18n.t(key, **options.merge(default: keys))
      else
        super
      end
    end

    def page_entries_info_translate(keys, options = {})
      if defined?(::I18n)
        key = keys.shift
        ::I18n.t(key, **options.merge(default: keys))
      else
        super
      end
    end
  end

  class LinkRenderer < ActionView::LinkRenderer
    protected

    def html_container(html)
      tag(:div, tag(:ul, html, class: 'pagination'), class: 'pagination-container')
    end

    def page_number(page)
      if page == current_page
        tag(:li, link(page, page, class: 'current'), class: 'selected')
      else
        tag(:li, link(page, page, rel: rel_value(page)))
      end
    end

    def previous_or_next_page(page, text, classname)
      if page
        tag(:li, link(text, page, class: classname))
      else
        tag(:li, link(text, '#', class: classname), class: 'disabled')
      end
    end

    def gap
      tag(:li, link('...', '#'), class: 'disabled')
    end

    # Preserve all search parameters in the pagination links
    def url(page)
      @base_url_params ||= begin
        # Convert params to hash and exclude action/controller
        url_params = @template.params.to_unsafe_h.except('action', 'controller').symbolize_keys
        merge_optional_params(url_params)
      end
      @base_url_params[:page] = page
      @template.url_for(@base_url_params)
    end
  end
end
