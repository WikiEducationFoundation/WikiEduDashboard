# frozen_string_literal: true

require "#{Rails.root}/lib/wiki_edits"

class WikiPreferencesManager
  def initialize(user:, wiki: nil)
    @user = user
    @wiki = wiki || Wiki.default_wiki
  end

  def enable_visual_editor
    ve_options = [
      'visualeditor-editor=visualeditor', # enables VE as default editor
      'visualeditor-hidebetawelcome=1', # skips the 'start editing' dialog on first edit
      'visualeditor-hideusered=1' # disables the blue dots on cite and link buttons
    ].join('|')
    #################
    # Other options #
    #################
    # 'visualeditor-tabs=multi-tab' # enables both Edit and Edit Source tabs

    params = { action: 'options',
               change: ve_options,
               format: 'json' }
    WikiEdits.new(@wiki).api_post params, @user
  end

  # def reset_visual_editor
  #   ve_options = ['visualeditor-hidebetawelcome=0',
  #                 'visualeditor-hideusered'].join('|')
  #   params = { action: 'options',
  #              change: ve_options,
  #              format: 'json' }
  #   WikiEdits.new(@wiki).api_post params, @user
  # end
end
