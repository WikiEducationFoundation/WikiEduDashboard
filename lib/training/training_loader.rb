# frozen_string_literal: true

require "#{Rails.root}/lib/training/wiki_slide_parser"

# Loads any of the three types of training content:
# TrainingLibrary, TrainingModule, TrainingSlide
# Source of content is training_content yaml files and/or wiki pages.
class TrainingLoader
  def initialize(content_class:, slug_whitelist: nil)
    @content_class = content_class # TrainingLibrary, TrainingModule, or TrainingSlide

    @slug_whitelist = slug_whitelist # limited list of slugs to process (optional)

    @path_to_yaml = content_class.path_to_yaml # a sub-directory of training_content

    # Index page that links to all the libraries, modules or slides to be loaded
    @wiki_base_page = content_class.wiki_base_page

    @collection = []
  end

  def load_content
    load_from_yaml
    load_from_wiki if Features.wiki_trainings?
    return @collection
  end

  private

  ########################
  # YAML-based trainings #
  ########################
  def load_from_yaml
    Dir.glob(@path_to_yaml) do |yaml_file|
      @collection << new_from_file(yaml_file)
    end
  end

  def new_from_file(yaml_file)
    slug = File.basename(yaml_file, '.yml')
    slug.gsub!(/^[0-9]+-/, '') if @content_class.trim_id_from_filename

    content = YAML.load_file(yaml_file).to_hashugar
    @content_class.new(content, slug)
  end

  #####################
  # On-wiki trainings #
  #####################

  CONCURRENCY = 30 # Maximum simultaneous requests to mediawiki
  def load_from_wiki
    Raven.capture_message 'Loading trainings from wiki', level: 'info'
    source_pages = @slug_whitelist ? whitelisted_wiki_source_pages : wiki_source_pages
    raise_no_matching_wiki_pages_error if source_pages.empty?

    thread_count = [CONCURRENCY, source_pages.count].min
    threads = source_pages.in_groups(thread_count, false).map.with_index do |wiki_page_group, i|
      Thread.new(i) { add_trainings_to_collection(wiki_page_group) }
    end
    threads.each(&:join)
  rescue InvalidWikiContentError => e
    Raven.capture e
  end

  def add_trainings_to_collection(wiki_pages)
    wiki_pages.each do |wiki_page|
      content = new_from_wiki_page(wiki_page)
      unless content&.valid?
        Raven.capture_message 'Invalid wiki training content',
                              level: 'warn',
                              extra: { content: content, wiki_page: wiki_page }
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

    # TODO: Determine whether Hashr or OpenStruct might be more performant.
    # These objects are long-lived, so Hashugar may not be the best option.
    content = content.to_hashugar
    @content_class.new(content, content.slug)
  end

  # json pages have all the required data within the json content, but optionally
  # point to a wiki page for the content
  def new_from_json_wiki_page(json_wikitext)
    content = JSON.parse(json_wikitext)
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
    full_content = content.merge training_hash_from(wikitext: wikitext)
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
    rescue
      raise InvalidWikiContentError, "could not get links from '#{@wiki_base_page}'"
    end
  end

  def whitelisted_wiki_source_pages
    wiki_source_pages.select { |page| @slug_whitelist.include? slug_from(page) }
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
  def training_hash_from(wiki_page: nil, wikitext: nil)
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
      Error: no wiki pages found from among #{@slug_whitelist}.

      Link them from '#{@wiki_base_page}'.
    ERROR
    raise NoMatchingWikiPagesFound, message
  end

  class InvalidWikiContentError < StandardError; end
  class NoMatchingWikiPagesFound < StandardError; end
end
