# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/category_utils"
require_dependency "#{Rails.root}/lib/wiki_api"

# Fetches data about which wiki pages transclude a given page
class TransclusionImporter
  def initialize(template, update_service: nil)
    @template = template
    @wiki = template.wiki
    @name = template.name
    @update_service = update_service
  end

  def transcluded_titles
    CategoryUtils.get_titles_without_prefixes all_transcluded_pages
  end

  private

  def all_transcluded_pages
    wiki_api = WikiApi.new(@wiki, update_service: @update_service)
    @query = transclusion_query
    @transcluded_in = []
    until @continue == 'done'
      @query.merge! @continue unless @continue.nil?
      response = wiki_api.query @query
      @transcluded_in += response.data['pages'].values.first['transcludedin'] || []
      @continue = response['continue'] || 'done'
    end

    @transcluded_in
  end

  def transclusion_query
    {
      prop: 'transcludedin',
      titles: "Template:#{@name}",
      tinamespace: '0|1', # mainspace or talk space
      tilimit: 500
    }
  end
end
