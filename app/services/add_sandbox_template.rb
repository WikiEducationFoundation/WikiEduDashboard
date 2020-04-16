# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"
require_dependency "#{Rails.root}/lib/wiki_edits"

class AddSandboxTemplate
  def initialize(home_wiki:, sandbox:, sandbox_template:, current_user:)
    @current_user = current_user
    @sandbox = sandbox
    @default_template = '{{user sandbox}}'
    @sandbox_template = sandbox_template
    @wiki_editor = WikiEdits.new(home_wiki)
    @wiki_api = WikiApi.new(home_wiki)
    @initial_page_content = @wiki_api.get_page_content(@sandbox)
    add_template
  end

  private

  def add_template
    # Never double-post the sandbox template
    return if sandbox_template_present?
    default_template_present? ? replace_default_with_sandbox_template : add_sandbox_template
  end

  def sandbox_template_present?
    @initial_page_content.include?(@sandbox_template)
  end

  def default_template_present?
    @initial_page_content.include?(@default_template)
  end

  def replace_default_with_sandbox_template
    sandbox_summary = "replacing #{@default_template} with #{@sandbox_template}"
    replaced_page_content = @initial_page_content.gsub(@default_template, @sandbox_template)
    @wiki_editor.post_whole_page(@current_user, @sandbox, replaced_page_content, sandbox_summary)
  end

  def add_sandbox_template
    sandbox_summary = "adding #{@sandbox_template}"
    new_line_template = @sandbox_template + "\n"
    @wiki_editor.add_to_page_top(@sandbox, @current_user, new_line_template, sandbox_summary)
  end
end
