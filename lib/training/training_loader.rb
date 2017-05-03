# frozen_string_literal: true

require "#{Rails.root}/lib/training/wiki_slide_parser"

class TrainingLoader
  def initialize(content_class:, path_to_yaml:, trim_id_from_filename:, wiki_base_page:)
    @collection = []
    @content_class = content_class

    @cache_key = content_class.cache_key
    @path_to_yaml = path_to_yaml
    @wiki_base_page = wiki_base_page
    @trim_id_from_filename = trim_id_from_filename
  end

  def load_content
    load_from_yaml
    load_from_wiki if Features.wiki_trainings?
    write_to_cache
    return @collection
  end

  private

  def load_from_yaml
    Dir.glob(@path_to_yaml) do |yaml_file|
      @collection << new_from_file(yaml_file)
    end
  end

  CONCURRENCY = 30
  def load_from_wiki
    Raven.capture_message 'Loading trainings from wiki', level: 'info'
    source_pages = wiki_source_pages
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
                              extra: { content: content }
        next
      end
      @collection << content
    end
  end

  def write_to_cache
    Rails.cache.write @cache_key, @collection
  end

  def new_from_wiki_page(wiki_page)
    json_wikitext = WikiApi.new(MetaWiki.new).get_page_content(wiki_page)
    return unless json_wikitext # Handle wiki pages that don't exist.
    content = JSON.parse(json_wikitext)
    if content['wiki_page']
      wikitext = WikiApi.new(MetaWiki.new).get_page_content(content['wiki_page'])
      content.merge! training_hash_from_wiki_page(content['wiki_page'], wikitext: wikitext)
      content['translations'] = {}
      translated_wiki_pages(base_page: content['wiki_page'], base_page_wikitext: wikitext).each do |translated_page|
        language = translated_page.split('/').last
        content['translations'][language] = training_hash_from_wiki_page(translated_page)
      end
    end
    content = content.to_hashugar
    @content_class.new(content, content.slug)
  end

  def wiki_source_pages(base_page: nil)
    link_source = base_page || @wiki_base_page
    # To handle more than 500 pages linked from the source page,
    # we'll need to update this to use 'continue'.
    query_params = { prop: 'links', titles: link_source, pllimit: 500 }
    response = WikiApi.new(MetaWiki.new).query(query_params)
    begin
      response.data['pages'].values[0]['links'].map { |page| page['title'] }
    rescue
      raise InvalidWikiContentError, "could not get links from '#{link_source}'"
    end
  end

  def translated_wiki_pages(base_page:, base_page_wikitext:)
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

  def training_hash_from_wiki_page(wiki_page, wikitext: nil)
    wikitext ||= WikiApi.new(MetaWiki.new).get_page_content(wiki_page)
    parser = WikiSlideParser.new(wikitext)
    case @content_class.to_s
    when 'TrainingSlide'
      { title: parser.title, content: parser.content, assessment: parser.quiz }
    when 'TrainingModule'
      { name: parser.title, description: parser.content }
    end
  end

  def new_from_file(yaml_file)
    slug = File.basename(yaml_file, '.yml')
    slug.gsub!(/^[0-9]+-/, '') if @trim_id_from_filename

    content = YAML.load_file(yaml_file).to_hashugar
    @content_class.new(content, slug)
  end

  class InvalidWikiContentError < StandardError; end
end
