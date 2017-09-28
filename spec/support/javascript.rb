# frozen_string_literal: true

module JavascriptHelper
  # Basecamp trix uses hidden input to populate its editor
  def fill_in_trix_editor(id, value)
    find(:xpath, "//*[@id='#{id}']", visible: false).set(value)
  end

  def select_from_chosen(item_text, options)
    option_value = page.evaluate_script("$(\"##{options[:from]} option:contains('#{item_text}')\").val()")
    page.execute_script("$('##{options[:from]}').val('#{option_value}')")
  end
end
