# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"
require_dependency "#{Rails.root}/lib/wiki_edits"

class AddSandboxTemplate
  DEFAULT_TEMPLATE = '{{user sandbox}}'
  def initialize(home_wiki:, sandbox:, sandbox_template:, current_user:)
    @current_user = current_user
    @sandbox = sandbox
    @sandbox_template = sandbox_template
    @wiki_editor = WikiEdits.new(home_wiki)
    wiki_api = WikiApi.new(home_wiki)
    @initial_page_content = wiki_api.get_page_content(@sandbox)
    add_template
  end

  private

  def add_template
    # Never double-post the sandbox template
    if sandbox_template_present?
      return
    elsif default_template_present?
      replace_default_with_sandbox_template
    else
      add_sandbox_template
    end
  end

  def sandbox_template_present?
    @initial_page_content.include?(@sandbox_template)
  end

  def default_template_present?
    @initial_page_content.include?(DEFAULT_TEMPLATE)
  end

  def replace_default_with_sandbox_template
    sandbox_summary = "replacing #{DEFAULT_TEMPLATE} with #{@sandbox_template}"
    replaced_page_content = @initial_page_content.gsub(DEFAULT_TEMPLATE, @sandbox_template)
    @wiki_editor.post_whole_page(@current_user, @sandbox, replaced_page_content, sandbox_summary)
  end

  def add_sandbox_template
    sandbox_summary = "adding #{@sandbox_template}"
    new_line_template = "#{@sandbox_template}\n"
    @wiki_editor.add_to_page_top(@sandbox, @current_user, new_line_template, sandbox_summary)
  end
end
