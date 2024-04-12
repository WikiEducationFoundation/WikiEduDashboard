# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/training/wiki_slide_parser"
require_dependency "#{Rails.root}/lib/training/training_base"
require_dependency "#{Rails.root}/lib/wiki_api"

# Loads any of the three types of training content:
# TrainingLibrary, TrainingModule, TrainingSlide
# Source of content is training_content yaml files and/or wiki pages.
class WikiTrainingLoader
  def self.load_content(content_class, slug_list)
    puts "STEP - Loading #{content_class} from wiki"
    # content_class_object = content_class.constantize
    @content_class = content_class # TrainingLibrary, TrainingModule, or TrainingSlide
    @slug_list = slug_list # limited list of slugs to process (optional)
    # Index page that links to all the libraries, modules or slides to be loaded
    @wiki_base_page = content_class.wiki_base_page

    load_from_wiki
  end

  private

  #####################
  # On-wiki trainings #
  #####################

  def self.load_from_wiki
    source_pages = @slug_list ? listed_wiki_source_pages : wiki_source_pages
    raise_no_matching_wiki_pages_error if source_pages.empty?
    Sentry.capture_message "Loading #{@content_class}s from wiki",
                           level: 'info', extra: { wiki_pages: source_pages }

    source_pages.each do |wiki_page|
      TrainingBase.update_status_to_started(@content_class, wiki_page)
      add_trainings_to_collection(wiki_page)
      TrainingBase.update_status_to_complete(@content_class, wiki_page)
    end
  end

  def self.add_trainings_to_collection(wiki_page)
    content = new_from_wiki_page(wiki_page)
    unless content&.valid?
      Sentry.capture_message 'Invalid wiki training content',
                             level: 'warning', extra: { content:, wiki_page: }
      return
    end
  end

  def self.new_from_wiki_page(wiki_page)
    wikitext = WikiApi.new(MetaWiki.new).get_page_content(wiki_page)
    return if wikitext.blank? # Handle wiki pages that don't exist.

    # Handles either json pages or regular wikitext pages
    content = if wiki_page[-5..] == '.json'
                new_from_json_wiki_page(wikitext)
              else
                new_from_wikitext_page(wiki_page, wikitext)
              end
    puts "STEP - Adding #{@content_class} #{content['slug']} from #{wiki_page}"
    @content_class.inflate(content, content['slug'], wiki_page)
  end

  # json pages have all the required data within the json content, but optionally
  # point to a wiki page for the content
  def self.new_from_json_wiki_page(json_wikitext)
    content = Oj.load(json_wikitext)
    base_page = content['wiki_page']
    return content unless base_page
    wikitext = WikiApi.new(MetaWiki.new).get_page_content(base_page)
    training_content_and_translations(content:, base_page:, wikitext:)
  end

  # wikitext pages have the slide id and slug embedded in the page title
  def self.new_from_wikitext_page(wiki_page, wikitext)
    content = slug_and_id_from(wiki_page)
    training_content_and_translations(content:, base_page: wiki_page, wikitext:)
  end

  # Gets the training hashes for the page itself and any translations that exist.
  def self.training_content_and_translations(content:, base_page:, wikitext:)
    full_content = content.merge training_hash_from(wiki_page: base_page, wikitext:)
    full_content['translations'] = {}
    translated_pages(base_page:, base_page_wikitext: wikitext).each do |translated_page|
      language = translated_page.split('/').last
      full_content['translations'][language] = training_hash_from(wiki_page: translated_page)
    end
    full_content
  end

  # Gets a list of page titles linked from the base page
  def self.wiki_source_pages
    # To handle more than 500 pages linked from the source page,
    # we'll need to update this to use 'continue'.
    query_params = { prop: 'links', titles: @wiki_base_page, pllimit: 500 }
    response = WikiApi.new(MetaWiki.new).query(query_params)
    begin
      response.data['pages'].values[0]['links'].map { |page| page['title'] }
    rescue StandardError
      raise_invalid_wiki_content_error
    end
  end

  def self.listed_wiki_source_pages
    wiki_source_pages.select { |page| @slug_list.include? slug_from(page) }
  end

  def self.translated_pages(base_page:, base_page_wikitext:)
    return [] unless base_page_wikitext&.include? '<translate>'
    translations_query = { meta: 'messagegroupstats',
                           mgsgroup: "page-#{base_page}" }
    response = WikiApi.new(MetaWiki.new).query(translations_query)
    return [] unless response
    translations = []
    response.data['messagegroupstats'].each do |language|
      translations << (base_page + '/' + language['code']) if any_translations?(language)
    end
    return translations
  end

  def self.any_translations?(language)
    language['total'].positive? && language['translated'].positive?
  end

  # Given either a wiki page title or some wikitext, parses the content
  # into training data.
  def self.training_hash_from(wiki_page:, wikitext: nil)
    wikitext ||= WikiApi.new(MetaWiki.new).get_page_content(wiki_page)
    parser = WikiSlideParser.new(wikitext)
    case @content_class.to_s
    when 'TrainingSlide'
      { title: parser.title, content: parser.content, assessment: parser.quiz }
    when 'TrainingModule'
      { name: parser.title, description: parser.content }
    when 'TrainingLibrary'
      { name: parser.title, introduction: parser.content, categories: parser.categories }
    end
  end

  def self.slug_and_id_from(wiki_page)
    # Extract the slug and slide id from the last segment of the wiki page title
    # The expected form is something like "Training modules/dashboard/slides/20201-about-campaigns"
    id_and_slug = wiki_page.split('/').last
    slug = id_and_slug.gsub(/^[0-9]+-/, '')
    id = id_and_slug[/^[0-9]+/].to_i
    { 'id' => id, 'slug' => slug }
  end

  def self.slug_from(wiki_page)
    wiki_page.split('/').last.gsub(/^[0-9]+-/, '').gsub('.json', '')
  end

  def self.raise_no_matching_wiki_pages_error
    error = {}
    error['message'] = <<~ERROR
      Error: no wiki pages found from among #{@slug_list}.

      Link them from '#{@wiki_base_page}'.
    ERROR
    error['content_class'] = @content_class
    raise NoMatchingWikiPagesFound, error
  end

  def self.raise_invalid_wiki_content_error
    Sentry.capture_exception e
    error = {}
    error['message'] = "could not get links from '#{@wiki_base_page}'"
    error['content_class'] = @content_class
    raise InvalidWikiContentError, error
  end

  class InvalidWikiContentError < StandardError; end

  class NoMatchingWikiPagesFound < StandardError; end
end
