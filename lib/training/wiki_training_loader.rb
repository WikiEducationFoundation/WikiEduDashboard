# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/training/wiki_slide_parser"
require_dependency "#{Rails.root}/lib/wiki_api"

# Loads any of the three types of training content:
# TrainingLibrary, TrainingModule, TrainingSlide
# Source of content is training_content yaml files and/or wiki pages.
class WikiTrainingLoader
  def initialize(content_class:, slug_list: nil)
    @content_class = content_class # TrainingLibrary, TrainingModule, or TrainingSlide
    @slug_list = slug_list # limited list of slugs to process (optional)
    # Index page that links to all the libraries, modules or slides to be loaded
    @wiki_base_page = content_class.wiki_base_page

    @collection = []
  end

  def load_content
    load_from_wiki
    return @collection
  end

  private

  #####################
  # On-wiki trainings #
  #####################

  CONCURRENCY = 10 # Maximum simultaneous requests to mediawiki
  def load_from_wiki
    source_pages = @slug_list ? listed_wiki_source_pages : wiki_source_pages
    raise_no_matching_wiki_pages_error if source_pages.empty?
    Raven.capture_message "Loading #{@content_class}s from wiki",
                          level: 'info', extra: { wiki_pages: source_pages }

    thread_count = [CONCURRENCY, source_pages.count].min
    threads = source_pages.in_groups(thread_count, false).map.with_index do |wiki_page_group, i|
      Thread.new(i) { add_trainings_to_collection(wiki_page_group) }
    end
    threads.each(&:join)
  rescue InvalidWikiContentError => e
    Raven.capture_exception e
  end

  def add_trainings_to_collection(wiki_pages)
    wiki_pages.each do |wiki_page|
      content = new_from_wiki_page(wiki_page)
      unless content&.valid?
        Raven.capture_message 'Invalid wiki training content',
                              level: 'warn', extra: { content: content, wiki_page: wiki_page }
        next
      end
      @collection << content
    end
  end

  def new_from_wiki_page(wiki_page)
    wikitext = WikiApi.new(MetaWiki.new).get_page_content(wiki_page)
    return if wikitext.blank? # Handle wiki pages that don't exist.

    # Handles either json pages or regular wikitext pages
    content = if wiki_page[-5..-1] == '.json'
                new_from_json_wiki_page(wikitext)
              else
                new_from_wikitext_page(wiki_page, wikitext)
              end

    @content_class.inflate(content, content['slug'], wiki_page)
  end

  # json pages have all the required data within the json content, but optionally
  # point to a wiki page for the content
  def new_from_json_wiki_page(json_wikitext)
    content = Oj.load(json_wikitext)
    base_page = content['wiki_page']
    return content unless base_page
    wikitext = WikiApi.new(MetaWiki.new).get_page_content(base_page)
    training_content_and_translations(content: content, base_page: base_page, wikitext: wikitext)
  end

  # wikitext pages have the slide id and slug embedded in the page title
  def new_from_wikitext_page(wiki_page, wikitext)
    content = slug_and_id_from(wiki_page)
    training_content_and_translations(content: content, base_page: wiki_page, wikitext: wikitext)
  end

  # Gets the training hashes for the page itself and any translations that exist.
  def training_content_and_translations(content:, base_page:, wikitext:)
    full_content = content.merge training_hash_from(wiki_page: base_page, wikitext: wikitext)
    full_content['translations'] = {}
    translated_pages(base_page: base_page, base_page_wikitext: wikitext).each do |translated_page|
      language = translated_page.split('/').last
      full_content['translations'][language] = training_hash_from(wiki_page: translated_page)
    end
    full_content
  end

  # Gets a list of page titles linked from the base page
  def wiki_source_pages
    # To handle more than 500 pages linked from the source page,
    # we'll need to update this to use 'continue'.
    query_params = { prop: 'links', titles: @wiki_base_page, pllimit: 500 }
    response = WikiApi.new(MetaWiki.new).query(query_params)
    begin
      response.data['pages'].values[0]['links'].map { |page| page['title'] }
    rescue StandardError
      raise InvalidWikiContentError, "could not get links from '#{@wiki_base_page}'"
    end
  end

  def listed_wiki_source_pages
    wiki_source_pages.select { |page| @slug_list.include? slug_from(page) }
  end

  def translated_pages(base_page:, base_page_wikitext:)
    return [] unless base_page_wikitext&.include? '<translate>'
    translations_query = { meta: 'messagegroupstats',
                           mgsgroup: "page-#{base_page}" }
    response = WikiApi.new(MetaWiki.new).query(translations_query)
    return [] unless response
    translations = []
    response.data['messagegroupstats'].each do |language|
      translations << base_page + '/' + language['code'] if any_translations?(language)
    end
    return translations
  end

  def any_translations?(language)
    language['total'].positive? && language['translated'].positive?
  end

  # Given either a wiki page title or some wikitext, parses the content
  # into training data.
  def training_hash_from(wiki_page:, wikitext: nil)
    wikitext ||= WikiApi.new(MetaWiki.new).get_page_content(wiki_page)
    parser = WikiSlideParser.new(wikitext)
    case @content_class.to_s
    when 'TrainingSlide'
      { title: parser.title, content: parser.content, assessment: parser.quiz }
    when 'TrainingModule'
      { name: parser.title, description: parser.content }
    end
  end

  def slug_and_id_from(wiki_page)
    # Extract the slug and slide id from the last segment of the wiki page title
    # The expected form is something like "Training modules/dashboard/slides/20201-about-campaigns"
    id_and_slug = wiki_page.split('/').last
    slug = id_and_slug.gsub(/^[0-9]+-/, '')
    id = id_and_slug[/^[0-9]+/].to_i
    { 'id' => id, 'slug' => slug }
  end

  def slug_from(wiki_page)
    wiki_page.split('/').last.gsub(/^[0-9]+-/, '').gsub('.json', '')
  end

  def raise_no_matching_wiki_pages_error
    message = <<~ERROR
      Error: no wiki pages found from among #{@slug_list}.

      Link them from '#{@wiki_base_page}'.
    ERROR
    raise NoMatchingWikiPagesFound, message
  end

  class InvalidWikiContentError < StandardError; end
  class NoMatchingWikiPagesFound < StandardError; end
end
