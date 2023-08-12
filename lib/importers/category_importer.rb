# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/replica"
require_dependency "#{Rails.root}/lib/importers/revision_score_importer"
require_dependency "#{Rails.root}/lib/importers/article_importer"
require_dependency "#{Rails.root}/lib/importers/average_views_importer"
require_dependency "#{Rails.root}/lib/category_utils"
require_dependency "#{Rails.root}/lib/wiki_api"

#= Imports articles for a category, along with view data and revision scores
class CategoryImporter
  ################
  # Entry points #
  ################
  def initialize(wiki, opts={})
    @wiki = wiki
    @depth = opts[:depth] || 0
    @min_views = opts[:min_views] || 0
    @max_wp10 = opts[:max_wp10] || 100
  end

  def mainspace_page_titles_for_category(category, depth=0)
    CategoryUtils.get_titles_without_prefixes(page_data_for_category(category, depth))
  end

  def page_titles_for_category(category, depth=0, namespace=nil)
    CategoryUtils.get_titles(page_data_for_category(category, depth, namespace))
  end

  private

  def page_data_for_category(category, depth=0, namespace=nil)
    cat_query = category_query(category, namespace)
    page_data = get_category_member_data(cat_query)
    if depth.positive?
      depth -= 1
      subcats = subcategories_of(category)
      subcats.each do |subcat|
        page_data += page_data_for_category(subcat, depth, namespace)
      end
    end
    page_data
  end

  def get_category_member_data(query)
    pages = []
    continue = true
    until continue.nil?
      cat_response = WikiApi.new(@wiki).query query
      pages_batch = cat_response.data['categorymembers']
      pages += pages_batch
      continue = cat_response['continue']
      query['cmcontinue'] = continue['cmcontinue'] if continue
    end
    pages
  end

  def subcategories_of(category)
    subcat_query = category_query(category, 14) # 14 is the Category namespace
    subcats_pages = get_category_member_data(subcat_query)
    CategoryUtils.get_titles(subcats_pages)
  end

  def category_query(category, namespace)
    { list: 'categorymembers',
      cmtitle: category,
      cmlimit: 500,
      cmnamespace: namespace || 0, # mainspace articles by default
      continue: '' }
  end
end
