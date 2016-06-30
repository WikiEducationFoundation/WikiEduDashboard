require "#{Rails.root}/lib/wiki_edits"

class WikiPreferencesManager
  def initialize(user:, wiki: nil)
    @user = user
    @wiki = wiki || Wiki.default_wiki
  end

  def enable_visual_editor
    ve_options = ['visualeditor-editor=visualeditor',
                  'visualeditor-hidebetawelcome=1',
                  'visualeditor-tabs=multi-tab'].join('|')
    params = { action: 'options',
               change: ve_options,
               format: 'json' }
    WikiEdits.new(@wiki).api_post params, @user
  end
end
